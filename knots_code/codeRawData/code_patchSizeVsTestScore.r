#### link patch size to exploration score ####

# load libs
library(tidyr); library(dplyr); library(readr); library(sf)

# read in patch size data from shapefile
patches <- st_read("../data2018/selRawData/patch/patches.shp")

# read in behav scores
behavScore <- read_csv("../data2018/behavScores.csv") %>% 
  mutate(bird = factor(id))

# link behav score and patch size and area
patches <- left_join(patches, behavScore, by= c("bird"))

# filter out unreasonable data of greater than 100 x 100 m
patches <- filter(patches, area <= 1e4)

# make exploratory plots
library(ggplot2)
source("codePlotOptions/geomFlatViolin.r")
source("codePlotOptions/ggThemePub.r")

ggplot(patches)+
  geom_boxplot(aes(x = factor(round(as.numeric(tdlCycl)/10)), 
                   y = area, fill = factor(bird)),
               position = position_dodge(preserve = "single", width = 1),
                   alpha = 0.5)+
  themePubLeg()+
  ylim(0,1e4)
