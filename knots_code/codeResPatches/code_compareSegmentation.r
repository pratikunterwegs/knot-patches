#### code to compare segclust and kmeans ####

# print system specs
sessionInfo()

# load libs
library(tidyverse); library(segclust2d)
library(sf)

# load plot opts
source("codePlotOptions/ggThemePub.r")

# read data, warnings are supressed
data = read_csv("../data2018/data2018WithRecurse.csv")

#read griend as sf
griend = st_read("../griend_polygon/griend_polygon.shp")

# select id.tide combinations of interest and filter for res time
# rename id as bird
data2 = filter(data, 
              id.tide %in% c(547.110, 550.06, 593.102, 439.064, 572.114)) %>% 
  rename(bird = id) %>% 
  mutate(id.tide = as.factor(id.tide)) %>% 
  filter(residenceTime >= 10)

#### segclust 2d method ####

# choose parameters Kmax, lmin, and type
# segmentation happens on coords x and y
# Kmax = 25 # approx 2 per hour of the tidal cycle
lmin = 5 # at least 5 points per segment, ie, 50 seconds

# nest data
data2 = group_by(data2, id.tide) %>% nest()

# use segclust2d
data2 = mutate(data2, dataSeg = map(data, function(x){
  segmentation(x, lmin = 10, 
               seg.var = c("x", "y"),
               scale.variable = FALSE,
               Kmax = 200) %>% 
    augment()
}))

# make seg summary
data2$segSummary = map(data2$dataSeg, function(z){
  group_by(z, state_ordered) %>% 
    summarise(meanX = mean(x), meanY = mean(y), meanTime = mean(time))
})

# make multiple figures
plots = map2(data2$dataSeg, data2$segSummary, function(a,b,c){
  ggplot(griend)+
    geom_sf()+
    geom_path(data = a, aes(x,y), size = 0.2)+
    geom_point(data = b, aes(x,y, col = state_ordered))+
    geom_text(data = c, aes(meanX, meanY, label = state_ordered))
})

  
#### changed till here ####

# gather method classifications
data2 = mutate(data2, data = map(data, function(z){
  select(z, x, y, residenceTime, timeNum, segment, state_ordered) %>% 
    gather(segMethod, segNum, -x,-y,-residenceTime,-timeNum)
}))

# make list of plots
listplots = map(data$data, function(z){
  ggplot(griend)+
    geom_sf(size = 0.1)+
    geom_path(data = z, aes(x,y), col = 1, size = 0.01)+
    geom_point(data = z, aes(x,y, col = factor(segNum)), shape = 1)+
    scale_color_manual(values = pals::kovesi.rainbow(max(z$segNum)))+
    facet_wrap(~segMethod, 
               labeller = labeller(segMethod = c(segment = "K-means", state_ordered = "Lavielle")))+
    coord_sf(datum = NA)+
    themePubLeg()+
    theme(legend.position = "bottom")+
    labs(caption = Sys.time())
})

# show plots
map(listplots, print)

# make list
listplots2 = map(data$data, function(z){
  ggplot(z)+
    geom_line(aes(x = as.POSIXct(timeNum, origin = "1970-01-01"),
                  y = residenceTime), size= 0.1)+
    geom_point(aes(x = as.POSIXct(timeNum, origin = "1970-01-01"),
                   y = residenceTime, col = factor(segNum)))+
    scale_color_manual(values = pals::kovesi.rainbow(max(z$segNum)))+
    facet_grid(~segMethod,
               labeller = labeller(segMethod = c(segment = "K-means", state_ordered = "Lavielle")))+
    themePubLeg()+
    theme(legend.position = "bottom")+
    labs(caption = Sys.time(), x = "time")
})

# show plots
map(listplots2, print)

# convert to wide format
data = unnest(data) %>% 
  mutate(segMethod = ifelse(segMethod == "segment", "Kmeans", "Lavielle"), 
         id.tide = as.character(id.tide)) %>% 
  spread(segMethod, segNum)

# write to file
write_csv(data, path = "testSegmentationData.csv")