#### code to make shapefiles ####

# load libs
library(tidyverse); library(readr)

data = read_csv("../data2018/data2018posWithTides.csv")

#### movement distance per tidal cycle ####
# split by id and tidalCycle
dataSfLine = plyr::dlply(data, c("id", "tidalCycle"))

# get metadata
namesDf = tibble(names = names(plyr::dlply(data, c("id", "tidalCycle"))), id = substr(names, 1, 3), tidalCycle = as.numeric(substring(names, 5)))

# make an full shapefile of all paths
dataSfLine = map(dataSfLine, function(x){
  cbind(x$x, x$y) %>% 
    st_linestring(dim = "XY")
})

# make sfc and add metadata
dataSfLine = st_sfc(dataSfLine, crs = 32631)

dataSfLine = st_sf(cbind(namesDf, dataSfLine))

# export to shapefile
write_sf(dataSfLine, dsn = "../data2018/spatials", layer = "data2018tracks", driver = "ESRI Shapefile")

#### plot subset ####
test = dataSfLine %>% filter(tidalCycle %in% 1:10)
testPlot = ggplot(test)+
  geom_sf(aes(col = factor(tidalCycle)))+
  coord_sf(datum = NA)+
  facet_wrap(~id)+
  theme_void()

# make plotly map and export for first 10 tidal cycles
# this is of dubious usefulness but who knows
library(plotly)

p = ggplotly(
  ggplot(test)+
    geom_sf(aes(col = factor(tidalCycle)))+
    facet_wrap(~id)
)

library(htmlwidgets)
saveWidget(p, file = "../figs/widgetTracks2018tides01to10.html",
           selfcontained = F)
