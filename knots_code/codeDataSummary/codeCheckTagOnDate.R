#### code to check if tags on before release ####

library(readr); library(tidyr); library(dplyr)

#'load move data summary
dataSummary = read_csv("../data2018/dataSummary2018.csv") %>% 
  distinct(id, .keep_all = T)
#'load tagging data
behavData = read_csv("../data2018/behavScores.csv")
#'join the two
#'
dataSummary = left_join(dataSummary, behavData)

dataTimeDiff = select(dataSummary, id, timeStart, Release_Date) %>% 
  mutate(timeDiff = as.numeric(difftime(time1 = Release_Date, time2 = timeStart, units = "hours")))

#### histogram of release-on lag ####
library(ggplot2)
source("codePlotOptions/ggThemePub.r")

ggplot(dataTimeDiff)+
  geom_histogram(aes(x = timeDiff), col = drkGry, fill = stdGry,
                 bins = 50)+
  geom_vline(xintercept = 0, col = altRed, lty = 2)+
  themePub()+
  xlab("time to tag first position after release (hrs)")+
  xlim(-50, 200)+
  ylab("# birds")
