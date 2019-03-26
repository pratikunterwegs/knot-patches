#### code to make shapefiles ####

#'load libs
library(tidyverse); library(readr)

data = read_csv("../data2018/data2018posWithTides.csv")

#### movement distance per tidal cycle ####
#'nest by id and tidal cycle
dataSf = group_by(data, id, tidalCycle) %>% 
  nest() %>% 
  mutate(data = map(data, function(x){
    st_as_sf(x, coords = c("x", "y")) %>% 
      `st_crs<-`(32631)
  }))

#'map a distance function across the list
tidalMovement = map(dataSf$data, function(x){
  c(NA, as.numeric(st_distance(x[1:(nrow(x)-1),], x[2:nrow(x),], 
                               by_element = T)))
  })

#'save as rdata
save(tidalMovement, file = "tidalMovement2018.rdata")

#'make numeric
tidalMovement = map(tidalMovement, as.numeric)
#'add NA to each vector
#tidalMovement = map(tidalMovement, function(x) c(NA, x))

#### merge movement data and id data ####
#'nest by id and tidal cycle, remove datasf
rm(dataSf); gc()
dataNest = group_by(data, id, tidalCycle) %>% 
  nest()

#'check how many positions and distances
a = tibble(nData = map(dataNest$data, nrow), 
           nDists = map(tidalMovement, length)) %>% 
  unnest()

#'count how many mismatches
count(a, nData != nDists)

#'check which these are
a = a %>% cbind(dataNest %>% select(id, tidalCycle))

#View(a)
#'NB: id-tidal cycle combinations which don't have equal numbers
#'of positions and distances are those where the number of data are
#'1 and the distances are for some reason 3
#'
#'filter these out before joining

dataNest = dataNest %>% 
  mutate(distance = tidalMovement) %>% 
  left_join(a) %>% 
  filter(nData == nDists)

#'then unnest data
dataNest = unnest(dataNest)

#'write id, tidalCycle and distances to data
write_csv(dataNest %>% select(id, tidalCycle, timeNum, distance),
          path = "data2018withDistances.csv")
