#### code for polygons around residence patches ####

library(tidyverse); library(data.table)

# read in recurse data for selected birds
dataRevFiles <- list.files("../data2018/oneHertzData/recurseData/", full.names = T)
# read in the data
data <- purrr::map(dataRevFiles[1], fread) %>% 
  keep(function(x) { nrow(x) > 0})

# get id.tide names
library(glue)
names <- purrr::map_chr(data, 
                        function(x){ glue(unique(x$id), 
                                          stringr::str_pad(unique(x$tidalcycle), 3, pad = 0),
                                          .sep = ".") })
# assign names
names(data) <- names

# prep to assign sequence to res patches
# to each id.tide combination
data <- purrr::map(data, function(df) {
  # remove NA vals in fpt
  # set residence time to 0 or 1 predicated on <= 10 (mins)
  df[!is.na(fpt),][,resTime:= ifelse(resTime <= 2, F, T)
                   # get breakpoints where F changes to T and vice versa
                   ][,resPatch:= c(as.numeric(resTime[1]),
                                   diff(resTime))
                     # keeping fixes where restime > 10
                     ][resTime == T,
                       # assign res patch as change from F to T
                       ][,resPatch:= cumsum(resPatch)]
}) %>% 
  keep(function(x) nrow(x) > 2)

# get time to high tide from written data
dataHt <- list.files("../data2018/oneHertzData/recursePrep/", full.names = T)[1] %>% 
  map(fread) %>% bind_rows() %>% select(time, id, x, y, tidaltime, dist, tidalcycle)

# merge to recurse data
data <- map(data, function(df){
  df <- merge(df, dataHt, all = FALSE)
  return(df)
})

# clear main data
rm(dataHt); gc()

# get names
names <- names(data)

# make residence patches
library(sf)

# error dataframes
dfErrors <- list()

# source distance function
source("codeMoveMetrics/functionEuclideanDistance.r")

#### function for resPatches arranged by time ####
source("codeRawData/func_residencePatch.r")

#### get patch data ####
patchData <- map(data, funcGetResPatches)

# assign names
names(patchData) <- names

# filter non-sf results
patchData <- keep(patchData, function(x){
  sum(c("tbl", "data.frame") %in% class(x)) > 0
})

# save
save(patchData, file = "tempPatchData.rdata")

#### process patches as spatials ####
# get ids and tides
birds <- as.list(substr(names(patchData), 1, 3))
tides <- as.list(substr(names(patchData), 5, 7))

# # assign id tide to patches
# patchData <- pmap(list(patchData, birds, tides), function(df, a, b){
#   mutate(df, bird = a, tidalCycle = b)
# })

# turn into multipolygon
# patchData2 <- sf::st_as_sf(data.table::rbindlist(patchData))
# 
# # save as json to maintain single file
# st_write(patchData2, dsn = "../data2018/oneHertzData/patches",
#          driver = "ESRI Shapefile", layer = "patches", delete_layer = TRUE)
# 
# # try getting plots
# # read in griend
# griend <- st_read("../griend_polygon/griend_polygon.shp")
# ggplot()+
#   geom_sf(data = griend)+
#   geom_sf(data = patchData2, aes(fill = as.POSIXct(time_mean, origin = "1970-01-01")))+
#   geom_path(data = patchData2, aes(x_mean, y_mean))
# 
# ggsave("figPatchExample.pdf", width = 10, height = 8, device = pdf()); dev.off()

# # hsitogram
# ggplot(patchData2)+
#   geom_histogram(aes(area, fill = factor(bird)), position = "identity")+
#   xlim(0, 2e4)+
#   #facet_wrap(~bird, ncol = 5)+
#   # scale_y_log10()+
#   # scale_color_viridis_c()+
#   labs(x = "patch area (m^2)", title = "patch area distribution",
#        caption = Sys.time(), fill = "bird")+
#   theme(legend.position = "none")
# 
# ggsave("../figs/figPatchSizeDistribution.pdf", width = 10, height =4, device = pdf()); dev.off()

