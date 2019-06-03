#### code for polygons around residence patches ####

library(tidyverse); library(data.table)

# read in recurse data for selected birds
dataRevFiles <- list.files("../data2018/selRawData/recurseData/", full.names = T)
# read in the data
data <- purrr::map(dataRevFiles, fread)
# get id.tide names
library(glue)
names <- purrr::map_chr(data, 
                        function(x){ glue(unique(x$id), 
                                          stringr::str_pad(unique(x$tidalCycle), 3, pad = 0),
                                          .sep = ".") })
# assign names
names(data) <- names

# prep to assign sequence to res patches
# to each id.tide combination
data <- purrr::map(data, function(df) {
  # remove NA vals in fpt
  # set residence time to 0 or 1 predicated on <= 10 (mins)
  df[!is.na(fpt),][,resTime:= ifelse(resTime <= 10, F, T)
                   # get breakpoints where F chances to T and vice versa
                   ][,resPatch:= c(as.numeric(resTime[1]),
                                   diff(resTime))
                     # keeping fixes where restime > 10
                     ][resTime == T,
                       # assign res patch as change from F to T
                       ][,resPatch:= cumsum(resPatch)]
})

# make residence patches
library(sf)

dataPatches <- map(data[c(1:5)], function(df){
  # group by patch
  group_by(df, resPatch) %>% 
    # make sd
    st_as_sf(coords = c("x", "y")) %>% 
    # assign crs
    `st_crs<-`(32631) %>% 
    # draw a 10 m buffer (arbit choice)
    st_buffer(10) %>% 
    # dissolve overlapping polygons into each other 
    st_union() %>% 
    # split the resulting polygon into its constituents
    st_cast("MULTIPOLYGON")
})

distancePatches

# write to file to check if something can be done in qgis
st_write(df2, dsn = "../data2018/selRawData/patch", layer = "patches.shp", driver = "ESRI Shapefile", delete_layer = TRUE)



