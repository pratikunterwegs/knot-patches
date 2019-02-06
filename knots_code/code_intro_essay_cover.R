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
#data = data[[2]]

#'convert to x,y,t
data = data %>% 
  map(function(x) select(x, time=TIME, x=X, y=Y, covxy = COVXY, towers = NBS)) %>% 
  map(function(x) mutate(x, time = plyr::round_any(time/1000, 10))) %>% 
  map(function(x) x %>% filter(towers > 3) %>% group_by(time) %>% summarise_all(mean))

library(sf)
#'make linestring df object
dataline = map(data, function(x){
  st_linestring(x = cbind(x$x, x$y), dim = "XY")})

#'make points
datapoints = map(data, function(x){
  st_multipoint(x = cbind(x$x, x$y), dim = "XY")
})


#'assign crs and make sfc
dataline = map(dataline, function(x){st_sfc(x, crs = 32631)})
datapoints = map(datapoints, function(x){st_sfc(x, crs= 32631)})

#'plot all 10
x11(); par(mfrow = c(2,5)); for(i in 1:10) plot(dataline[[i]])

x11(); plot(datapoints[[2]], cex = 0.1)

#'write knot 471 to shapefile
write_sf(dataline[[2]], dsn = "intro_essay_track", layer = "knot_track_471", driver = "ESRI Shapefile")
#'write points
write_sf(datapoints[[2]], dsn = "intro_essay_points", layer = "knot_points_471", driver = "ESRI Shapefile")

#'get neutral landscape
library(NLMR);library(raster)
landscape = nlm_gaussianfield(ncol = 1480, nrow = 1050, resolution = 1, autocorr_range = 100)

#'save raster
#writeRaster(landscape, filename = "cover_raster.tif", format = "GTiff", overwrite = T)
library(RColorBrewer)
pal = colorRampPalette(brewer.pal(9, "BrBG")[c(1:9)])(20)

png(filename = "intro_essay_cover_part01.png", width = 148, height = 105, units = "mm", res = 300)
par(mar = c(0,0,0,0)); image(landscape, col = pal, axes = F, box =F, bty = "n", legend=F)
dev.off()