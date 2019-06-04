#### code for polygons around residence patches ####

library(tidyverse); library(data.table)

# read in recurse data for selected birds
dataRevFiles <- list.files("../data2018/selRawData/recurseData/", full.names = T)
# read in the data
data <- purrr::map(dataRevFiles[1:5], fread)

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

# get time to high tide
dataHt <- fread("../data2018/selRawData/rawdataWithTides.csv")

data <- map(data, function(df){
  merge(df, dataHt, all=FALSE)
})

# clear main data
rm(dataHt); gc()

# make residence patches
library(sf)

# error dataframes
dfErrors <- list()

# source distance function
source("codeMoveMetrics/functionEuclideanDistance.r")

#### function for resPatches arranged by time ####
funcGetResPatches <- function(df){
  
  # assert df is a data frame
  
  # try function and ignore errors for now
  tryCatch(
    { 
      # convert to sf
      pts = df %>% 
        # make sd
        st_as_sf(coords = c("x", "y")) %>% 
        # assign crs
        `st_crs<-`(32631)#
      
      # make polygons
      polygons = pts %>% 
        # draw a 50 m buffer (arbitrary choice)
        st_buffer(10.0) %>%
        
        # group_by(resPatch) %>%
        # summarise()
        # # dissolve overlapping polygons into each other
        st_union(by_feature = FALSE) %>%
        # # split the resulting multipolygon into its constituents
        st_cast("POLYGON") %>% 
        st_sf() %>% 
        mutate(patch = 1:nrow(.))
      
      # get which points are covered by which polygon
      dfOverlaps = as_tibble(st_covers(polygons, pts)) %>% 
        rename(patch = row.id, point = col.id)
      
      # get mean time and time to high tide from base data
      # make a new tibble as a left join
      patchMetrics = left_join(dfOverlaps,
                          # with raw data assigned row ids as point id
                          df %>% 
                            mutate(point = 1:nrow(df)) %>% 
                            select(point, x, y, time, timeToHiTide)) %>% 
        # for each polygon or residence patch
        group_by(patch) %>% 
        # summarise the mean:
        # x,y (centroid), numeric time, and time since HT
        summarise_at(vars(x,y,time,timeToHiTide), list(mean = mean,
                                                       start = min,
                                                       end = max)) %>% 
        
        # add area: must be here to avoid mixing areas of polygons
        # as a reordering takes place immediately after
        # area is in metres squared, the map units (this is UTM zone 31N)
        mutate(area = as.numeric(st_area(polygons)),
               # time in hours
               duration = (time_end - time_start) / 3600, 
               # assign a spatial geometry
               geom = polygons$geometry) %>% 
        
        # join to the polygons spatial data
        
        # arrange by time_mean
        arrange(time_mean) %>%
        # reorder the polygons and get distance between each and area
        mutate(patch = 1:nrow(.),
               distance = funcDistance(., "x_mean", "y_mean")) %>% 
        # convert result to sf
        st_sf()
        
      
      # remove data
      rm(pts, polygons, dfOverlaps); gc()
        
      # return the patch data as function output
      return(patchMetrics)
    },
    # null error function, with option to collect data on errors
    error= function(e)
    {
      # print(glue("there was an error in id_tide combination... ",
      #                             unique(z$id), unique(z$tidalCycle)))
      # dfErrors <- append(dfErrors, glue(z$id, "_", z$tidalCycle))
    }
  )
  
}

#### get patch data ####
patchData <- map(data, funcGetResPatches)

# add griend
griend <- st_read("../griend_polygon/griend_polygon.shp")

# plot on map
ggplot(griend)+
  geom_sf()+
  geom_sf(data = patchData[[1]], aes(fill = duration), col = "transparent")
