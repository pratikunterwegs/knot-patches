#### code to get total distance and mcp ####

library(tidyverse); library(data.table)

library(sf)

# list files
dataFiles <- list.files("../data2018/oneHertzData/recursePrep/", full.names = T)

data <- map_df(dataFiles[1:10], function(filename){
  
  # place a try catch here
  # read in data
  df <- fread(filename)[!is.na(dist),.(x,y,time,id, tidalcycle, dist)]
  
  # make sf, union, get convex hull area
  mcp <- st_as_sf(df, coords = c("x","y")) %>% st_union() %>% st_convex_hull() %>% st_area()
  
  # sum distance
  df <- df[,.(totalDist = sum(dist, na.rm = T)), by=list(id, tidalcycle)]
  
  # add area
  df[,mcpArea:=mcp]
  
  # make df
  setDF(df)
  
  # return
  return(df)
  
})

# write to file
fwrite(data, file = "../data2018/oneHertzData/dataMCParea.csv")