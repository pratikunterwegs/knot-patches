#### code for segmentation ####

#'load libs
library(readr); library(tidyr); library(dplyr)

#'load data with distances

data = read_csv("../data2018/data2018WithRecurse.csv")

#'split by id-tide
data = plyr::dlply(data, c("id", "tidalCycle"))

#'remove data poor dfs where nrow below 33% of expected positions
data = data[unlist(lapply(data, nrow)) >= 12*60*6*.33]

#### segmentation ####
library(segclust2d)

#'test data
dataTest = data[1:5]

dataSeg = list()
for(i in 1:5){
  x = dataTest[[i]]
  #lmin is 5 minutes, so 5*6 points = 30pts
  #Kmax is set to auto
  dataSeg[[i]] = segmentation(x, lmin = 5, seg.var = c("y", "x"))
}

#'plot to check
plot(dataSeg[[1]])

y = bind_rows(lapply(dataSeg, augment)) %>% 
  rename(bird = id)

#'load griend
library(sf)
griend = st_read("../griend_polygon/griend_polygon.shp")

source("codePlotOptions/ggThemePub.r")
ggplot(griend)+
  geom_sf(fill = "white")+
  scale_colour_manual(values = pals::kovesi.cyclic_mygbm_30_95_c78(22))+
  geom_path(data = y, aes(x, y, col = factor(state_ordered)), size = 3)+
  facet_grid(tidalCycle~bird)
