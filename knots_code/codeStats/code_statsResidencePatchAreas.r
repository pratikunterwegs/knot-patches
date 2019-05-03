#### code for operations on residence patch areas ####

# load libs
library(tidyverse); library(readr); library(sf)
library(viridis)

# read in residence patch data
data = read_csv("../data2018/data2018residencePatchAreas.csv")

dataCount = data %>%
  mutate(segArea = plyr::round_any(area, 256)) %>% 
  group_by(tidalCycle) %>% 
  count(segArea) %>% 
  mutate(prop = n/sum(n))

# make exploratory plot
source("codePlotOptions/ggThemePub.r")

ggplot(dataCount)+
  geom_tile(aes(x = tidalCycle, y = segArea, fill = prop), col = "white")+
  scale_fill_viridis(option = "magma",direction = -1)+
  coord_cartesian(ylim = c(0, 2e4))+
  themePubLeg()+
  labs(x = "tidal cycle",
       y = "segment area (m^2)",
       title = "distribution of segment areas (256 m^2 bin) ~ tidal cycles",
       fill = "prop. \nof \nsegs")

# save exploratory plot
