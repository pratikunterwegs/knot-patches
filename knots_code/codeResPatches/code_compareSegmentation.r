# print system specs
sessionInfo()

# load libs
library(tidyverse); library(segclust2d)
library(sf)

# load plot opts
source("../codePlotOptions/ggThemePub.r")

# read data, warnings are supressed
data = read_csv("../../data2018/data2018WithRecurse.csv")

#read griend as sf
griend = st_read("../../griend_polygon/griend_polygon.shp")

# select id.tide combinations of interest and filter for res time
# rename id as bird
data = filter(data, 
              id.tide %in% c(547.110, 550.06, 593.102, 439.064, 572.114)) %>% 
  filter(residenceTime >= 10) %>% 
  rename(bird = id)

#print as wrapped panel
ggplot(griend)+
  geom_sf()+
  geom_path(data = data, aes(x, y), size = 0.2)+
  geom_point(data = data, aes(x, y), size = 0.1, col = 2, shape = 1)+
  facet_wrap(~id.tide, ncol = 3)+
  coord_sf(datum = NA)+
  themePub()+
  labs(title = "tracks: red points are fixes", caption = Sys.time())

# guess time between segments as number of moves above 90th percentile
funcGetClusters = function(x){
  # needs a numeric vector
  assertthat::assert_that(is.numeric(x), msg = "x is not a numeric vector!")
  y = quantile(x, probs = 0.01)
  z = sum(x <= y)
  return(z)
} 

# setup kmeans function using guessed number of residence patches
funcSegment = function(x){
  # kmeans reqs a matrix or coercable object such as a df
  assertthat::assert_that(is.data.frame(x), msg = "x is not a df!")
  nAssumedPatches = funcGetClusters(x$residenceTime)
  x1 = kmeans(x[,c("x", "y", "residenceTime")], centers = nAssumedPatches)
  return(x1[["cluster"]])
}

# choose parameters Kmax, lmin, and type
# segmentation happens on coords x and y
Kmax = 25 # approx 2 per hour of the tidal cycle
lmin = 10 # at least 10 points per segment
type = "home-range"

# nest data
data = group_by(data, id.tide) %>% nest()

# use Kmeans
# assign new column in data$data for segment/cluster
data = mutate(data, data = map(data, function(df){
  mutate(df, segment = funcSegment(df))
}))

# use segclust2d
data = mutate(data, data = map(data, function(x){
  segmentation(x, Kmax = Kmax, lmin = lmin, 
               coord.names = c("x", "y"), seg.var = "residenceTime") %>% 
    augment()
}))

# gather method classifications
data = mutate(data, data = map(data, function(z){
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