#### code for models ####

library(data.table); library(tidyverse)
library(lme4)

# simple ci function
ci = function(x){
  qnorm(0.975)*sd(x, na.rm = T)/sqrt((length(x)))}

#### load data ####
# read mcp and dist data
data <- fread("../data2018/dataMCParea.csv")
setDF(data)

# read number of fixes
recPrepFiles <- list.files("../data2018/oneHertzData/recursePrep/", full.names = T)

# read in data and ask how many rows
recPrepData <- map_df(recPrepFiles, function(z){
  fread(z)[,.N,by=list(id, tidalcycle)]
})

#save to file
fwrite(recPrepData, "../data2018/data2018idTideCount.csv")

data <- merge(data, recPrepData, all = FALSE, no.dups = TRUE)

#### run coarse scale area and distance models ####
library(lme4)

# prepare the data for both models at the same time
modsCoarse <- data %>% 
  select(totalDist, mcpArea, exploreScore, fixes = N, id, tidalcycle) %>% 
  drop_na() %>% 
  gather(respVar, empVal, -exploreScore, -fixes, -id, -tidalcycle) %>% 
  nest(-respVar)

# add the model object as a new list column
modsCoarse <- modsCoarse %>% 
  # run models with id as a random effect
  mutate(
    modelWithId = map(data, function(z){
      lmer(empVal ~ exploreScore + log(fixes) + (1|id) + (1|tidalcycle), 
           data = z, na.action = na.omit)
    }),
    # run mods without id as random effect
    modelWioId = map(data, function(z){
      lmer(empVal ~ exploreScore + log(fixes) + (1|tidalcycle), 
           data = z, na.action = na.omit)
    }))

# get model predictions for explore score, holding fixes at mean
# and no random effects
modsCoarse <- modsCoarse %>% 
  mutate(
    # for models without id
    predModWioId = map2(modelWioId, data, function(a,b){
      b %>% 
        mutate(predval = predict(a, type = "response", re.form = NULL))
    })
  )

# unnest data for use and summarise
modsCoarseData <- modsCoarse %>% select(respVar, predModWioId) %>% 
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
source("codePlotOptions/ggThemeGeese.r")

ggplot(modsCoarseData)+
  geom_pointrange(aes(x = exploreBin, y = empVal_mean,
                      ymin = empVal_mean - empVal_ci,
                      ymax = empVal_mean + empVal_ci), size = 0.2)+
  geom_smooth(aes(x = exploreBin, y = predval_mean), 
              col = 1, method = "lm", fill = "grey80", lwd = 0.3)+
  
  scale_x_continuous(breaks = seq(-0.4, 1, 0.2))+
  
  facet_wrap(~respVar, scales = "free_y")+
  labs(x = "exploration score", y = bquote("mean ± 95% CI (km or km"^2~")"))+
  themePubGeese()
  

# save plot
ggsave(filename = "../figs/fig04coarseMetrics.pdf", height = 80/25.4, width = 180/25.4)
