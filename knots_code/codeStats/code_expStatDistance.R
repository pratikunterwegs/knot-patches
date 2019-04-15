#### code to explore movement distance ####

#'load libs and data
library(tidyverse); library(readr)

#'load basic summary data
dataSummary = read_csv("../data2018/dataSummary2018.csv")

#'load distances travelled
dataDist = read_csv("../data2018/data2018withDistances.csv")

#'summarise basic data
dataDistSummary = group_by(dataDist, id, tidalCycle) %>% 
  summarise(distPerTide = sum(distance, na.rm = T))

#'load plot ops
source("codePlotOptions/ggThemePub.r")

#### exploratory plots ####
#'distribution of distance per tide
ggplot(dataDistSummary)+
  geom_histogram(aes(x = distPerTide/1e3), bins = 50, col = "grey20",
                 fill = "grey90")+
  themePub()+
  ggtitle("distance per tidal cycle")+ xlab("distance (km)")

#'distribution of distance in foraging and non-foraging period
#'foraging period is HT+3 : HT+10
dataDistForage = filter(dataDist, 
                       between(timeToHiTide, 3*60, 10*60)) %>% 
                       mutate(day2 = plyr::round_any(tidalCycle, 8)) %>%
  group_by(id, day2, tidalCycle) %>%
  summarise(distPerPeriod = sum(distance, na.rm = T)) %>% 
  ungroup() %>% 
  group_by(id, day2) %>% 
  summarise_at(vars(distPerPeriod), mean)

#'plot
ggplot(dataDistForage)+
  geom_histogram(aes(x = distPerPeriod, fill = day2, group = day2), 
                 col = drkGry,
                 size = 0.3, position = "stack", bins = 50)+
  scale_fill_gradientn(colours = (colorspace::heat_hcl(30)),
                      name = "tidal \ncycle \nbin")+
  # scale_fill_viridis_c(name = "tidal \ncycle \nbin")+
  xlab("mean distance ")+
 # facet_wrap(~day2)+
  themePubLeg()+
  ggtitle("Mean distance per foraging period: 8 tidal cycle bins (~2 days)")+ xlab("distance (km)")+
  xlim(0, 3e4)

#'save
ggsave(filename = "../figs/figMeanDistPerForage.pdf", 
       device = pdf(), width = 297, height = 125, units = "mm", dpi = 300); dev.off()