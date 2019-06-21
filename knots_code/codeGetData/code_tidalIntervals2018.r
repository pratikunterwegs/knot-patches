#### code to determine tidal intervals in 2018 ####

# load libs
library(tidyverse); library(readr)

#### load waterlevel data ####
# load waterlevel data from west terschelling
# from rijkswaterstaat waterinfo request
# 
waterlevel = read_delim("../data2018/waterlevelWestTerschelling.csv", delim = ";")

# select relevant columns, time and waterlevel
# TAKE CARE TO SELECT ONLY ONE MEASURE OF WATERLEVEL
waterlevel = waterlevel %>% 
  filter(GROOTHEID_OMSCHRIJVING == "Waterhoogte") %>% # select the measure
  select(date = WAARNEMINGDATUM, time = WAARNEMINGTIJD, level = NUMERIEKEWAARDE)

# get a full posixct object for time
waterlevel = waterlevel %>% 
  mutate(dateTime = as.POSIXct(date, format = "%d-%m-%Y")+as.numeric(time)) %>% 
  ungroup()

#### source high-low tide function ####
# source function
source("codeGetData/high_low_tide.R")
# calculate tides on a 12 hour 25 minute cycle
# per RWS advice
tides = HL(waterlevel$level, waterlevel$dateTime, period = 13, tides = "all")

tides$timeNum = as.numeric(tides$time)

# export as csv
write_csv(tides, path = "../data2018/tidesSummer2018.csv")
