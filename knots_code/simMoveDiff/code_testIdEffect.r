#### code to test different distributions ####

# load libs
library(data.table)
library(tidyr); library(dplyr); library(purrr)
library(stringr)

# source movement lib
source("codeMoveMetrics/functionEuclideanDistance.r")

# simple ci function
ci = function(x){
  qnorm(0.975)*sd(x, na.rm = T)/sqrt((length(x)))}

# read data and nest, separating into random walk and levy flight data frames
data <- fread("simMoveDiff/dataSimMoveDiff.csv") %>% 
  setDF() %>% 
  group_by(id, replicate, repEff, moveProb, moveScale) %>% nest() %>% 
  # separate using select
  mutate(Rw = map(data, function(df){
    df %>% select(-matches(c("Lf"))) %>% rename("x" = "xRw", "y"="yRw") %>% 
      mutate(simtype = "rw")
  }),
  Lf = map(data, function(df){
    df %>% select(-matches(c("Rw"))) %>% rename("x" = "xLf", "y" = "yLf") %>% 
      mutate(simtype = "lf")
  })) %>% 
  # gather by sim type
  select(-data) %>% 
  gather(sim, data, -id, -replicate, -moveProb, -moveScale)

#### simulate explore score ####
# simulated explore score is the log total distance moved by an individual in the first 10 timesteps of any one of the replicates
scoredata <- data %>% 
  mutate(scoredata = map(data, function(df){
    head(df, 50)
  })) %>% 
  select(-data)

# get sim explore score
scoredata <- scoredata %>% 
  mutate(totalDist = map_dbl(scoredata, function(df){
    a = (sum(funcDistance(df), na.rm = T))
    return(a)
  })) %>% 
  select(-scoredata)

# fit a rptR model to the data
library(rptR)
repMod = rpt(totalDist ~ sim + (1|id) + (1|replicate), 
             grname = c("id", "replicate"), 
             data = scoredata, datatype = "Gaussian", 
             nboot = 100, npermut = 0)

# get scores as scaled ranef on id
scoredata$simexscore <- scales::rescale((ranef(repMod$mod)$id[,1]),
                                        to = c(-1, 1))

# plot unique simexscore as id
library(ggplot2)
scoredata %>% 
  distinct(id, simexscore) %>% 
  ggplot()+
  stat_density(aes(x = simexscore), geom = "line")+
  theme_bw()

# plot sim score against movement param
ggplot(scoredata)+
  geom_point(aes(x = ifelse(sim == "Rw", moveProb, moveScale), simexscore), size = 0.2)+
  facet_wrap(~sim, scales = "free")+
  theme_bw()+
  labs(x = "movement parameter", y = "estimated explore score")+
#  scale_y_continuous(limits = c(0, 3))+
  theme(panel.grid = element_blank(),
        strip.background = element_blank())

# set seed
set.seed(0)
# subsample data at 10 - 60% to mimic imperfect sampling  
data <- data %>% 
  mutate_at(vars(data), list(~map(., function(df){
    sample_frac(df, runif(1, 0.1, 0.6))})))

# calculate total distance, MCP area, nFixes as for emp data
library(sf)

dataSummary <- data %>% 
  # on each of the two kinds of sim data
  mutate_at(vars(data), 
            # map the following funcs
            list(#~map_chr(., function(df){unique(df$simtype)}),
                 ~map_int(., nrow),
                 ~map_dbl(., function(df){
                   # sum the distance
                   sum(funcDistance(df), na.rm = T)
                 }),
                 ~map_dbl(., function(df){
                   # get the MCP area
                   st_as_sf(df, coords = c("x","y")) %>% 
                     st_union() %>% 
                     st_convex_hull() %>% 
                     st_area()
                 }))) %>% 
  select(-data)

# rename cols
names(dataSummary) <- c("id", "replicate", "moveProb", "moveScale",
                        "simtype", "fixes","distance","area")

# prep for model
modData <- dataSummary %>% 
  # gather by response variable
  gather(respvar, simval, -id, -replicate, -fixes, -moveProb, -moveScale, -simtype) %>% 
  # group by sim type and resp and nest, allows same model code on each df
  group_by(simtype, respvar) %>% 
  nest()

# join simexscore to simdata by model
modData <- modData %>% 
  # statement conditional on the simulation type
  mutate(data = ifelse(simtype == "Lf",
                       map(data, function(df){
                         inner_join(df, scoredata %>%
                                      filter(sim == "Lf") %>% 
                                      select(id, simexscore, sim))
                       }),
                       map(data, function(df){
                         inner_join(df, scoredata %>% 
                                      filter(sim == "Rw") %>% 
                                      select(id, simexscore, sim))
                       })))

# run model on each df using lmertest
library(lmerTest)
modData <- modData %>%
  mutate(model = map(data, function(df){
    lmer(simval ~ log(fixes) + simexscore + (1|id), data=df)
  }))

# run model summary
map(modData$model, summary)

#### plot effect ####
plotData <- dataSummary %>%
  inner_join(scoredata) %>% 
  # get a rounded move param
  # mutate(moveProb = plyr::round_any(moveProb, 0.1),
  #        moveScale = plyr::round_any(moveScale, 0.5)) %>% 
  mutate(score = plyr::round_any(simexscore, 0.2)) %>% 
  # select vars and gather
  select(score, simtype, distance, area) %>% 
  gather(respvar, simval, -simtype, -score) %>% 
  group_by(simtype, score, respvar) %>%
  summarise_all(list(~mean(.), ~ci(.)))

# plot construction
source("codePlotOptions/ggThemeKnots.r")
library(ggplot2)
library(scales)

# write a pair of labellers
respvarLabels <- c("area" = "MCP area (unit²)",
                    "distance" = "Total distance (units)")

simtypeLabels <- c("Lf" = "Levy flight",
                   "Rw" = "Random walk")

# reorder plot variables
plotData <- mutate(plotData %>% ungroup(),
                   simtype = factor(simtype, levels = c("Rw", "Lf")),
                   respvar = factor(respvar, levels = c("distance", "area")))

# make plot
plotSimMetrics <- ggplot(plotData)+
  geom_pointrange(aes(x= score, 
                      y = mean,
                      ymin = mean-ci, ymax = mean+ci,
                      shape = simtype), size = 0.2)+
  # facet the metrics by sim type
  facet_wrap(simtype~respvar, scales = "free",
             switch = "y",
             labeller = labeller(respvar = respvarLabels,
                                 simtype = simtypeLabels))+
  scale_shape_manual(values = c(16,15))+
  
  scale_y_continuous(label=comma)+
  
  themePubKnots()+
  theme(strip.placement = "outside", 
        strip.background = element_blank(),
        strip.text = element_text(face = "plain", hjust = 0.5),
        panel.spacing.y = unit(2, "lines"),
        legend.position = "none")+
  labs(x = "Simulated exploration score", y= NULL)

# export plot
{pdf(file = "../figs/figA01simMetrics.pdf", width = 150/25.4, height = 120/25.4)
  
  print(plotSimMetrics);
  grid.text(c("a","b", "c", "d"), x = c(0.115, 0.6, 0.115, 0.6), y = c(0.95, 0.95, 0.5, 0.5), just = "left",
            gp = gpar(fontface = "bold"), vp = NULL)
  
  dev.off()}

# ends here