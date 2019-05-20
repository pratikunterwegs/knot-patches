#### code to make shapefiles ####

# clear env
rm(list = ls()); gc()

# load libs
library(tidyverse); library(readr)
library(sf)
data = read_csv("../data2018/data2018posWithTides.csv")

#### movement distance per tidal cycle ####
# nest by id and tidal cycle
dataSf = group_by(data, id, tidalCycle) %>% 
  nest()

# keep only data (rows) where nrow > 1
dataSf = dataSf[unlist(map(dataSf$data, nrow)) > 1,]

# source the euclidan distance function
source("codeMoveMetrics/functionEuclideanDistance.r")

# map a distance function across the list, it's super quick
tidalMovement = map(dataSf$data, function(a)
{
  funcDistance(a, "x", "y")
})

# save as rdata
save(tidalMovement, file = "tidalMovement2018.rdata")

#### merge movement data and id data ####
# remove data to reduce bloat
rm(data); gc()

# joining distances with data
dataSf = dataSf %>% 
  mutate(distance = tidalMovement)

# then unnest data
dataSf = unnest(dataSf)

# write id, tidalCycle and distances to data
write_csv(dataSf, path = "../data2018/data2018withDistances.csv")
