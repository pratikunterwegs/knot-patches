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

#### prepare for recursion analysis ####
#'make list of id - tidalCycle combination
data = plyr::dlply(data, c("id", "tidalCycle"))
#'remove dataframes with less than 33% points, ~139
data = purrr::keep(data, function(x) nrow(x) >= 150)

#'prepare for recurse by exporting to file
for(i in 1:length(data)){
  write_csv(data[[i]], path = paste("../data2018/dataRecurse/id",
            unique(data[[i]]$id), "tide",
            unique(data[[i]]$tidalCycle, ".csv")))
}

#'prepare files list to read in data
recurseFiles = list.files(path = "../data2018/dataRecurse/", full.names = T)

library(recurse)

#'in a for loop, read files, make recurse, write to file, remove data
for(i in 1:length(recurseFiles)){
  x = read_csv(recurseFiles[i])

  tide = unique(x$tidalCycle); id = unique(x$id)

  x = x[,c("x", "y", "time", "id")]

  #'get revisits from a radius of 100m
  #'threshold of 10 minutes
  xRecurse = getRecursions(x = x, radius = 100, threshold = 10,
    timeunits = "mins", verbose = TRUE)

  #'get FPT as first residence time
  xFpt = xRecurse[["revisitStats"]] %>%
          group_by(coordIdX, visitIdX) %>%
          summarise(fpt = first(residenceTime))

  #'make tibble
  xRecurseData = tibble(id = id, tide = tide,
            residenceTime = xRecurse[["residenceTIme"]],
            revisits = xRecurse[["revisits"]],
            fpt = xFpt$fpt)

  #'clear memory
  rm(x, tide, id, xRecurse, xFpt); gc()

  #'write recurse to file
  write_csv(xRecurseData, path = paste("../data2018/dataForageRecurse/id",
            id, "tide",
            tide, ".csv"))

  #'remove data
  rm(xRecurseData); gc()
}

#### read data back in and get FPT ####
#'list files
recurseFiles = list.files(path = "../data2018/dataForageRecurse",
                          full.names = T)

#'read the files in
recurseData = lapply(recurseFiles, read_csv)

#'bind to existing data
data = map2(data, recurseData, cbind)

#### potential LTRAJ method ####

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
