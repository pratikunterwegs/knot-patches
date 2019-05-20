#### code for residence patch maps ####

# load libs
library(sf)
library(readr)
# load residence patch polygon geometries
# this is the raw spatial/coordinate data
load("../data2018/spatials/residencePatches.rdata")

# add residence patch data; the id and segment etc
# id 596 tidal Cycle 11 is missing, exclude for now
# load data
dataFiles = list.files("../data2018/segmentation/", full.names = T)

# read data and filter for quality, at least 5 points per segment
data = map(dataFiles, read_csv) %>% 
  bind_rows() %>% 
  mutate(id = substr(id.tide, 1, 3),
         tidalCycle = substr(id.tide, 5, 7))

# summarise data into id - tidalCycle
library(dplyr)
library(purrr)
library(tidyr)
dataSummary = data %>% 
  group_by(id, tidalCycle, segment) %>% 
  summarise_at(vars(x, y, residenceTime), list(~mean(.)))
# merge resPatches to a single sfc object
#resPatches = map(resPatches, st_union)
resPatches = st_sfc(reduce(resPatches, rbind))
# make a geometry column in dataSummary
dataSf = st_set_geometry(dataSummary, resPatches) %>% 
  `st_crs<-`(32631)

#### plot 100 examples with points ####
source("codePlotOptions/ggThemePub.r")

# load griend file
griend = st_read("../griend_polygon/griend_polygon.shp")
library(ggplot2)

# subset area polygons
dataSfSubset = dataSf %>%
  mutate(bird = id) %>% 
  group_by(bird, tidalCycle) %>% 
  nest() %>% 
  sample_n(25)

# get a list of polygons
dataSfSample = right_join(dataSf, dataSfSubset %>% select(bird, tidalCycle),
                          by = c("id" = "bird", "tidalCycle")) %>% 
  mutate(bird = id) %>% 
  plyr::dlply(c("bird", "tidalCycle"))

# # select points from data to match
dataSubset = data %>% filter(id == dataSfSubset$bird,
                             tidalCycle == dataSfSubset$tidalCycle) %>% 
  mutate(bird= id) %>% 
  plyr::dlply(c("bird", "tidalCycle"))

# make plot in a list

listPlots = map2(dataSfSample, dataSubset, function(z, w){
  ggplot(griend)+
    geom_sf(col = 2)+
    geom_sf(data = z, aes(fill = factor(segment)), alpha = 0.2)+
    # 
    geom_point(data = w, aes(x, y, col = factor(segment)), size = 0.2)+
    geom_path(data = w, aes(x, y, col = factor(segment)), size = 0.1)+
    # 
    facet_wrap(bird~tidalCycle, ncol = 5)+
    # 
    scale_fill_manual(values = pals::kovesi.rainbow(length(unique(z$segment))))+
    scale_colour_manual(values = pals::kovesi.rainbow(length(unique(w$segment))))+
    
    #coord_sf(datum = NA)+
    themePubLeg()
})

# export to single pdf
pdf(file = "../figs/figResPatchesMap.pdf", width = 297/25.4, height = 210/25.4)
for (i in 1:25) {
  print(listPlots[[i]])
}
dev.off()