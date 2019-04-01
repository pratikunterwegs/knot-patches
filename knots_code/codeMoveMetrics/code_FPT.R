#### estimating first passage time ####
#'load the data and estimate first passage time using the
#'recurse function or similar

#'load libs
library(tidyverse); library(readr)

#'read in the data
data = read_csv("../data2018/data2018posWithTides.csv")

#'subset for good forage data
goodForageData = read_csv("../data2018/goodForageData.csv")

data = filter(data, id %in% goodForageData$id, tidalCycle %in%
                goodForageData$tidalCycle) %>% 
  filter(between(timeToHiTide, 3*60, 10*60))

#### recursion analysis ####
#'make list of id - tidalCycle combination
data = plyr::dlply(data, c("id", "tidalCycle"))
#'remove dataframes with less than 33% points, ~139
data = purrr::keep(data, function(x) nrow(x) >= 150)

#'convert to ltraj
library(adehabitatLT)

dataLtraj = lapply(data, function(x){
  as.ltraj(xy = x[,c("x","y")], date = x$time, id = x$id,
           proj4string = CRS("+proj=utm +zone=31 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"))
})

#'get fpt
dataFpt = lapply(dataLtraj, function(x){
  fpt(x, radii = 100, units = "seconds")
})

#'make tibble of nested data
dataFpt = lapply(dataFpt, function(x) x[[1]])
dataFptNest = tibble(id.tide = names(dataFpt), fpt = dataFpt) %>% 
  unnest()

#'write to file
write_csv(dataFptNest, path = "../data2018/data2018FptForage.csv")
