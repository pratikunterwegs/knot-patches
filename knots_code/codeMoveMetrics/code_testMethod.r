#### code to diagnose methods ####

# load libs and data
library(data.table); library(tidyverse)
library(glue); library(sf)

# source distance function
source("codeMoveMetrics/functionEuclideanDistance.r")

# function for resPatches arranged by time
source("codeMakeResults/func_residencePatch.r")

# read in recurse data for selected birds
dataRevFiles <- list.files("../data2018/oneHertzData/recurseData/", full.names = T)[1]

# get time to high tide from written data
dataHtFiles <- list.files("../data2018/oneHertzData/recursePrep/", full.names = T)[1]

# make dataframe of assumption parameters
resTimeLimit = c(2, 4, 10); travelSeg = c(1, 5, 10); travelTime = c(1, 2, 5, 10)
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
  df <- fread(revdata)
  
  print(glue('individual {unique(df$id)} in tide {unique(df$tidalcycle)} has {nrow(df)} obs'))
  
  # prep to assign sequence to res patches
  # to each id.tide combination
  # remove NA vals in fpt
  # set residence time to 0 or 1 predicated on <= 10 (mins)
  df <- df[!is.na(fpt),
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
             ][,rollResTime:=(zoo::rollmean(resTime, k = travelSeg, fill = NA) > 0.5)
               # drop NAs in rolling residence time evaluation
               # essentially the first and last elements will be dropped
               ][!is.na(rollResTime),
                 ][,resPatch:= c(as.numeric(resTime[1]),
                                 diff(resTime))
                   # keeping fixes where restime > 10
                   ][resTime == T,
                     # assign res patch as change from F to T
                     ][,resPatch:= cumsum(resPatch)]
  
  
  dataHt <- fread(htData)
  # merge to recurse data
  df <- merge(df, dataHt, all = FALSE)
  
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
plotdata = patches %>% bind_rows()
#### diagnostic plots for respatches ####
{
  x11()
  {
    ggplot()+
      geom_path(data = plotdata,
                aes(x_mean, y_mean), 
                #size =2, 
                col = "grey30",
                arrow = arrow(type = "closed", angle = 7))+
      geom_point(data = plotdata,
                 aes(x_mean, y_mean, size = duration, fill = area), 
                 pch = 21)+
      scale_fill_distiller(palette = "", direction = 1)+
      theme_bw()+
      facet_grid(resTimeLimit~travelSeg, labeller = label_both)+
      labs(col = "distance (m)",
           x = "long.", y = "lat.")+
      theme(axis.text = element_blank(),
            panel.grid = element_blank())
  }
}