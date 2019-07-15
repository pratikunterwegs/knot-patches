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
    {mcp <- st_as_sf(df, coords = c("x","y")) %>% st_union() %>% 
      st_convex_hull() %>% `st_crs<-`(32631)
    
    mcpArea <- as.numeric(st_area(mcp))},
    error = function(e){ print(glue('problems with bird {unique(df$id)} in tide {unique(df$tidalcycle)}'))})
  
  tryCatch(
  # sum distance
  {df <- setDT(df)[,.(totalDist = sum(dist, na.rm = T)), by=list(id, tidalcycle)]},
  error = function(e){ print(glue('problems with bird {unique(df$id)} in tide {unique(df$tidalcycle)}'))})
  
  # add area
  df[,mcpArea:=mcpArea]
  
  # make df
  setDF(df)
  
  df <- cbind(df, mcp) %>% st_as_sf()
  
  # return
  return(df)
  
})

# filter data because there were problems with 1 row data
data <- keep(data, function(z){
  # check if both mcp area and dist are present
  sum(c("totalDist", "mcpArea") %in% names(z)) == 2
})

# export to shapefile
mcpBirds <- reduce(data, rbind)
# get bounding box
bbox <- mcpBirds %>% st_union()

st_write(bbox, dsn = "../data2018/spatials/newUnionPatches", layer = "unionPatches.shp",
         driver = "ESRI Shapefile")

# bind to df
data <- map(data, st_drop_geometry) %>% bind_rows()

# write to file
fwrite(data, file = "../data2018/dataMCParea.csv")

#### plot mcp and distance vs explore score ####
# read in behav scores
behavScore <- read_csv("../data2018/behavScores.csv")

# pot ops
source("codePlotOptions/ggThemeKnots.r")

# simple ci function
ci = function(x){
  qnorm(0.975)*sd(x, na.rm = T)/sqrt((length(x)))
}

# join explore score and area dist data
data = inner_join(data, behavScore, by = "id")

# write to file
fwrite(data, file = "../data2018/dataMCParea.csv")

# end here