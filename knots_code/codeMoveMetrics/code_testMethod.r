#### code to diagnose methods ####

# load libs and data
library(data.table); library(tidyverse)
library(glue); library(sf)

# source distance function
source("codeMoveMetrics/functionEuclideanDistance.r")

# function for resPatches arranged by time
source("codeMoveMetrics/func_residencePatch.r")

# read in recurse data for selected birds
dataRevFiles <- list.files("../data2018/oneHertzData/recurseData/", full.names = T)[1:5]

# get time to high tide from written data
dataHtFiles <- list.files("../data2018/oneHertzData/recursePrep/", full.names = T)[1:5]

# make dataframe of assumption parameters
resTimeLimit = c(2, 4, 10); travelSeg = c(5)
assumpData <- crossing(resTimeLimit, travelSeg)

# make data - param assump combo df
dataToTest <- tibble(revdata = dataRevFiles, htData = dataHtFiles, assump = list(assumpData)) %>% 
  unnest(cols = assump)

#### testing the patches produced by different assumptions ####

# passing data to a function that manually segments and returns patches
data <- purrr::pmap(dataToTest, function(revdata, htData, resTimeLimit, travelSeg){
  
  # print param assumpts
  print(glue('param assumpts...\n residence time threshold = {resTimeLimit}\n travel segment smoothing = {travelSeg}'))
  
  # read the file in
  {df <- fread(revdata)
    dataHt <- fread(htData)
    # merge to recurse data
    df <- merge(df, dataHt, all = FALSE)
    print(glue('individual {unique(df$id)} in tide {unique(df$tidalcycle)} has {nrow(df)} obs'))
  }
  
  ## SET THE DF IN ORDER OF TIME ##
  setorder(df,time)
  
  # prep to assign sequence to res patches
  # to each id.tide combination
  # remove NA vals in fpt
  # set residence time to 0 or 1 predicated on <= 10 (mins)
  df <- df[!is.na(fpt) #& between(tidaltime, 4*60, 9*60),
           ][,resTimeBool:= ifelse(resTime <= resTimeLimit, F, T)
             # get breakpoints if the mean over rows of length travelSeg
             # is below 0.5
             # how does this work?
             # a sequence of comparisons, resTime <= resTimeLimit
             # may be thus: c(T,T,T,F,F,T,T)
             # indicating two non-residence points between 3 and 2 residence points
             # the rolling mean over a window of length 3 will be
             # c(1,.67,.33,.33,.33,.67) which can be used to
             # smooth over false negatives of residence
             ][,rollResTime:=(zoo::rollmean(resTimeBool, k = travelSeg, fill = NA) > 0.5)
               # drop NAs in rolling residence time evaluation
               # essentially the first and last elements will be dropped
               ][!is.na(rollResTime),
                 ][,resPatch:= c(as.numeric(resTimeBool[1]),
                                 diff(resTimeBool))
                   # keeping fixes where restime > 10
                   ][resTimeBool == T,
                     # assign res patch as change from F to T
                     ][,resPatch:= cumsum(resPatch)]

  
  # add param assumptions
  df$resTimeLimit = resTimeLimit; df$travelSeg = travelSeg
  
  return(df)
  
})

#### separate funciton to return res patches ####
funcReturnPatchData <- function(segData){
  # get patch data
  patchData <- funcGetResPatches(segData)
  
  # remove what seems to be the sf data
  patchData <- patchData # %>% dplyr::select(-data)
  
  # add the parameter assumptions
  patchData$resTimeLimit = segData$resTimeLimit[1]
  patchData$travelSeg = segData$travelSeg[1]
  
  return(patchData)
}

# get patches
patches <- map(data, funcReturnPatchData)

# prep plot data
plotdata = patches %>% bind_rows()
#### diagnostic plots for respatches ####
{
  x11()
  {
    ggplot()+
      geom_point(data = bind_rows(data) %>% filter(tidalcycle %in% c(7,8,9)),
                 aes(x,y, col = resTime), alpha = 0.7, size = 0.5)+
      
      
      geom_point(data = plotdata %>% filter(tidalcycle %in% c(7,8,9)),
                 aes(X_mean, Y_mean, size = duration/60), 
                 pch = 1, col = 1, alpha = 1)+
      
      geom_path(data = plotdata %>% filter(tidalcycle %in% c(7,8,9)),
                aes(X_mean, Y_mean), 
                #size =2, 
                col = "red",
                arrow = arrow(type = "closed", angle = 7))+
      
      geom_segment(data = bind_rows(data) %>% filter(tidalcycle %in% c(7,8,9)),
                   aes(x = min(x),
                       xend = min(x) + 100,
                       y = min(y),
                       yend = min(y)),
                   col = "grey", size = 2)+

      scale_color_distiller(palette = "Blues", direction = 1,
                            limits = c(0,NA))+
      
      scale_size(range = c(0, 10))+
      
      # scale_fill_distiller(palette = "Greys", direction = 1,
      #                      breaks = c(4e3, 10e3, 16e3))+
      theme_bw()+
      facet_grid(resTimeLimit~tidalcycle, labeller = label_both,
                 scales = "free")+
      labs(#col = "residence time (mins)",
           x = "long.", y = "lat.",
           size = "time in patch (mins)",
           title = "individual 435, tidalcycle = 8 - 10, low tide (7-9)",
           subtitle = "grey bar = 100 m")+
      theme(axis.text = element_blank(),
            panel.grid = element_blank(),
            legend.position = "top")
  }
  ggsave(filename = "../figs/fig_newPatches_testSegments_435_8to10.png",
         device = png(),
         dpi = 300,
         height = 12, width = 12)
  dev.off()
}