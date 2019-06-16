#### link patch size to exploration score ####

# load libs
library(tidyr); library(dplyr); library(readr); library(sf)

# read in patch size data from shapefile
patches <- st_read("../data2018/oneHertzDataSubset/patch/patches.shp")

# read in behav scores
behavScore <- read_csv("../data2018/behavScores.csv") %>% 
  mutate(bird = factor(id))

# link behav score and patch size and area
patches <- left_join(patches, behavScore, by= c("bird"))

# # filter out unreasonable data of greater than 100 x 100 m
# patches <- filter(patches)

# make exploratory plots
library(ggplot2)
source("codePlotOptions/geomFlatViolin.r")
source("codePlotOptions/ggThemePub.r")

# plot boxplot of patch area over all times to high tide in 10 cycle clusters
ggplot(patches)+
  geom_boxplot(aes(x = factor(round(as.numeric(tdlCycl)/10)), 
                   y = area, fill = factor(bird)),
               position = position_dodge(preserve = "single", width = 1),
                   alpha = 0.5)+
  themePubLeg()+
  ylim(0,1e4)

# plot boxplots of foraging vs non-foraging patches
patches %>% 
  mutate(highTideHour = floor(tmTHTd_),
         foraging = ifelse(between(highTideHour, 4, 9), "low-tide", "high-tide"),
         tidalCycleCluster = factor(round(as.numeric(tdlCycl)/10)))%>%
  ggplot()+
  geom_boxplot(aes(x = factor(highTideHour), 
                   y = area),
               position = position_dodge(preserve = "single", width = 1),
               alpha = 0.5)+
  facet_wrap(~tidalCycleCluster)+
  themePubLeg()+
  ylim(0,1e4)+
  labs(x = "hours since high tide", y = "patch area (m^2)",
       title = "patch area ~ time since high tide",
       caption = Sys.time())

ggsave(filename = "../figs/figPatchAreaVsTime.pdf", width = 11, height = 8,
       device = pdf()); dev.off()

# plot patch area vs other predictors
patches %>% filter(area < 1e4) %>% 
  as_tibble() %>% 
  select(area, WING, MASS, gizzard_mass, pectoral, exploreScore, bird) %>% 
  gather(predictor, value, -bird, -area) %>% 

ggplot()+
  geom_jitter(aes(x = value, y = area, group = bird), size= 0.1, alpha = 0.2)+
  geom_smooth(aes(x = value, y = area), method = "glm")+
  facet_wrap(~predictor, scales = "free")+
  coord_cartesian(ylim = c(0,5e3))+
  labs(x = "predictor value", y = "patch area (m^2)", caption = Sys.time(),
       title = "patch area ~ various predictors")+
  themePub()

ggsave(filename = "../figs/figPatchAreaVsPredictors.pdf", width = 11, height = 8,
       device = pdf()); dev.off()
