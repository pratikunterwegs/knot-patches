#### code to diagnose methods ####

# load libs and data
library(data.table); library(tidyverse)
library(glue); library(sf)

# source distance function
source("codeMoveMetrics/functionEuclideanDistance.r")

# function for resPatches arranged by time
source("codeMoveMetrics/func_residencePatch.r")

# read in recurse data for selected birds
dataRevFiles <- list.files("../data2018/oneHertzData/recurseData/", full.names = T)[1:5]

# get time to high tide from written data
dataHtFiles <- list.files("../data2018/oneHertzData/recursePrep/", full.names = T)[1:5]

# make dataframe of assumption parameters
resTimeLimit = c(2, 4, 10); travelSeg = c(5)
assumpData <- crossing(resTimeLimit, travelSeg)

# make data - param assump combo df
dataToTest <- tibble(revdata = dataRevFiles, htData = dataHtFiles, assump = list(assumpData)) %>% 
  unnest(cols = assump)

#### testing the patches produced by different assumptions ####

# passing data to a function that manually segments and returns patches
data <- purrr::pmap(dataToTest, funcSegPath)

#### separate funciton to return res patches ####
funcReturnPatchData <- function(segData){
  # get patch data
  patchData <- funcGetResPatches(segData, returnSf = TRUE)
  
  # remove what seems to be the sf data
  patchData <- patchData # %>% dplyr::select(-data)
  
  # add the parameter assumptions
  patchData[[1]]$resTimeLimit = segData$resTimeLimit[1]
  patchData[[1]]$travelSeg = segData$travelSeg[1]
  
  # now add to spatial obj for plotting
  patchData[[2]]$resTimeLimit = segData$resTimeLimit[1]
  patchData[[2]]$travelSeg = segData$travelSeg[1]
  
  return(patchData)
}

# get patches
patches <- map(data, funcReturnPatchData)

# add names and transpose
patches <- map(patches, function(df){
  names(df) = c("data", "spatial")
  return(df)
}) %>% 
  transpose()

# bind rows for plotting
patches <- map(patches, bind_rows)

# handle spatial data
patches$spatial <- st_sf(patches$spatial, sf_column_name = "geometry")

# make patch data an sf column
patches$data <- patches$data %>% 
  st_as_sf(coords = c("X_mean", "Y_mean"))

# make data sf
data = bind_rows(data) %>% 
  st_as_sf(coords = c("x","y"))

# set crs
st_crs(patches$spatial) = 32631; st_crs(patches$data) = 32631; st_crs(data) = 32631

# make lines from patches
travelpaths = patches$data
travelpaths = travelpaths %>% 
  bind_cols(st_coordinates(.) %>% as_tibble()) %>% 
  st_drop_geometry() %>% 
  group_by(tidalcycle, resTimeLimit) %>% 
  nest() %>% 
  mutate(data = map(data, function(df){
    st_linestring(as.matrix(df[,c("X", "Y")]))
  }))
travelpaths = st_sf(travelpaths, sf_column_name = "data")
st_crs(travelpaths) = 32631

#### export data as shapefile ####
# export
st_write(patches$data, dsn = "../data2018/spatials/testPatches/data",
         layer = "patchData", driver = "ESRI Shapefile")

st_write(data, dsn = "../data2018/spatials/testPatches/rawData",
         layer = "rawdata", driver = "ESRI Shapefile")

st_write(patches$spatial, dsn = "../data2018/spatials/testPatches/patches",
         layer = "patchOutline", driver = "ESRI Shapefile", delete_layer = T)

st_write(travelpaths, dsn = "../data2018/spatials/testPatches/paths",
         layer = "travelPaths", driver = "ESRI Shapefile")
#### plot data ####
library(tmap)
map = 
  tm_shape(data)+
  tm_dots(alpha = 0.2, size = 0.01, shape = 4,
          col = "grey")+
  tm_facets(by = c("resTimeLimit"), along = c("tidalcycle"))+
  
  tm_shape(patches$spatial)+
  tm_polygons(col = "patch", style = "cat", alpha = 0.5,
              border.col = "dodgerblue",
              palette = "Paired")+
  
  
  
  tm_facets(by = c("resTimeLimit"), along = c("tidalcycle"))+
  
  tm_shape(travelpaths)+
  tm_lines(col = "red")+
  
  
  tm_facets(by = c("resTimeLimit"), along = c("tidalcycle"))+
  
  tm_shape(patches$data)+
  tm_dots(shape = 21, col = "blue",
          size = "duration")+
  
  
  tm_facets(by = c("resTimeLimit"), along = c("tidalcycle"))+
  tm_layout(legend.outside = F)

tmap_save(tm = map,
          filename = "../figs/fig_newPatches_testSegments_435_8to10.pdf",
          height = 10, width = 12)
