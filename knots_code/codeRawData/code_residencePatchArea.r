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

# error dataframes
dfErrors = list()

dataPatches <- map(data, function(df){
  tryCatch(
  # group by patch
  {group_by(df, resPatch) %>% 
    # make sd
    st_as_sf(coords = c("x", "y")) %>% 
    # assign crs
    `st_crs<-`(32631) %>% 
    # draw a 50 m buffer (arbitrary choice)
    st_buffer(50) %>% 
    # dissolve overlapping polygons into each other 
    st_union() %>% 
    # split the resulting multipolygon into its constituents
    st_cast("POLYGON")},
  error= function(e){print(glue("there was an error in id_tide combination... ",
                                unique(z$id), unique(z$tidalCycle)))
    dfErrors <- append(dfErrors, glue(z$id, "_", z$tidalCycle))
    }
  )
})

# remove all dataPatches which are not sfc objects
dataPatches <- dataPatches[!is.na(str_match(map_chr(dataPatches, function(x) class(x)[1]), "sfc"))]
# remove dataPatches where there are 2 polygons or fewer: 268 remain
dataPatches <- dataPatches[map_dbl(dataPatches, length) > 2]

# get distance between one patch and the next
distancePatches <- map(dataPatches, function(z){
  as.numeric(st_distance(z[1:length(z) - 1],
                         z[2:length(z)], by_element = TRUE))
})

# patch areas
areaPatches <- map(dataPatches, function(z){ as.numeric(st_area(z))})

# save as rdata
save(areaPatches, distancePatches, dataPatches, file = "tempResPatches.rdata")
