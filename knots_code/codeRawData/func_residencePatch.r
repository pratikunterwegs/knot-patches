#### function to get residence patches ####

# currently complains about unknown columns, but seems to work

# use sf
library(tidyverse); library(sf)

funcGetResPatches <- function(df, x = "x", y = "y", time = "time", tidaltime = "tidaltime"){
  
  # assert df is a data frame
  assertthat::assert_that(is.data.frame(df),
                          is.character(c(x,y,time,tidaltime)), # check that args are strings
                          is.numeric(c(df$time, df$tidaltime)), # check times are numerics
                          msg = "argument classes don't match expected arg classes")
  
  assertthat::assert_that(length(base::intersect(c(x,y,time,tidaltime), names(df))) == 4,
                          msg = "wrong column names provided, or df has wrong cols")
  
  # try function and ignore errors for now
  tryCatch(
    { 
      # convert to sf points object
      pts = df %>% 
        # make sd
        st_as_sf(coords = c("x", "y")) %>% 
        # assign crs
        `st_crs<-`(32631)#
      
      # make polygons
      polygons = pts %>% 
        # draw a 10 m buffer (arbitrary choice)
        st_buffer(10.0) %>%
        
        group_by(resPatch) %>% 
        # make lsit column of sf objects
        nest() %>% 
        # union the buffers within each res patch, but not between patches
        mutate(data = map(data, function(z) {
          st_union(z)
        }))
      
      # remove the pts sf obj
      rm(pts); gc()
            # convert the complex sf object to a simpler sfc column
      polygons$data = reduce(polygons$data, c) %>% st_sfc()
      
      # don't do this, the resulting object is too large for 7000 uses
      # make polygons a full sf object
      #polygons = st_sf(polygons)
      
      # get patch area in m^2
      polygons = mutate(polygons, area = as.numeric(st_area(data)))
      
      # return to summarising residence patches
      patchSummary = df %>%  
        group_by(id, tidalcycle, resPatch) %>% 
        nest() %>% 
        mutate(data = map(data, function(df){
          # arrange by time
          arrange(df, time) %>% 
          # get distance inside patch
          mutate(distInPatch = funcDistance(.)) %>%
            # get summary of other covariates
          summarise_at(vars(x,y,time,tidaltime),
                       list(mean = mean,
                            start = first,
                            end = last)) %>% 
            # get duration inside patch and sum of distances
            mutate(duration = time_end - time_start,
                 distInPatch = sum(funcDistance(df), na.rm = T)) %>% 
            mutate_at(vars(time_mean), list(round))
          
        })) %>% 
        # unnest
        unnest() %>%
        # arrange in order of time for interpatch distances
        arrange(resPatch) %>% 
        mutate(distBwPatch = funcDistance(., a = "x_mean", b = "y_mean"))
      
      # join summary data with polygons
      # the order matters for the class of the resulting object!
      patchSummary = left_join(patchSummary, polygons)
      
      # return the patch data as function output
      print(glue('residence patches of {unique(df$id)} in tide {unique(df$tidalcycle)} constructed...'))
      return(patchSummary)
      rm(polygons); gc()
    },
    # null error function, with option to collect data on errors
    error= function(e)
    {
      print(glue('there was an error in id_tide combination... 
                                  {unique(df$id)} {unique(df$tidalcycle)}'))
      # dfErrors <- append(dfErrors, glue(z$id, "_", z$tidalCycle))
    }
  )
  
}