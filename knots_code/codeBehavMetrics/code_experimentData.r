#### read experiment data and output clean behav scores ####

library(tidyverse); library(readr)

# read data
dataExp = read_csv("../data2018/SelinDB.csv")

# keep cols and rename others
colsToKeep = c("SEX","AGE","WING","BILL","TOTHD","TARS","MASS",
               "gizzard_mass", "pectoral", "Release_Date", "Release_Time")

# subset data for  toa tags
behavScores = dataExp %>% 
  select(id = Toa_Tag, colsToKeep, contains("texpl"),
        -contains("W0")) %>% 
  filter(!is.na(id))

# convert release date to posixct
behavScores$Release_Date = as.POSIXct(paste(behavScores$Release_Date,
                                            behavScores$Release_Time,
                                            sep = " "),
                                      format = "%d.%m.%y %H:%M:%S", tz = "Europe/Berlin")

# get mean of field and wadunit scores
behavScores$exploreScore = behavScores %>% 
  select(contains("F0")) %>% 
  apply(1, function(x) mean(x, na.rm = T))

# remove field scores
behavScores = select(behavScores, -contains("F0"))

# export for use
write_csv(behavScores, path = "../data2018/behavScores.csv")


