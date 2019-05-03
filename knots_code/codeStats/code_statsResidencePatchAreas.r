#### code for operations on residence patch areas ####

# load libs
library(tidyverse); library(readr); library(sf)
library(viridis)

# read in residence patch data
data = read_csv("../data2018/data2018residencePatchAreas.csv")

#### explore data between tides ####
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
       y = "res. patch area (m^2)",
       title = "distribution of segment areas (256 m^2 bin) ~ tidal cycles",
       fill = "prop. \nof \nsegs")

# save exploratory plot
ggsave(filename = "../figs/figResPatchAreaDistr.pdf", 
       device = pdf(), width = 200, height = 125, units = "mm"); dev.off()

#### explore within tides ####
# summarise data
resPatchTide = data %>% 
  mutate(tTht = round(timeToHiTide_start/60),
         segArea = plyr::round_any(area, 256)) %>% 
  filter(!is.na(tTht)) %>% 
  group_by(tTht) %>% 
  count(segArea) %>% mutate(prop = n/sum(n))

# plot data summary
ggplot(resPatchTide)+
  geom_tile(aes(x = (tTht), y = segArea, fill = prop), col = "white")+
  scale_fill_viridis(option = "magma",direction = -1)+
  scale_x_reverse(breaks = 0:13)+
  coord_flip(ylim = c(0, 2e4))+
  themePubLeg()+
  labs(x = "time since HT (hrs)",
       y = "res. patch area (m^2)",
       title = "distribution of segment areas (256 m^2 bin) ~ time since HT",
       fill = "prop. \nof \nsegs")

# save exploratory plot
ggsave(filename = "../figs/figResPatchAreaDistrWithinTides.pdf", 
       device = pdf(), width = 200, height = 90, units = "mm"); dev.off()
