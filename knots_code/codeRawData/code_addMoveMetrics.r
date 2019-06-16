#### code add metrics ####

# read in all birds and select some tidal cycles
library(tidyverse); library(data.table)
library(glue)
library(fasttime) # fast date-time operations

# select tides
selected_tides <- c(seq(5, 100, 15))

# filter out 24 hours after release
# read in release time
releaseData <- fread("../data2018/behavScores.csv", )[,timeNumRelease := as.numeric(fastPOSIXct(Release_Date))]

dataSubset <- map(dataFiles, function(df){
  tempdf <- read_csv(df) %>% setDT() # use readcsv rather than fread
  newNames <- str_to_lower(names(tempdf))
  setnames(tempdf, newNames)
  
  tempdf <- tempdf[tidalcycle %in% c(selected_tides),
                   ][,id:=(tag - 3.1001e10)]
  
  relTime <- merge(releaseData, tempdf, by = "id", all = FALSE, no.dups = T)$timeNumRelease
  # filter data 24 hours post release time  
  tempdf <- tempdf[time >= (relTime + 24 * 3600),]
  
  rm(relTime)
  
  return(tempdf)
})

# bind and write to file
fwrite(bind_rows(dataSubset), file = "../data2018/oneHertzDataSubset/data2018oneHzSelTides.csv")

# split data and remove dfs with less than 100 obs
dataForSeg <- dataSubset %>% keep(function(x) nrow(x) > 100)

source("codeMoveMetrics/functionEuclideanDistance.r")
# calc distance
dataDist <- map(dataForSeg, function(df){
  
  dist <- funcDistance(df, "x", "y")
  
})

# add distance to reg data frame
dataForSeg <- map2(dataForSeg, dataDist, function(z,w){
  mutate(z, dist = w)
})

# make dir for segmentation output
if(!dir.exists("../data2018/oneHertzDataSubset/recursePrep")){
  dir.create("../data2018/oneHertzDataSubset/recursePrep")
}

# split by id and tidal cycle
dataForSeg <- map(dataForSeg, function(x){
  group_by(x, tidalcycle, id) %>% nest()
}) %>% bind_rows()

# paste id and tide for easy extraction, pad tide number to 3 digits
library(glue)
pmap(list(dataForSeg$id, dataForSeg$tidalcycle, dataForSeg$data), function(a, b, c) {
  
  fwrite(mutate(c, id = a, tidalcycle = b), 
         file = glue("../data2018/oneHertzDataSubset/recursePrep/", a,
                     "_", str_pad(b, 3, pad = "0")))
})

# remove previous data
rm(tempdf, dataForSeg, releaseData); gc()



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