#### function to get residence patches ####

# Code author Pratik Gupte
# PhD student
# MARM group, GELIFES-RUG, NL
# Contact p.r.gupte@rug.nl

# currently complains about vectorising geometry cols, but seems to work

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
        # this unions the smaller buffers
        summarise()
      
      # remove the pts sf obj
      rm(pts); gc()
      # convert the complex sf object to a simpler sfc column
      # this function, st_sfc, produces warnings. ignore them
      # polygons$data = reduce(polygons$data, c) %>% st_sfc()
      
      # get patch area in m^2
      # polygons = mutate(polygons, area = as.numeric(st_area(polygons)))
      
      # return to summarising residence patches
      patchSummary = df %>%
        group_by(id, tidalcycle, resPatch) %>%
        nest() %>%
        
        # filter if too few points in patch
        # THIS IS AN ARBITRARY CHOICE
        filter(map_int(data, nrow) >= 3) %>% 
        
        mutate(data = map(data, function(df){
          # arrange by time
          dff <- arrange(df, time)
          # get distance inside patch if n positions are greater than 1, else return 0
          distInPatch <- funcDistance(dff)
          # mutate(distInPatch =
          #          ifelse(nrow(df) < 2, NA, funcDistance(df))) %>%
          # get summary of other covariates
          dff <- dff %>% summarise_at(vars(x,y,time,tidaltime),
                                      list(mean = mean,
                                           start = first,
                                           end = last)) %>%
            # get duration inside patch and sum of distances
            mutate(duration = time_end - time_start,
                   nFixes = nrow(dff),
                   distInPatch = sum(distInPatch, na.rm = TRUE)) %>%
            mutate_at(vars(time_mean), list(round))
          
          return(dff)
          
        })) %>%
        # unnest
        unnest() %>%
        # arrange in order of time for interpatch distances
        arrange(resPatch) %>%
        mutate(distBwPatch = funcDistance(., a = "x_mean", b = "y_mean"))
      
      # join summary data with polygons
      # the order matters for the class of the resulting object! use an inner join
      patchSummary = inner_join(patchSummary, polygons)
      
      # return the patch data as function output
      print(glue('residence patches of {unique(df$id)} in tide {unique(df$tidalcycle)} constructed...'))
      return(patchSummary)
    },
    # null error function, with option to collect data on errors
    error= function(e)
    {
      print(glue('\nthere was an error in id_tide combination...
                                  {unique(df$id)} {unique(df$tidalcycle)}\n'))
      # dfErrors <- append(dfErrors, glue(z$id, "_", z$tidalCycle))
    }
  )
  
}
