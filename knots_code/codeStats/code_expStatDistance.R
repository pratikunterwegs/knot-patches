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
dataDistForage = mutate(dataDist, 
                        #foragePeriod = between(timeToHiTide, 3*60, 10*60),
                        hourHT = plyr::round_any(timeToHiTide, 60)/60) %>% 
  group_by(id, tidalCycle, hourHT) %>%
  summarise(distPerPeriod = sum(distance, na.rm = T))
#'plot
ggplot(dataDistForage %>% 
         filter(hourHT %in% c(4:10)))+
  stat_density(aes(x = distPerPeriod/1e3, y = ..count../max(..count..)),
                     #col = factor(hourHT)), bins = 30, 
               col = "grey20",
                 position = "identity", alpha = 1, geom = "line")+
  #scale_fill_manual(values = pals::kovesi.cyclic_mygbm_30_95_c78(6))+
  themePubLeg()+facet_wrap(~hourHT)+
  ggtitle("total distance per hour since HT")+ xlab("distance (km)")+
  ylab("proportion")+
  xlim(0, 2)

#'save
ggsave(filename = "../figs/figSumDistPerHour.pdf", 
       device = pdf(), width = 125, height = 125, units = "mm", dpi = 300); dev.off()
