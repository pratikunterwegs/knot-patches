#### code to deal with raw data from selected birds ####
# selected birds are

selected_tides <- c(seq(5, 100, 15))

# now try for random birds

# load libs
library(tidyverse); library(data.table)
library(glue)

# list files
dataFiles <- list.files("../data2018/", pattern = "knots2018", full.names = T)

# selected data
selectData <- list()

# make output dir if non existent
if(!dir.exists("../data2018/oneHertzData")){
  dir.create("../data2018/oneHertzData")
}

for(i in 1:length(dataFiles)) {
  load(dataFiles[i])
  
  # prep data to compare
  data <- data2018.raw %>%
    keep(function(x) length(x) > 0) %>% # keep non null lists
    flatten() %>% # flatten this list structure
    keep(function(x) nrow(x) > 0) # keep dfs with data
  
  rm(data2018.raw); gc()
  
  names <- map_chr(data, function(x) as.character(unique(x$TAG - 3.1001e10)))
  
  map2(data, names, function(x, y){
    fwrite(x, file = glue("../data2018/oneHertzData/", y, ".csv"))
  })
  
}


#### assign tidal cycles ####
tides <- fread("../data2018/tidesSummer2018.csv")[tide == "H"]

# read in data and add tidal cycles
dataFiles <- list.files(path = "../data2018/oneHertzData/", full.names = TRUE)

# assign and write
map(dataFiles, function(df){
  tempdf <- read_csv(df) %>% setDT()
  tempdf[,TIME:=floor(TIME/1e3)]
  tempdf <- merge(tempdf, tides, by.x = "TIME", by.y = "timeNum", all = TRUE)
  setorder(tempdf, TIME)
  tempdf <- tempdf[,tide:=!is.na(tide)
         ][, tidalCycle:=cumsum(tide)
           ][,tidalTime:= (TIME - min(TIME))/60,by=tidalCycle
             ][complete.cases(X),]
              
  tempdf[,`:=` (temp = NULL, tide = NULL, level = NULL, time = NULL)
         ][,tidalCycle:=tidalCycle-min(tidalCycle)+1]

  fwrite(tempdf, file = df)
  return("overwritten with tidal cycles")
})

#### read in again and select some tides ####

dataSubset <- map(dataFiles, function(df){
  tempdf <- read_csv(df) %>% setDT()
  tempdf <- tempdf[tidalCycle %in% c(selected_tides),
         ][,ID:=(TAG - 3.1001e10)]
  
  newNames <- str_to_lower(names(tempdf))
  setnames(tempdf, newNames)
  
  return(tempdf) # works wo comma
})

# remove select data
rm(selectData); gc()

# filter out 24 hours after release
# read in release time
releaseData <- read_csv("../data2018/behavScores.csv") %>% 
  mutate(timeNumRelease = as.numeric(Release_Date))

# join to data and keep data where time >= release date + 24 h
dataSubset <- left_join(data, releaseData %>% select(id, timeNumRelease)) %>% 
  filter(time >= timeNumRelease + (24 * 3600)) %>% 
  select(-timeNumRelease)

# bind tides and data on time
data <- split(data, f = data$id) %>% 
  map(function(df){
    full_join(df, tides, by = c("time" = "timeNum")) %>% 
      arrange(time) %>%                                 # arrange by time
      mutate(tide = ifelse(is.na(level), "other", tide),# classify points
             tidalCycle = cumsum(tide == "H")) %>%      # assign tidal cycle
      filter(!is.na(x)) %>%                             # remove non positions
      select(-tide, -level, -time.y)                    # remove tidal data
  }) %>% bind_rows() %>%                                # bind rows
  mutate(tidalCycle = tidalCycle - min(tidalCycle) + 1) %>%
  group_by(id, tidalCycle) %>% 
  mutate(timeToHiTide = (time - min(time)) / 3600)

# split data and remove dfs with less than 100 obs
dataForSeg <- group_by(data, id, tidalCycle) %>%
  group_split() %>% 
  keep(function(x) nrow(x) > 100)

source("codeMoveMetrics/functionEuclideanDistance.r")
# calc distance
dataDist <- map(dataForSeg, function(df){
  funcDistance(df, "x", "y")  
})

# add distance
dataForSeg <- map2(dataForSeg, dataDist, function(z,w){
  mutate(z, dist = w)
})
# bind rows
dataForSeg <- bind_rows(dataForSeg)

# write to file
fwrite(dataForSeg, file = "../data2018/selRawData/rawdataWithTidesDists.csv")

# make dir for segmentation output
if(!dir.exists("../data2018/selRawData/recursePrep")){
  dir.create("../data2018/selRawData/recursePrep")
}

# paste id and tide for easy extraction, padd tide number to 3 digits
library(glue)
for (i in 1:length(dataForSeg)) {
  bird <- unique(dataForSeg[[i]]$id)
  tide <- str_pad(unique(dataForSeg[[i]]$tidalCycle), 3, pad = 0)
  fwrite(dataForSeg[[i]], 
         file = glue("../data2018/selRawData/recursePrep/", bird,
                     "_", tide))
}

# remove previous data
rm(data, dataForSeg, releaseData, tides, waterlevel); gc()

#### segmentation process ####

# list files
dataFiles <- list.files("../data2018/selRawData/recursePrep/", full.names = T)

# create dir for output
if(!dir.exists("../data2018/selRawData/recurseData")){
  dir.create("../data2018/selRawData/recurseData")
}

library(recurse)
for(i in 1:length(dataFiles)){
  
  # read in data
  df <- as.data.frame(fread(dataFiles[i])[,.(x,y,time,id, tidalCycle)])
  
  # assign bird and tidal cycle
  bird <- unique(df$id); tide <- str_pad(unique(df$tidalCycle),3,pad = 0)
  
  # run recurse
  dfRecurse <- getRecursions(x = df[,c("x","y","time","id")], radius = 50, 
                             timeunits = "mins", verbose = TRUE)
  
  # get residence time as sum of first 1 hour
  dfRes <- setDT(dfRecurse[["revisitStats"]]                          # select rev stats
                 )[,cumlTime:=cumsum(timeInside),                     # calc cumulative time
                   by=.(coordIdx,x,y)                                 # for each coordinate
                   ][cumlTime <= 60,                                  # remove times > 60
                     ][,.(resTime = sum(timeInside),                  # calc metrics
                          fpt = first(timeInside),
                          revisits = max(visitIdx)), .(coordIdx,x,y)] # for each coordinate
  
  # join to data, for some reason, data.table converts time to posixct
  # this conversion is both wrong and unwanted
  df <- data.table(df)[dfRes,on=.(x,y)]
  
  # write to file
  fwrite(df, file = glue("../data2018/selRawData/recurseData/recurse", bird,
                         "_", tide), dateTimeAs = "epoch")
  
  rm(df, dfRecurse, dfRes)
  
}

#### segmentation ####
# list files
dataRevFiles <- list.files("../data2018/selRawData/recurseData/", full.names = T)
# read in the data
data <- purrr::map(dataRevFiles, fread)

# get id.tide names
library(glue)
names <- purrr::map_chr(data, function(x){ glue(unique(x$id), 
                                         stringr::str_pad(unique(x$tidalCycle), 3, pad = 0),
                                         .sep = ".") })
names(data) <- names

# subset data, remove 
data <- data[c(1:5)]

# get distance data
dataDist <- fread("../data2018/selRawData/rawdataWithTidesDists.csv")

## prep for segmentation
data <- purrr::map(data, function(df) {
  df[!is.na(fpt),][,resTime:= ifelse(resTime <= 2, 0, 1e2)][,resTime:= resTime + runif(length(resTime), 0, 0.1)]
})

# run segclust on res time
library(segclust2d)
# this works fairly well
dataSeg <- purrr::map(data, function(df){
  segclust(df, seg.var = c("resTime"), lmin = 50, Kmax = 20,
                ncluster = 2, 
                scale.variable = FALSE,
                diag.var = c("resTime"), sameV = TRUE) %>% 
    augment()
})

#### make plot ####
# read in griend
library(ggplot2)
#griend = sf::st_read("../griend_polygon/griend_polygon.shp")
plotlist1 <- map(dataSeg, function(df){
  ggplot(griend)+
  geom_sf()+
  geom_point(data = df,
             aes(x,y, col = resTime > 2),
             size = 0.2, shape = 16)+
  scale_color_brewer(palette = "Set1")+
  theme(legend.position = "bottom")+
  labs(title= glue(unique(df$id), unique(df$tidalCycle), .sep="_"), 
       colour = "residence time > 2 minute",
       subtitle = "manual residence time")
}) %>% map(function(x) ggplotGrob(x))

plotlist2 <- map(dataSeg, function(df){
  ggplot(griend)+
  geom_sf()+
  geom_point(data = df,
             aes(x,y, col = factor(state_ordered)),
             size = 0.2, shape = 16)+
  scale_color_brewer(palette = "Set1")+
  theme(legend.position = "bottom")+
  labs(title = glue(unique(df$id), unique(df$tidalCycle), .sep="_"),
       subtitle="segmented on residence time", 
       colour = "class")
}) %>% map(function(x) ggplotGrob(x))

# plot grid
library(gridExtra)
pdf(file = "../figs/figRawDataSegmentation.pdf", width = 12, height = 8)
for(i in 1:length(plotlist1)){
  grid.arrange(plotlist1[[i]], plotlist2[[i]], ncol = 2)
}
dev.off()
