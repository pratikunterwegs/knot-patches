#### code to compare segclust and kmeans ####

# print system specs
sessionInfo()

# load libs
library(tidyverse); library(segclust2d)
library(sf)

# load plot opts
source("codePlotOptions/ggThemePub.r")

# read data, warnings are supressed
data = read_csv("../data2018/data2018WithRecurse.csv") %>% 
  select(id, timeNum, x, y, residenceTime, id.tide, time)

dataDist = read_csv("../data2018/data2018withDistances.csv") %>% 
  select(id, timeNum, distance)

#read griend as sf
griend = st_read("../griend_polygon/griend_polygon.shp")

# select id.tide combinations of interest and filter for res time
# rename id as bird
data2 = filter(data, 
              id.tide %in% c(547.110, 550.06, 593.102, 439.064, 572.114)) %>% 
  rename(bird = id) %>% 
  mutate(id.tide = as.factor(id.tide)) %>% 
  left_join(dataDist, by = c("bird"="id", "timeNum")) %>% 
  filter(!is.na(distance), residenceTime >= 10)

#### segclust 2d method ####

# choose parameters Kmax, lmin, and type
# segmentation happens on coords x and y
# Kmax = 25 # approx 2 per hour of the tidal cycle
lmin = 5 # at least 5 points per segment, ie, 50 seconds

# nest data
data2 = group_by(data2, id.tide) %>% nest()

# use segclust2d on restime and time, ordered by time
data2$dataSegResTime = map(data2$data, function(x){
  segmentation(x, lmin = 5, 
               seg.var = c("residenceTime", "timeNum"),
               order.var = "timeNum",
               scale.variable = FALSE,
               Kmax = 100) %>% 
    augment()})

# use on distance ordered by time
data2$dataSegDist = map(data2$data, function(x){
  segmentation(x, lmin = 5, 
               seg.var = c("distance", "timeNum"),
               order.var = "timeNum",
               scale.variable = FALSE,
               Kmax = 100) %>% 
    augment()})

# make seg summary
data2$segSummaryResTime = map(data2$dataSegResTime, function(z){
  group_by(z, state_ordered) %>% 
    summarise_at(vars(x,y,time), list(mean=mean, start=first, end=last))
})

# make distance seg summary
data2$segSummaryDist = map(data2$dataSegDist, function(z){
  group_by(z, state_ordered) %>% 
    summarise_at(vars(x,y,time), list(mean=mean, start=first, end=last))
})

# make multiple figures for res time seg
plotsSegResTime = map2(data2$dataSegResTime, data2$segSummaryResTime, function(a,b){
  ggplot(griend)+
    geom_sf()+
    coord_sf(datum=NA)+
    geom_text(data = b, aes(x_mean, y_mean, label = state_ordered),
              fontface = "bold")+
    
    geom_path(data = a, aes(x,y), size = 0.2)+
    geom_point(data = a, aes(x,y, col = factor(state_ordered)))+
    scale_colour_manual(values = pals::kovesi.rainbow(max(a$state_ordered)))+
    theme_void()+
    theme(legend.position = "bottom")+
    labs(caption = Sys.time(), subtitle = "segmented by residence time",
         col = "segment",
         title = first(a$bird))
}) %>% map(function(x) ggplotGrob(x))

# figures for distance seg
plotsSegDist = map2(data2$dataSegDist, data2$segSummaryDist, function(a,b){
  ggplot(griend)+
    geom_sf()+
    coord_sf(datum=NA)+
    geom_text(data = b, aes(x_mean, y_mean, label = state_ordered),
              fontface = "bold")+
    
    geom_path(data = a, aes(x,y), size = 0.2)+
    geom_point(data = a, aes(x,y, col = factor(state_ordered)))+
    
    scale_colour_manual(values = pals::kovesi.rainbow(max(a$state_ordered)))+
    theme_void()+
    theme(legend.position = "bottom")+
    labs(caption = Sys.time(), subtitle = "segmented by distance",
         col = "segment", title = first(a$bird))
}) %>% map(function(x) ggplotGrob(x))

# make restime vs time and distance vs time plot
dataPlotRes = map(data2$dataSegResTime, function(a){
  
  ggplot(a)+
    geom_path(aes(time,residenceTime))+
    geom_point(aes(time,residenceTime, col = factor(state_ordered)))+
    scale_colour_manual(values = pals::kovesi.rainbow(max(a$state_ordered)))+
    theme(legend.position = "bottom", legend.direction = "horizontal")+
    labs(colour = "segment", caption = Sys.time(),
         title = first(a$bird))
  
}) %>% map(function(x) ggplotGrob(x))

# make distance vs time plot
dataPlotDist = map(data2$dataSegDist, function(a){
  
  ggplot(a)+
    geom_path(aes(time,distance))+
    geom_point(aes(time,distance, col = factor(state_ordered)))+
    scale_colour_manual(values = pals::kovesi.rainbow(max(a$state_ordered)))+
    theme(legend.position = "bottom", legend.direction = "horizontal")+
    labs(colour = "segment",
         title = first(a$bird), caption = Sys.time())+
    coord_cartesian(ylim=c(0, 25))
  
}) %>% map(function(x) ggplotGrob(x))


# make side by side
library(gridExtra)
plotCombine = pmap(list(plotsSegResTime, plotsSegDist,
                   dataPlotRes, dataPlotDist), function(a,b,c,d){
  arrangeGrob(grobs = list(a,b,c,d), ncol = 2)
})
plot(plotCombine[[2]])

# plot as pdf
pdf(file = "../figs/figCompareSegclsutvars.pdf", width = 12, height = 8)
for(i in 1:length(plotCombine)){
  plot(plotCombine[[i]])
}
dev.off()
