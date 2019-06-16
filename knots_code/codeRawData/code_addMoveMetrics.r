#### code add metrics ####

# read in all birds and select some tidal cycles
library(tidyverse); library(data.table)
library(glue)
library(fasttime) # fast date-time operations

# select tides
selected_tides <- c(seq(5, 100, 15))

# filter out 24 hours after release
# read in release time
releaseData <- fread("../data2018/behavScores.csv", )[,timeNumRelease := as.numeric(fastPOSIXct(Release_Date))]

dataSubset <- map(dataFiles, function(df){
  tempdf <- read_csv(df) %>% setDT() # use readcsv rather than fread
  newNames <- str_to_lower(names(tempdf))
  setnames(tempdf, newNames)
  
  tempdf <- tempdf[tidalcycle %in% c(selected_tides),
                   ][,id:=(tag - 3.1001e10)]
  
  relTime <- merge(releaseData, tempdf, by = "id", all = FALSE, no.dups = T)$timeNumRelease
  # filter data 24 hours post release time  
  tempdf <- tempdf[time >= (relTime + 24 * 3600),]
  
  rm(relTime)
  
  return(tempdf)
})

# bind and write to file
fwrite(bind_rows(dataSubset), file = "../data2018/oneHertzDataSubset/data2018oneHzSelTides.csv")

# split data and remove dfs with less than 100 obs
dataForSeg <- dataSubset %>% keep(function(x) nrow(x) > 100)

source("codeMoveMetrics/functionEuclideanDistance.r")
# calc distance
dataDist <- map(dataForSeg, function(df){
  
  dist <- funcDistance(df, "x", "y")
  
})

# add distance to reg data frame
dataForSeg <- map2(dataForSeg, dataDist, function(z,w){
  mutate(z, dist = w)
})

# make dir for segmentation output
if(!dir.exists("../data2018/oneHertzDataSubset/recursePrep")){
  dir.create("../data2018/oneHertzDataSubset/recursePrep")
}

# split by id and tidal cycle
dataForSeg <- map(dataForSeg, function(x){
  group_by(x, tidalcycle, id) %>% nest()
}) %>% bind_rows()

# paste id and tide for easy extraction, pad tide number to 3 digits
library(glue)
pmap(list(dataForSeg$id, dataForSeg$tidalcycle, dataForSeg$data), function(a, b, c) {
  
  fwrite(mutate(c, id = a, tidalcycle = b), 
         file = glue("../data2018/oneHertzDataSubset/recursePrep/", a,
                     "_", str_pad(b, 3, pad = "0")))
})

# remove previous data
rm(tempdf, dataForSeg, releaseData); gc()