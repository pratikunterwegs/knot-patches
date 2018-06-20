
#### data for array based pairwise distances

source("libs.R")
load("birds.all.rdata")

k2 = birds.all %>% filter(batch == "knots02")

#'set the time to group by in seconds
sample_interval = 60

#filter the first three days and round to 2 seconds
k2.1 = k2 %>% mutate(day = julian(ts, origin = min(ts))) %>% filter(day < 3) %>% mutate(time_round = round_any(TIME/1e3, sample_interval))

#'round data to 2s
k2.2 = k2.1 %>% melt(id.vars = c("time_round","id"), measure.vars = c("X","Y")) %>% group_by(id, time_round, variable) %>% summarise(mean = mean(value, na.rm = T)) %>% dcast(id + time_round ~ variable, mean)

#'convert to geographic coordinates for the geosphere package
library(sf)
k2.2sf = st_as_sf(k2.2, coords = c("X","Y")); st_crs(k2.2sf) = 32631
k2.2sfgeo = st_transform(k2.2sf, 4326)
k2.2sfgeo = k2.2sfgeo %>% mutate(X = st_coordinates(k2.2sfgeo)[,1], Y = st_coordinates(k2.2sfgeo)[,2])

k2.2 = st_set_geometry(k2.2sfgeo, NULL)

#'create a sequence of tiemstamps from min TIME to max TIME, in increments of 1000, or divide by 1e3 and have increments of 1s
#'

k2.time = data_frame(time_calc = seq(min(k2.2$time_round), max(k2.2$time_round), sample_interval))
#'make df again by removing geometry

#'split into lsit, and then merge each element to the timestamps df.
k2.3 = k2.2 %>% dlply("id") %>% map(function(x) full_join(k2.time, x, by = c("time_calc" = "time_round")))

#'assign id
for (i in 1:length(k2.3)) {
  k2.3[[i]]$id = names(k2.3)[i]  
}

#'select a sample of the dfs, and select only x,y and id
a = k2.3 #%>% filter(id %in% c("151", "157","231"))
a = a %>% map(function(x)x %>% select(id,X,Y))

#'convert to matrix
a = a %>% map(function(x) x %>% mutate(id = NULL)) %>% map(as.matrix)

#'bind the matrices into an array along the third dimension
b = abind::abind(a[c(1:3)], along = 3)

#'create an empty holding array of the same dimensions as the bound array
d = array(dim = dim(b))

#'now run the spdists functions through a for loop
#'load libs
library(geosphere)

#for (i in 1:3) {
  x = a[!names(a) %in% names(a)[i]]
  for(j in 1:length(x)){
    d[,j,i] = distVincentyEllipsoid(p1 = a[[i]], p2 = x[[j]])
  }
}

#t(apply(d, c(3,1), mean))