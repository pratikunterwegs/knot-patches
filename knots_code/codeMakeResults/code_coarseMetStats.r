#### code for models ####

library(data.table); library(tidyverse)
library(lmerTest)

# simple ci function
ci = function(x){
  qnorm(0.975)*sd(x, na.rm = T)/sqrt((length(x)))}

#### load data ####
# read mcp and dist data
data <- fread("../data2018/dataMCParea.csv")
setDF(data)

# # read number of fixes
# recPrepFiles <- list.files("../data2018/oneHertzData/recursePrep/", full.names = T)
# 
# # read in data and ask how many rows
# recPrepData <- map_df(recPrepFiles, function(z){
#   fread(z)[,.N,by=list(id, tidalcycle)]
# })
# 
# #save to file
# fwrite(recPrepData, "../data2018/data2018idTideCount.csv")

# read prepared data of positions per tidal cycle
recPrepData <- fread("../data2018/data2018idTideCount.csv")

data <- merge(data, recPrepData, all = FALSE, no.dups = TRUE)

# read and select behav scores
behavData <- read_csv("../data2018/behavScoresRanef.csv") %>% 
  select(id, contains("Score"))

# join move metrics with behav datas
data <- inner_join(data, behavData)

#### run coarse scale area and distance models ####
# prepare the data for both models at the same time
modsCoarse <- data %>% 
  # select cols
  select(totalDist, mcpArea, contains("Score"), fixes = N, id, tidalcycle) %>% 
  drop_na() %>%
  # make long for score type, either transformed or cond ranef
  gather(scoreType, scoreval, -id, -tidalcycle, -totalDist, -mcpArea, -fixes) %>% 
  group_by(scoreType) %>% 
  # split into two dfs
  nest() %>% 
  # in each df, split by response variable
  mutate(data = map(data, function(df){
    df %>% gather(respVar, respval, -scoreval, -fixes, -id, -tidalcycle) %>%
    nest(-respVar)
  })) %>% 
  # unnest one level
  unnest()

 # add the model object as a new list column
modsCoarse <- modsCoarse %>% 
  # run models with id as a random effect
  mutate(
    modelWithId = map(data, function(z){
      lmer(sqrt(respval) ~ scoreval + (1|id) + (1|tidalcycle), 
           data = z, na.action = na.omit)
    }),
    # run mods without id as random effect
    modelWioId = map(data, function(z){
      lmer(sqrt(respval) ~ scoreval + (1|tidalcycle), 
           data = z, na.action = na.omit)
    }))

# set model list object names for export
library(glue)
names(modsCoarse$modelWithId) <- glue("response = {modsCoarse$respVar} predictor = {modsCoarse$scoreType}")
names(modsCoarse$modelWioId) <- names(modsCoarse$modelWithId)

#### get model predictions ####
# get model predictions for explore score,k
# and no random effects
modsCoarse <- modsCoarse %>% 
  mutate(
    # for models without id
    pred = map2(modelWithId, data, function(a,b){
      b %>% 
        mutate(predval = predict(a, type = "response", re.form = NULL))
    })
  )

# unnest data for use and summarise
modsCoarseData <- modsCoarse %>% select(respVar, pred) %>% 
  unnest() %>% 
  # now summarise by respVar and binned explore score
  group_by(respVar,
           exploreBin = plyr::round_any(exploreScore, 0.2)) %>% 
  
  mutate(empVal = ifelse(respVar == "totalDist", empVal/1e3, empVal/1e6),
         predval = ifelse(respVar == "totalDist", predval/1e3, predval/1e6)) %>% 
  
  # get mean and ci for plots
  summarise_at(vars(empVal, predval),
               list(~mean(.), ~ci(.)))

# plot
source("codePlotOptions/ggThemeKnots.r")

# write a labeller
coarseMetLabels <- c("mcpArea" = "MCP area (km²)",
                     "totalDist" = "Total distance (km)")


# plot with panels
plotCoarseMetrics <- ggplot(modsCoarseData)+
  geom_pointrange(aes(x = exploreBin, y = empVal_mean,
                      ymin = empVal_mean - empVal_ci,
                      ymax = empVal_mean + empVal_ci#,
                      # shape = tidestage
                      ), size = 0.3)+
  geom_smooth(aes(x = exploreBin, y = predval_mean#, lty = tidestage
                  ), 
              col = 1, method = "lm", fill = "grey80", lwd = 0.3)+
  
  scale_x_continuous(breaks = seq(-0.4, 1, 0.2))+

  scale_shape_manual(values = c(16, 15))+
  
  facet_wrap(~respVar, scales = "free_y",
                 labeller = labeller(respVar = coarseMetLabels),
                 strip.position = "left")+
  themePubKnots()+
  theme(strip.placement = "outside", 
        strip.background = element_blank(),
        strip.text = element_text(face = "plain", hjust = 0.5))+
  labs(y = NULL, x = "exploration score")

# save plot


{pdf(file = "../figs/fig04coarseMetrics.pdf", width = 180/25.4, height = 80/25.4)
  
  print(plotCoarseMetrics);
  grid.text(c("a","b"), x = c(0.1, 0.575), y = 0.95, just = "left",
            gp = gpar(fontface = "bold"), vp = NULL)
  
  dev.off()}

# write model output to file
# write model output to text file
{writeLines(R.utils::captureOutput(map(modsCoarse$model, summary)), 
            con = "../data2018/textCoarseMods.txt")}
