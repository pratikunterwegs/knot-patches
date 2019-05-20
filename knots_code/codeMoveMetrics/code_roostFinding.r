#### roost on Griend or Richel ####

# env clear
rm(list = ls()); gc()

# read in roost points

library(sf)
roosts = st_read("../data2018/spatials/islandRoostPoints.shp")

# load data with tidal positions, keep high tide positions
data = read_csv("../data2018/data2018posWithTides.csv")
dataHT = filter(data, !between(timeToHiTide, 3*60, 10*60)); rm(data); gc()

# make dataHT sf
dataHT = st_as_sf(dataHT, coords = c("x", "y")) %>%
  `st_crs<-`(32631)

# get distances
dataRoostDist = st_distance(dataHT, roosts)
# get as numeric
dataRoostDist = apply(dataRoostDist, 2, as.numeric) %>%
  as.data.frame() %>%
  `colnames<-`(c("griend", "derichel", "terschelling", "flieland")) %>%
  mutate(id = dataHT$id, timeNum = dataHT$timeNum,
         tidalCycle = dataHT$tidalCycle)

#### proportion per id per tide of roost ####
# use count
dataRoostDist = dataRoostDist %>%
  gather(island, distance, -id, -timeNum, -tidalCycle)

dataRoostDist = dataRoostDist %>%
  group_by(id, timeNum, tidalCycle) %>%
  summarise(roost = island[which.min(distance)])

# get per tide prop
dataRoostProp = ungroup(dataRoostDist) %>%
  count(id, tidalCycle, roost) %>%
  ungroup() %>%
  group_by(id, tidalCycle) %>%
  mutate(roostProp = n/sum(n))

# write to csv
write_csv(dataRoostProp, path = "../data2018/dataRoostProp.csv")

# plot griend prop
source("codePlotOptions/ggThemePub.r")
ggplot(dataRoostProp %>% filter(roost == "griend"))+
  geom_tile(aes(tidalCycle, factor(id), fill = roostProp),
            col = "white", size = 0.1)+
  scale_fill_viridis_c(name = "propGriend",
                       na.value = "grey")+
  themePubLeg()+
  labs(y = "id", title = "Proportion of roost time on Griend",
       caption = Sys.time())+
  theme(axis.text.y = element_text(size = 4))

# save to file
ggsave(filename = "../figs/figureRoostProp.pdf", device = pdf(), width = 210, height = 297, units = "mm", dpi = 300); dev.off()

# remove data and clean garbage
rm(list = ls()); gc()
