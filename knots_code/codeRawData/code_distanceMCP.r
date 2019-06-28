#### code to get total distance and mcp ####

library(tidyverse); library(data.table)
library(glue)
library(sf)

# list files
dataFiles <- list.files("../data2018/oneHertzData/recursePrep/", full.names = T)

data <- map(dataFiles, function(filename){
  
  # read in data
  df <- fread(filename)[,.(x,y,time,id, tidalcycle, dist)]
  
  # message
  print(glue('bird {unique(df$id)} in tide {unique(df$tidalcycle)} has {nrow(df)} obs'))
  
  # makde df
  setDF(df)
  
  tryCatch(
    # make sf, union, get convex hull area
    {mcp <- st_as_sf(df, coords = c("x","y")) %>% st_union() %>% st_convex_hull() %>% st_area()},
    error = function(e){ print(glue('problems with bird {unique(df$id)} in tide {unique(df$tidalcycle)}'))})
  
  tryCatch(
  # sum distance
  {df <- setDT(df)[,.(totalDist = sum(dist, na.rm = T)), by=list(id, tidalcycle)]},
  error = function(e){ print(glue('problems with bird {unique(df$id)} in tide {unique(df$tidalcycle)}'))})
  
  # add area
  df[,mcpArea:=mcp]
  
  # make df
  setDF(df)
  
  # return
  return(df)
  
})

# write to file
fwrite(data, file = "../data2018/oneHertzData/dataMCParea.csv")