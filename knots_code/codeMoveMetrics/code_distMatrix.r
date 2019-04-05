#### distance matrices ####
#'code to get pairwise distance matrix
#'the number of pairwise matrices is n*(n-1)/2
#'or 9316 for 137 birds
#'

#### load data ####
#'load libs
library(tidyverse); library(readr)

data = read_csv("../data2018/data2018posWithTides.csv")

#'remove bad cols
data = select(data, id, x, y, timeNum); gc()

#'nest by id
dataNest = group_by(data, id) %>% nest()

#'now create uniform records, ie, fill missing positions with NA
timeNumSeq = tibble(timeNum = seq(min(data$timeNum), max(data$timeNum), 10))

#'merge with each nested df
dataNest = mutate(dataNest, data = map(data, function(x){
  full_join(timeNumSeq, x)
}))

#'set the missing x and y values to 0, and the id to
#'the unique non-NA value
dataNest$data = map(dataNest$data, function(z){
  mutate(z, x = ifelse(is.na(x), 9e6, x),
         y = ifelse(is.na(y), 9e6, y))
})

dataNest = unnest(dataNest) %>% 
  plyr::dlply("id")
#### calculate distances ####

z = tibble()

#'write distance function
dist2bird = function(z, w){
  dist = sqrt((z$x - w$x)^2 + (z$y - w$y)^2)
  return(dist)
}

#'prep empty list
z = vector("list", length(dataNest)) %>% 
  map(function(x){vector("list", length(dataNest))})

rm(data); gc()
dataNest2 = dataNest

dataNest = dataNest2
#'run loop
for(i in 1:length(dataNest)){
  
  for(j in 1:length(dataNest)){
    z[[i]][[j]] = tibble(focal = dataNest[[i]]$id,
                         nonfocal = dataNest[[j]]$id,
                         focalX = dataNest[[i]]$x,
                         nonfocalX = dataNest[[j]]$x,
                         timeNum = dataNest[[i]]$timeNum,
                         distance = 
      dist2bird(dataNest[[i]], dataNest[[j]])) %>% 
      filter(focalX < 9e6, nonfocalX < 9e6,
             focal != nonfocal)
  }
  z[[i]] = z[[i]] %>% keep(function(x) nrow(x) > 1)
  
}

#'bind rows with names
names(z) = names(dataNest)
#'bind rows within ids
distData = map(z, function(x) bind_rows(x))
#'bind across data
rm(z); gc()
rm(dataNest); gc()


#### write to individual files ####
for(i in 1:length(distData)){
  write_csv(distData[[i]],
            path = paste("../data2018/distMatrix/id",
                         unique(distData[[i]]$focal),
                         ".csv", sep = ""))
}

rm(distData); gc()
