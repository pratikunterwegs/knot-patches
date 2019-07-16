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
  group_by(id, replicate, moveProb, moveScale) %>% nest() %>% 
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

# run model on each df
library(lme4)
modData <- modData %>%
  mutate(model = map(data, function(df){
    lmer(simval ~ log(fixes) + moveProb + (1|id) + (1|replicate), data=df)
  }))

# run model summary
map(modData$model, summary)

# also car anova
map(modData$model, car::Anova)

#### plot effect ####
plotData <- dataSummary %>% 
  # get a rounded move param
  mutate(moveProb = plyr::round_any(moveProb, 0.1),
         moveScale = plyr::round_any(moveScale, 0.5)) %>% 
  # select vars and gather
  select(moveProb, simtype, distance, area) %>% 
  gather(respvar, simval, -simtype, -moveProb) %>% 
  group_by(simtype, moveProb, respvar) %>%
  summarise_all(list(~mean(.), ~ci(.)))

# plot construction
source("codePlotOptions/ggThemeGeese.r")
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
  geom_pointrange(aes(x= ifelse(simtype == "Lf", moveProb*5, moveProb), 
                      y = mean,
                      ymin = mean-ci, ymax = mean+ci,
                      shape = simtype))+
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
  labs(x = "Movement parameter", y= NULL)

# export plot
{pdf(file = "../figs/figA01simMetrics.pdf", width = 180/25.4, height = 150/25.4)
  
  print(plotSimMetrics);
  grid.text(c("a","b", "c", "d"), x = c(0.115, 0.6, 0.115, 0.6), y = c(0.95, 0.95, 0.5, 0.5), just = "left",
            gp = gpar(fontface = "bold"), vp = NULL)
  
  dev.off()}

# ends here