#### code to deal with raw data from selected birds ####

# load libs
library(tidyverse); library(data.table)
library(glue)

# list files
dataFiles <- list.files("../data2018/", pattern = "knots2018", full.names = T)

# make output dir if non existent
if(!dir.exists("../data2018/oneHertzData")){
  dir.create("../data2018/oneHertzData")
}

for(i in 1:length(dataFiles)) {
  load(dataFiles[i])
  
  # prep data to compare
  data <- data2018.raw %>%
    keep(function(x) length(x) > 0) %>% # keep non null lists
    flatten() %>% # flatten this list structure
    keep(function(x) nrow(x) > 0) # keep dfs with data
  
  rm(data2018.raw); gc()
  
  names <- map_chr(data, function(x) as.character(unique(x$TAG - 3.1001e10)))
  
  map2(data, names, function(x, y){
    fwrite(x, file = glue("../data2018/oneHertzData/", y, ".csv"))
  })
  
}

#### assign tidal cycles ####
tides <- read_csv("../data2018/tidesSummer2018.csv") %>% filter(tide == "H")

# read in data and add tidal cycles
dataFiles <- list.files(path = "../data2018/oneHertzData/", full.names = TRUE, pattern = "csv")

# assign and write
map(dataFiles, function(df){
  # read in the file with readr and make data.table
  tempdf <- read_csv(df) %>% setDT()
  # floor the time in milliseconds to seconds
  tempdf[,TIME:=floor(TIME/1e3)]
  # merge data to insert high tides within movement data
  tempdf <- merge(tempdf, tides, by.x = "TIME", by.y = "timeNum", all = TRUE)
  # arrange by time to position high tides correctly
  setorder(tempdf, TIME)
  # modify the df as follows
  tempdf <- tempdf[,tide:=!is.na(tide) # check if the tide has a value, ie, check for high tide
         ][, tidalCycle:=cumsum(tide) # cumulative sum the tide column, thus counting only high tides
           ][,tidalTime:= (TIME - min(TIME))/60,by=tidalCycle # within each tidal cycle, get time to high tide
             ][complete.cases(X),] # remove rows with incomplete cases of X
              
  tempdf[,`:=` (temp = NULL, tide = NULL, level = NULL, time = NULL)
         ][,tidalCycle:=tidalCycle-min(tidalCycle)+1]

  fwrite(tempdf, file = df)
  return("overwritten with tidal cycles")
})

# end here