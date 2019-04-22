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

#### explore steplength distributions ####
#'get summary data
dataDistSummary = dataDist %>% 
  mutate(hourHt = plyr::round_any(timeToHiTide, 60)) %>% 
  group_by(id, hourHt, tidalCycle) %>% 
  summarise(dist = mean(distance, na.rm = T))

#'add explore score
dataBehav = read_csv("../data2018/behavScores.csv")

dataDistSummary = left_join(dataDistSummary, dataBehav)

#'plot data
ggplot()+
  geom_freqpoly(data = dataDistSummary %>% 
                   filter(!is.na(exploreScore)),
               aes(x = dist, 
                   group = id, col = exploreScore), 
               position = "dodge",fill = "transparent", size = 1,
               binwidth = 10, alpha = 0.5)+
  
  scale_colour_gradientn(colours = pals::coolwarm(20))+
  
  xlim(0, quantile(dataDist$distance, 0.95, na.rm = T))+
  facet_wrap(~hourHt)+
  #coord_cartesian(ylim = c(0,10))+
  themePubLeg()

  