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
          
          # get summary of time to determine merging based on temporal proximity
          dff <- dff %>% summarise_at(vars(x,y,time),
                                      list(mean = mean,
                                           start = min,
                                           end = max))
          return(dff)
          
        })) %>%
        # unnest the data
        unnest() %>%
        # arrange in order of time for interpatch distances
        arrange(resPatch) %>%
        # needs ungrouping
        ungroup() %>% 
        
        # get bw patch distance and assess patch independence
        
        mutate(spatDist = funcDistance(., a = "x_mean", b = "y_mean"),
               # 1 hour temp indep
               tempIndep = c(T, as.numeric(diff(time_mean)) >= 3600),
               indePatch = cumsum(spatDist > 100 | tempIndep))
      
      # join summary data with polygons using a right join
      polygons = right_join(polygons, patchSummary)
      
      # cast polygons to MULTIPOLYGONS and then POLYGONS
      # this order matters per https://github.com/r-spatial/sf/issues/763
      
      polygons = st_cast(polygons, "MULTIPOLYGON") %>% st_cast("POLYGON") %>% 
        # remove single point data; these have an area of approx pi*100 (10 ^ 2) from pi*(r^2)
        filter(as.numeric(st_area(.)) > (pi*(10^2)))
        
      
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
