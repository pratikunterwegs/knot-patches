#### code for Griend departure ####

# load libs
library(tidyverse); library(readr)

# load data with tidal cycles
data = read_csv("../data2018/data2018posWithTides.csv")

#### last date of tracking ####
lastTrackDay = data %>% 
  group_by(id) %>% 
  summarise(firstDay = min(time),
    lastDay = max(time),
            trackDur = as.numeric(difftime(max(time), min(time), units = "days")),
            residenceDur = as.numeric(difftime(max(time), min(data$time), units = "days")))

# write to csv
write_csv(lastTrackDay, path = "../data2018/lastTrackDay2018.csv")


#### time to first 'Griend departure' ####
# here, we construct an arbitrary circle of radius 5km
# from griend and ask how long it was before the knots left.

# load the sf package
library(sf)

# read in griend polygon
griend = st_read("../griend_polygon/griend_polygon.shp")
# make a 5km buffer around the centroid
griendBuffer = st_buffer(st_centroid(griend), dist = 5e3)

# make data an sf object
dtaSf = st_as_sf(data, coords = c("x", "y")) %>% 
  `st_crs<-`(32631)

# find the difference of dataSf and the buffer polygon
dataSfBufferDiff = st_difference(dtaSf, griendBuffer)
# remove dataSf
rm(dtaSf); gc()

#### investigate first point outside griendBuffer ####
# convert to df drop geometry
dataExGriend = st_drop_geometry(dataSfBufferDiff)
dataExGriend = as.data.frame(dataExGriend) %>% 
  group_by(id) %>% 
  summarise(firstDayExGriend = min(time))

# add data for first day out of griend
lastTrackDay = lastTrackDay %>% 
  left_join(dataExGriend, by = "id") %>% 
  mutate(timeExGriend5km = as.numeric(difftime(firstDayExGriend, firstDay, units = "days")))

# save last day stats to file
# write to csv
write_csv(lastTrackDay, path = "../data2018/lastTrackDay2018.csv")


#### distance to griend per tide ####
# remove dataSfBuffer
rm(dataSfBufferDiff)

# make data sf
dataSf = st_as_sf(data, coords = c("x", "y")) %>% 
  `st_crs<-`(32631)

# set griend centroid
griend = griend %>% `st_crs<-`(32631)

# get distance to griend centroid
dataDistGriend = st_distance(dataSf, st_centroid(griend))

# add to positions
data$distGriend = as.numeric(dataDistGriend)
# remove data
rm(dataSf, dataDistGriend); gc()

# get min max distance per id per tide from griend
distGriendId = data %>% 
  group_by(id, tidalCycle) %>% 
  summarise(minDistGriend = min(distGriend),
            maxDistGriend = max(distGriend))

# plot
# source plot ops
source("codePlotOptions/ggThemePub.r")
distGriendId %>% 
  gather(var, value, -id, -tidalCycle) %>% 
  ggplot()+
  geom_tile(aes(x = tidalCycle, y = as.factor(id),
                fill = value/1e3))+
  scale_fill_viridis_c(option = "magma",
                      name = "distGriend (km)",
                      limits = c(0, 10),
                      na.value = litBlu)+
  facet_wrap(~var)+
  themePubLeg()+ylab("id")
  
# save to file
ggsave(filename = "../figs/distGriendIdTide.pdf", device = pdf(), width = 210, height = 297, units = "mm", dpi = 300); dev.off()

# write to file
write_csv(distGriendId, path = "../data2018/distGriendId.csv")
