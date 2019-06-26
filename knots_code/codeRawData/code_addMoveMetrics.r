#### code add metrics ####

# read in all birds and select some tidal cycles
library(tidyverse); library(data.table)
library(glue)
library(fasttime) # fast date-time operations

# select tides
# selected_tides <- c(seq(5, 100, 15))

# filter out 24 hours after release
# read in release time
releaseData <- fread("../data2018/behavScores.csv", )[,timeNumRelease := as.numeric(fastPOSIXct(Release_Date))]

# get distance function
source("codeMoveMetrics/functionEuclideanDistance.r")

# list files
dataFiles <- list.files(path = "../data2018/oneHertzData/", pattern = "csv", full.names = TRUE)

# make dir for segmentation output
if(!dir.exists("../data2018/oneHertzData/recursePrep")){
  dir.create("../data2018/oneHertzData/recursePrep")
}

# map over all files, filter data for release + 24 hours, add distances
# and write to file
map(dataFiles, function(df){
  tempdf <- read_csv(df) %>% setDT() # use readcsv rather than fread
  
  # calculate which tag was read in
  print(glue('read in bird {unique(tempdf$TAG) - 3.1001e10}...'))
  
  # assign names
  newNames <- str_to_lower(names(tempdf))
  setnames(tempdf, newNames)
  
  tempdf <- tempdf[
    # tidalcycle %in% c(selected_tides),
    #                ][
    ,id:=(tag - 3.1001e10)]
  
  relTime <- releaseData[releaseData$id == unique(tempdf$id),]$timeNumRelease
  # filter data 24 hours post release time  
  tempdf <- tempdf[time >= (relTime + 24 * 3600),] %>% 
    select(id, tidalcycle, time, x, y, nbs, covxy, tidaltime)
  
  rm(relTime)
  
  # group by id and tidal cycle
  tempdf <- group_by(tempdf, id, tidalcycle) %>% 
    nest() %>% 
    # make sure dataframe has more than 1 row
    mutate(toKeep = map_chr(data, nrow) > 1) %>% 
    filter(toKeep == TRUE) %>% select(-toKeep)
  
  # distance function fails once in a while
  tryCatch(
    {
      # get distances
      tempdf$data <- map(tempdf$data, function(z){
        mutate(z, dist = funcDistance(z))
      })
      
      # write to file in id and tidal cycle combination
      pmap(list(tempdf$id, tempdf$tidalcycle, tempdf$data), function(a, b, c) {
        
        fwrite(mutate(c, id = a, tidalcycle = b), 
               file = glue("../data2018/oneHertzData/recursePrep/", a,
                           "_", str_pad(b, 3, pad = "0")))
        
        print(glue('id {unique(a)} in tide {unique(b)} written to file'))
        
      })
      
    },
    error = function(e) {print(glue('problems in distance calculation of id {unique(tempdf$id)}'))}
  )
  return(glue('id {unique(tempdf$id)} and tidal cycle processed'))
})

## end here