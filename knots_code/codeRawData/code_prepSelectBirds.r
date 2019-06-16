#### code to deal with raw data from selected birds ####

# load libs
library(tidyverse); library(data.table)
library(glue)

# list files
dataFiles <- list.files("../data2018/", pattern = "knots2018", full.names = T)

# selected data
selectData <- list()

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
tides <- fread("../data2018/tidesSummer2018.csv")[tide == "H"]

# read in data and add tidal cycles
dataFiles <- list.files(path = "../data2018/oneHertzData/", full.names = TRUE)

# assign and write
map(dataFiles, function(df){
  tempdf <- read_csv(df) %>% setDT()
  tempdf[,TIME:=floor(TIME/1e3)]
  tempdf <- merge(tempdf, tides, by.x = "TIME", by.y = "timeNum", all = TRUE)
  setorder(tempdf, TIME)
  tempdf <- tempdf[,tide:=!is.na(tide)
         ][, tidalCycle:=cumsum(tide)
           ][,tidalTime:= (TIME - min(TIME))/60,by=tidalCycle
             ][complete.cases(X),]
              
  tempdf[,`:=` (temp = NULL, tide = NULL, level = NULL, time = NULL)
         ][,tidalCycle:=tidalCycle-min(tidalCycle)+1]

  fwrite(tempdf, file = df)
  return("overwritten with tidal cycles")
})


