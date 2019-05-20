#### code to kmeans cluster points ####

# this code is experimental and doesn't fully work
# without errors

# clean env
rm(list = ls()); gc()

#### load libs ####
library(tidyverse); library(readr)
rm(list = ls()); gc()

# load position data with residence times
data = read_csv("../data2018/data2018WithRecurse.csv") %>% 
  select(id, tidalCycle, x, y, timeNum, residenceTime)

# split by id and tide
dataNest = group_by(data, id, tidalCycle) %>% 
  nest()

# remove data
rm(data); gc()

# run Kmeans residence time
approxTimeBwSegs = 60*30 # in seconds, 10 mins

# write kmeans function for data
# choose centres  = duration in minutes / 10
funcSegment = function(x){
  # kmeans reqs a matrix or coercable object such as a df
  assertthat::assert_that(is.data.frame(x), msg = "x is not a df!")
  nAssumedPatches = floor((max(x$timeNum) - min(x$timeNum))/approxTimeBwSegs)
  x1 = kmeans(x[,c("x", "y", "timeNum")], centers = nAssumedPatches)
  return(x1[["cluster"]])
}

# run across the list of dfs
dataNest = mutate(dataNest, 
                  data = map(data, function(df){
                    mutate(df, segment = funcSegment(df))
                  }))

# write data to file
data = dataNest %>% unnest()
write_csv(data, "../data2018/data2018Segments.csv")

#### plot segments ####
# random 25 id~tide combos
dataSubset = sample_n(dataNest, 25) %>% 
  unnest() %>% 
  mutate(bird = id) %>% 
  group_by(bird, tidalCycle) %>% nest()
  

# read in griend
library(sf)
griend = st_read("../griend_polygon/griend_polygon.shp")

# make list plot
listPlots = map(dataSubset$data, function(z){
  ggplot(griend)+
    geom_sf(col = 2)+
    geom_point(data = z, 
               aes(x, y, col = factor(segment)), size = 0.5)+
    geom_path(data = z, aes(x, y, col = factor(segment)), size = 0.1)+
    #scale_fill_manual(values = pals::kovesi.rainbow(length(unique(z$segment))))+
    scale_colour_manual(values = pals::kovesi.rainbow(length(unique(z$segment))))+
    #coord_sf(datum = NA)+
    theme_bw()
})

# export plots
# export to single pdf
pdf(file = "../figs/figResPatchesMap.pdf", width = 297/25.4, height = 210/25.4)
for (i in 1:25) {
  print(listPlots[[i]]+
          labs(title = paste(dataSubset$bird[i],
                                  dataSubset$tidalCycle[i], sep = " ")))
}
dev.off()

# residence vs time plot
ggplot(dataSubset %>% unnest())+
  # geom_ribbon(aes(x = 1:length(residenceTime), ymin = min(residenceTime),
  #                 ymax = max(residenceTime), fill = factor(segment)),
  #             alpha = 0.2)+
  
  #  geom_line(aes(x = 1:length(residenceTime), y = residenceTime), size = 0.1)+
  geom_point(aes(x = 1:length(residenceTime), y = residenceTime, col = factor(segment)), size = 0.1)+
  geom_line(aes(x = 1:length(residenceTime), y = residenceTime, col = factor(segment)), size = 0.1)+
  scale_colour_manual(values = pals::kovesi.rainbow(26))+
  facet_wrap(~bird+tidalCycle, scales = "free_x")+
  theme_bw()+theme(legend.position = "none")

ggsave("../figs/figResPatchesResTimeVsTime.pdf", device = pdf(), 
       width = 350, height = 350, units = "mm"); dev.off()
