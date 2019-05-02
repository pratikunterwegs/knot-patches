#### make KDEs from residence patches ####

# this code makes 95% kernel density estimates from residence patches

# load libs
library(tidyverse); library(readr)
source("codePlotOptions/ggThemePub.r")
# load data
dataFiles = list.files("../data2018/segmentation/", full.names = T)
# read data
data = map(dataFiles, read_csv) %>% 
  map(function(x) plyr::dlply(x, "segment")) %>% 
  map(function(x) {
    keep(x, function(y) nrow(y) >= 20)
  })

# check that all lists have at least one element
lenList = map_dbl(data, length)
assertthat::assert_that(min(lenList) > 0)

# load kde functions
# sp provides spatial classes, ks provides kde functions
library(sp); library(ks)

# make empty list to hold residence patch KDEs
# this list has the same structure as the data
resPatches = data %>% map(function(x){map(x, function(y) NULL)})

# run a KDE function on each of the residence patches
for (i in 1:length(data)) {
  for(j in 1:length(data[[i]])){  
    x = data[[i]][[j]]
    #'get the positions matrix
    pos = x[,c("x", "y")]
    #'get the plugin H
    H.pi = Hpi(x = pos)
    #'get the KDE
    resPatchKDE = kde(pos, H = H.pi, compute.cont = T)
    #'draw contour lines
    contLines = contourLines(resPatchKDE$eval.points[[1]], resPatchKDE$eval.points[[2]], 
                             resPatchKDE$estimate, level = contourLevels(resPatchKDE, 0.05))
    #'convert each to polygon
    contPoly = lapply(contLines, function(y) Polygon(y[-1]))
    #'make polygons
    contPolyN = Polygons(contPoly, paste("resPatch", i, j, sep = "_"))
    #'make spatial polygon
    resPatches[[i]][[j]] = contPolyN
  }
  resPatches[[i]] = SpatialPolygons(resPatches[[i]], 1:length(resPatches[[i]]))
}

# save to rdata
save(resPatches, file = "../data2018/spatials/residencePatches.rdata")

#### get residence patch summaries ####
# convert to sf class
library(sf)
for(i in 25:length(resPatches)){
  resPatches[[i]] = st_as_sf(resPatches[[i]])
}
