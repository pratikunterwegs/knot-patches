#### link patch size to exploration score ####

# load libs
library(tidyr); library(dplyr); library(readr)

# read in patch size data from shapefile
patches <- read_csv("../data2018/oneHertzData/data2018patches.csv") 

# read in behav scores
behavScore <- read_csv("../data2018/behavScores.csv")

# link behav score and patch size and area
patches <- left_join(patches, behavScore, by= c("id"))

# # filter out unreasonable data of greater than 100 x 100 m
# patches <- filter(patches)

# make exploratory plots
library(ggplot2)
source("codePlotOptions/geomFlatViolin.r")
source("codePlotOptions/ggThemeKnots.r")
source("codePlotOptions/ggThemeGeese.r")

# simple ci function
ci = function(x){
  qnorm(0.975)*sd(x, na.rm = T)/sqrt((length(x)))
}

#### make patch summary ####
patchSummary <- patches %>% 
  mutate(tidalCluster = plyr::round_any(tidalcycle, 15),
         tidalTimeHour = plyr::round_any(tidaltime_mean/60, 1)) %>% 
  filter(tidalTimeHour <= 12, tidalCluster <=120) %>% 
  group_by(tidalCluster, tidalTimeHour) %>% 
  summarise_at(vars(area, nFixes, distInPatch, distBwPatch),
               list(~mean(., na.rm = T), ~ci(.)))

# source plot code
source("codeRawData/plot_resPatchPlots.r")

#### make patch summary for indivs ####
# get in incremens of 0.2 of explore score
patchIdSummary <- patches %>% 
  mutate(
    # tidalCluster = plyr::round_any(tidalcycle, 15),
    hiOrLo = ifelse(between(tidaltime_mean, 4*60, 9*60), "lowTide", "highTide"),
         exploreBin = plyr::round_any(exploreScore, 0.2)) %>% 
  select(exploreBin, 
         #tidalCluster, 
         duration, nFixes, 
         distInPatch, distBwPatch, area, hiOrLo) %>% 
  gather(variable, value, -exploreBin, -hiOrLo) %>% 
  group_by(exploreBin, hiOrLo, variable) %>% 
  summarise_at(vars(value),
               list(~mean(., na.rm = T), ~ci(.)))

# count patches per tide per explore score bin
patchCount <- patches %>% 
  mutate(hiOrLo = ifelse(between(tidaltime_mean, 4*60, 9*60), "lowTide", "highTide")) %>%  
  count(id, exploreScore, tidalcycle, hiOrLo) %>% 
  mutate(exploreBin = plyr::round_any(exploreScore, 0.2)) %>% 
  group_by(exploreBin, hiOrLo) %>% 
  summarise_at(vars(n), list(~mean(., na.rm=T),~ci(.))) %>% 
  mutate(variable = "patch changes") %>% 
  select(exploreBin, hiOrLo, variable, mean, ci) %>% 
  bind_rows(patchIdSummary)
  

# plot
ggplot(patchCount)+
  geom_pointrange(aes(x = exploreBin, y = mean, ymin = mean - ci,
                      ymax = mean + ci, col = hiOrLo, shape = hiOrLo),
                  position = position_dodge(width = 0.04), size = 0.3)+
  facet_wrap(~variable, scales = "free")+
  scale_colour_brewer(palette = "Dark2")+
  #scale_shape_cleveland()+
  themePubKnots()+
  labs(x = "exploration score", y = "value (specific units)",
       title = "patch values ~ exploration score",
       caption = Sys.time())+
  theme(legend.position = "top")

ggsave("../figs/figPatchMetricsVsExploreScoreWithTide.pdf", height = 6, width = 8,
       device = pdf()); dev.off()
