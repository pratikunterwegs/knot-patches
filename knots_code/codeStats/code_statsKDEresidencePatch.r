#### make KDEs from residence patches ####

# this code makes 95% kernel density estimates from residence patches

# load libs
library(tidyverse); library(readr)
source("codePlotOptions/ggThemePub.r")
# load data
dataFiles = list.files("../data2018/segmentation/", full.names = T)

# read data and filter for quality, at least 5 points per segment
data = map(dataFiles, read_csv) %>% 
  map(function(x) plyr::dlply(x, "segment")) %>% 
  map(function(x) {
    keep(x, function(y) nrow(y) >= 5)
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
    # get the positions matrix
    pos = x[,c("x", "y")]
    # get the plugin H
    H.pi = Hpi(x = pos)
    # get the KDE
    resPatchKDE = kde(pos, H = H.pi, compute.cont = T)
    # draw contour lines
    contLines = contourLines(resPatchKDE$eval.points[[1]], resPatchKDE$eval.points[[2]], 
                             resPatchKDE$estimate, level = contourLevels(resPatchKDE, 0.05))
    
    # convert each to polygon via linestring using sf directly
    contPoly = lapply(contLines, function(z){
      st_polygonize(st_linestring(x = (cbind(z[["x"]], z[["y"]]))))})
    
    # reduce possible multiple polygons to a sfg objects
    # then convert sfg to sfc objects
    contPoly = st_sfc(purrr::reduce(contPoly, rbind))
    # now combine all sfc objects into a single polygon
    resPatches[[i]][[j]] = st_combine(contPoly)
  }
  # combine the jth objects of the ith track into a single sfc
  # this sfc retains attributes of the segments (j in number)
  # such as area, which are important
  resPatches[[i]] = st_sfc(purrr::reduce(resPatches[[i]], rbind))
}

# save to rdata
save(resPatches, file = "../data2018/spatials/residencePatches.rdata")

#### get residence patch summaries ####
# calculate areas in m2 (in map units squared, here map units are metres)
resPatchArea = lapply(resPatches, st_area)

# combine with a summary of the filtered original data
dataCombined = map(data, function(x){
  map(x, function(y){
    y %>% summarise(id = unique(substr(id.tide, 1, 3)),
                    tidalCycle = as.numeric(unique(substr(id.tide, 5, 7))),
                    seg = unique(segment),
                    timeSegStart = min(timeNum),
                    timeSegEnd = max(timeNum))
  }) %>% 
    bind_rows()
})

# add the segment areas
dataCombined = map2(dataCombined, resPatchArea, function(x,y){
  mutate(x, area = y)
})

# bind rows and export
dataCombined = bind_rows(dataCombined)

# write to file
write_csv(dataCombined, "../data2018/data2018residencePatchAreas.csv")