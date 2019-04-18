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
  mutate(timeDiff = as.numeric(difftime(Release_Date, 
                                        timeStart, units = "hours")))
