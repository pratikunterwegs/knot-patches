#### code to get total distance and mcp ####

library(tidyverse); library(data.table)

# list files
dataFiles <- list.files("../data2018/oneHertzData/recursePrep/", full.names = T)

data <- map_df(dataFiles, function(filename){
  
  # read in data
  df <- fread(filename)[!is.na(dist),.(x,y,time,id, tidalcycle, dist)]
  # sum distance
  df[,.(totalDist = sum(dist, na.rm = T)), by=.(id, tidalcycle)]
  
  # make df
  setDF(df)
  
})

# get MCPs
data_mcp <- map(dataFiles, function(filename){
  # read in data
  df <- setDF(fread(filename)[,]
}) 