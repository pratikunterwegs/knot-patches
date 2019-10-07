#### function to get residence patches ####

# Code author Pratik Gupte
# PhD student
# MARM group, GELIFES-RUG, NL
# Contact p.r.gupte@rug.nl

# currently complains about vectorising geometry cols, but seems to work

# use sf
library(tidyverse); library(sf)

funcGetResPatches <- function(df, x = "x", y = "y", time = "time", 
                              tidaltime = "tidaltime",
                              buffsize = 10.0){
  
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
        group_by(id, tidalcycle, resPatch) %>% 
        nest() %>% 
        # make sd
        mutate(sfdata = map(data, function(dff){
          st_as_sf(dff, coords = c("x", "y")) %>%
            # assign crs
            `st_crs<-`(32631)}))#
      
      # make polygons
      pts = pts %>%
        mutate(polygons = map(sfdata, function(dff){
          # draw a 10 m buffer (arbitrary choice)
          st_buffer(dff, buffsize) %>% 
            summarise()})) %>% 
        # remove sf data
        select(-sfdata)
      
      # remove point polygons here, MIN polygon size is 5 points
      pts = pts %>% 
        filter(map_int(data, nrow) > 5)
      
      # cast all to multipolygon and then single polygon
      pts = pts %>% 
        mutate(polygons = map(polygons, function(dff){
          st_cast(dff, "MULTIPOLYGON") %>% 
            st_cast(., "POLYGON") %>% 
            mutate(area = as.numeric(st_area(.))) %>% 
            filter(area > 100*pi) %>% 
            # remove area after filtering
            select(-area)
        }))
      
      # return to summarising residence patch data from points
      patchSummary = pts %>%
        transmute(id = id,
                  tidalcycle = tidalcycle,
                  resPatch = resPatch,
                  summary = map(data, function(df){
                    # arrange by time
                    dff <- arrange(df, time)
                    
                    # get summary of time to determine merging based on temporal proximity
                    dff <- dff %>% 
                      summarise_at(vars(time),
                                   list(start = first))
                    
                    # return this
                    return(dff)
                    
                  })) %>%
        # unnest the data
        unnest() %>% 
        # arrange in order of start time for interpatch distances
        arrange(start) %>%
        # needs ungrouping
        ungroup()
      
      # join summary data with spatial data
      pts = left_join(pts, patchSummary)
      
      # unnest polygons column to get data
      pts = pts %>% 
        unnest(polygons, .drop = FALSE)
      
      # clear garbage
      gc()
      
      # make actual polygons object
      pts = 
        pts %>% 
        st_as_sf(., sf_column_name = "geometry")
      
      # get distance between polygons
      pts = pts %>% 
        mutate(spatdiff = c(Inf, as.numeric(st_distance(x = pts[1:nrow(pts)-1,], 
                                                        y = pts[2:nrow(pts),], 
                                                        by_element = T))),
               timediff = c(Inf, diff(start)))
      
      # identify independent patches
      pts = pts %>%  
        mutate(indePatch = cumsum(timediff > 3600 | spatdiff > 100)) #%>% 
      
      # merge polygons by indepatch and handle the underlying data
      pts = 
        pts %>% 
        `st_crs<-`(32631) %>% 
        group_by(id, tidalcycle, indePatch) %>% 
        summarise(data = list(data)) %>% 
        # get the distinct observations
        mutate(data = map(data, function(dff){
          dff %>% 
            bind_rows() %>% 
            distinct() %>% 
            arrange(time)
        })) 
      
      # get patch summary from underlying data
      pts = 
        pts %>% 
        # add x,y,time summary
        mutate(patchSummary = map(data, function(dff){
          dff %>% 
            arrange(time) %>% 
            summarise_at(vars(x, y, time, tidaltime),
                         list(mean = mean,
                              start = first,
                              end = last))
        })) %>% 
        # add total within patch distance
        mutate(distInPatch = map_dbl(data, function(dff){
          sum(dff$dist)
        }))
      
      # arrange patches by start time and add between patch distance
      pts =
        pts %>% 
        unnest(patchSummary, .drop = TRUE) %>% 
        arrange(time_mean) %>% 
        # add distance between and duration in SECONDS
        mutate(patch = 1:nrow(.),
               distBwPatch = funcDistance(., a = "x_mean", b = "y_mean"),
               duration = time_end - time_start) %>% 
        select(-indePatch)
      
      # drop geometry
      pts = pts %>% st_drop_geometry()
      
      gc();
      
      # plot to check
      # ggplot(pts)+
      #   geom_point(aes(x_mean,y_mean,size = time_end - time_start))+
      #   geom_path(aes(x_mean,y_mean), 
      #             arrow = arrow(angle = 10, type = "closed"),
      #             col = 2)
      
      # return the patch data as function output
      print(glue('residence patches of {unique(df$id)} in tide {unique(df$tidalcycle)} constructed...'))
      return(pts)
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
