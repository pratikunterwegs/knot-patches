#### function to get residence patches ####

# use sf
library(tidyverse); library(sf)

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
        summarise_at(vars(x,y,time,timeToHiTide), list(mean = mean)) %>% 
        
        # add area: must be here to avoid mixing areas of polygons
        # as a reordering takes place immediately after
        # area is in metres squared, the map units (this is UTM zone 31N)
        mutate(area = as.numeric(st_area(polygons)), 
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