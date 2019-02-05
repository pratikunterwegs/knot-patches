#### script for 2018 knot tracks for intro essay ####

library(tidyverse)

#'load a single 10 indiv data file
#'loading 10 to 20
load("knots2018raw10to20.rdata")
#'remove empty elements
data = data2018.raw %>% 
  keep(function(x)length(x)>0) %>% 
  map(bind_rows)
#'keep only data[1] now
#data = data[[6]]

#'convert to x,y,t
data = data %>% map(function(x) select(x, time=TIME, x=X, y=Y, covxy = COVXY))

library(sf)
#'make linestring df object
dataline = map(data, function(x){
  st_linestring(x = cbind(x$x, x$y), dim = "XY")})

dataline = map(dataline, function(x){st_sfc(x, crs = 32630)})
#'plot all 10
par(mfrow = c(2,5))
for(i in 1:10) plot(dataline[[i]])

#'write 2nd agent to shapefile
write_sf(dataline[[2]], dsn = "intro_essay_track", layer = "knot_track_471", driver = "ESRI Shapefile")
