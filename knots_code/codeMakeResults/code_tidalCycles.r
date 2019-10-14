#### code to determine tidal intervals in 2018 ####

# load libs
library(tidyverse); library(readr)

# load VulnToolkit or install if not
# VulnToolkit is the GH package version of the HL script we have been using
# https://github.com/troyhill/VulnToolkit
if("VulnToolkit" %in% installed.packages() == FALSE){
  devtools::install_github("troyhill/VulnToolkit")
}
library(VulnToolkit)

#### load waterlevel data ####
# load waterlevel data from west terschelling
# from rijkswaterstaat waterinfo request
# 
waterlevel = read_delim("../data2018/waterlevelWestTerschelling.csv", delim = ";")

# select relevant columns, time and waterlevel
waterlevel = select(waterlevel, date = WAARNEMINGDATUM, time = WAARNEMINGTIJD, level = NUMERIEKEWAARDE)

# get a full posixct object for time
waterlevel = waterlevel %>% 
  mutate(dateTime = as.POSIXct(date, format = "%d-%m-%Y")+as.numeric(time)) %>% 
  ungroup() %>%  
  select(-date, -time)

#### source high-low tide function ####
# calculate tides on a 12 hour 25 minute cycle
# per Rijkswaterstaat advice: see below 
# https://www.rijkswaterstaat.nl/water/waterdata-en-waterberichtgeving/waterdata/getij/index.aspx
tides = HL(waterlevel$level, waterlevel$dateTime, period = 12.41, tides = "all")

# export as csv
write_csv(tides, path = "../data2018/tidesSummer2018.csv")

# ends here