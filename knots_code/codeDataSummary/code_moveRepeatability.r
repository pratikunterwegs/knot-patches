#### code for population level repeatability in movement ####

library(readr)

#'read in data with movement
data = read_csv("../data2018/data2018withDistances.csv")

#'summarise total distance per tide
library(tidyverse)
dataSummary = data %>%
  group_by(id, tidalCycle) %>%
  summarise(nFixes = length(distance),
            distPerTide = sum(distance, na.rm = T),
            durHrs = (max(timeNum) - min(timeNum))/3600,
            propFixes = nFixes*10/(max(timeNum) - min(timeNum)))


#'count propFixes below 0.33
count(ungroup(dataSummary), goodFix = propFixes >= 0.33) %>%
  ggplot()+
  geom_col(aes(x = goodFix, y = n, fill = goodFix))

#'remove id - tidalCycle combinations below 0.5 fix prop
dataSummary = filter(dataSummary, propFixes >= 0.33)

#'which ids remain?
idsWanted = tibble(id = unique(dataSummary$id)) %>%
  mutate(rowNum = 1:nrow(.)) %>%
  select(rowNum, id)

#### WORK IN PROGRESS ####
