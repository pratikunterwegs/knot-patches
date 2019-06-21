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
dataFiles <- list.files(path = "../data2018/oneHertzData/", full.names = TRUE)

# make dir for segmentation output
if(!dir.exists("../data2018/oneHertzData/recursePrep")){
  dir.create("../data2018/oneHertzData/recursePrep")
}

# map over all files, filter data for release + 24 hours, add distances
# and write to file
map(dataFiles, function(df){
  tempdf <- read_csv(df) %>% setDT() # use readcsv rather than fread
  
  print(glue('read in {unique(tempdf$id)}...'))
  
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
    nest()
  
  tryCatch(
    {
      # get distances
      tempdf$data <- map(tempdf$data, function(df){
        mutate(df, dist = funcDistance(df, "x", "y"))
      })
    },
    error = function(e) {print(glue('problems in distance calculation of id {unique(tempdf$id)}'))}
  )
  
  # write to file in id and tidal cycle combination
  pmap(list(tempdf$id, tempdf$tidalcycle, tempdf$data), function(a, b, c) {
    
    fwrite(mutate(c, id = a, tidalcycle = b), 
           file = glue("../data2018/oneHertzData/recursePrep/", a,
                       "_", str_pad(b, 3, pad = "0")))
    
    print(glue('id {unique(a)} in tide {unique(b)} written to file'))
    
  })
  
  return(glue('id {unique(tempdf$id)} and tidal cycle subsets written to file'))
})



# # split by id and tidal cycle
# dataForSeg <- map(dataForSeg, function(x){
#   group_by(x, tidalcycle, id) %>% nest()
# }) %>% bind_rows()

# paste id and tide for easy extraction, pad tide number to 3 digits
library(glue)
pmap(list(dataForSeg$id, dataForSeg$tidalcycle, dataForSeg$data), function(a, b, c) {
  
  fwrite(mutate(c, id = a, tidalcycle = b), 
         file = glue("../data2018/oneHertzDataSubset/recursePrep/", a,
                     "_", str_pad(b, 3, pad = "0")))
})

# remove previous data
rm(tempdf, dataForSeg, releaseData); gc()