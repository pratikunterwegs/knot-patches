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
  mutate(hourHt = plyr::round_any(timeToHiTide, 60)/60) %>% 
  group_by(id, hourHt, tidalCycle) %>% 
  summarise(dist = mean(distance, na.rm = T))

#'add explore score
dataBehav = read_csv("../data2018/behavScores.csv")

dataDistSummary = left_join(dataDistSummary, dataBehav)

# filter data dist summary to see only the 0-25 and 75+ quantile
# of explore scores
exploreScoreExtremes = quantile(dataDistSummary$exploreScore, 
                                probs = c(0, 0.25, 0.75, 1), na.rm = T)

dataDistSummary = mutate(dataDistSummary, 
                         behavCat = cut(exploreScore, exploreScoreExtremes,
                                        labels = c("low", "med", "hig"),
                                        include.lowest = T))

#'plot data
ggplot()+
  geom_freqpoly(data = dataDistSummary %>% 
                   filter(!is.na(exploreScore),
                          hourHt < 13),
               aes(x = dist, group = id), 
               position = "identity", size = 0.1, geom = "line",
               alpha = 0.2)+
  
  xlim(0, quantile(dataDist$distance, 0.95, na.rm = T))+
  facet_grid(behavCat~hourHt)+
  #coord_cartesian(ylim = c(0,10))+
  themePub()+
  labs(x = "steplength (m)", y = "# fixes", 
       title = "steplength distribution over tidal cycle: hour ~ exploreScore")

#'save to file
ggsave(filename = "../figs/figSteplengthDistTime.pdf", 
       device = pdf(), width = 297, height = 210, units = "mm"); dev.off()
  