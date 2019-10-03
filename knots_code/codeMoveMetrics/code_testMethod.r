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
           ][,resTime:= ifelse(resTime <= resTimeLimit, F, T)
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
  patchData$resTimeLimit = resTimeLimit
  patchData$travelSeg = travelSeg
  
  return(patchData)
}

# get patches
patches <- map(data, funcReturnPatchData)

#### diagnostic plots for respatches ####
# get griend
griend <- st_read("../griend_polygon/griend_polygon.shp")

# plot data
{
  png(filename = "../figs/figSegmentationAssumptions.png",
      width = 2400, height = 3600, res = 300)
 # x11()
  {  
    par(mfrow = c(3,3), 
         mar = rep(2,4))
    map2(data, patches, function(df1, df2){
      
      g1 = st_crop(griend, xmin = min(df1$x) - 5e2,
                   xmax = max(df1$x)+5e2,
                   ymin = min(df1$y),
                   ymax = max(df1$y))
      
      # plot griend
      # plot(g1,
      #      main = glue('resTimeLimit = {unique(df1$resTimeLimit)} mins, travelSeg = {unique(df1$travelSeg)} pts'),
      #      reset = FALSE,
      #      col = "grey95",
      #      border = "transparent",
      #      cex.main = 1, asp = 0.5)
      # 
      setDT(df1)
      setorder(df1, time)
      
      # plot points
      plot(df1$x, df1$y, type = "p", add = TRUE, cex = 0.2,
             col = pals::kovesi.rainbow(20)[df1$resPatch],
                main = glue('resTimeLimit = {unique(df1$resTimeLimit)} mins, travelSeg = {unique(df1$travelSeg)} pts'))

      # plot patches scaled by duration
      points(df2$x_mean, df2$y_mean,
             pch = 21,
             cex = df2$duration*0.002, col = "grey29", 
             bg = scales::alpha("grey", 0.2))
      
      # add bg
      # points(df2$x_mean, df2$y_mean,
      #        pch = 19,
      #        cex = df2$duration*0.002, alpha = 0.2)
      text(df2$x_mean, df2$y_mean, col = 1,
             cex = 2,
             labels = as.character(df2$resPatch))
      
      # plot path
      lines(df2$x_mean, df2$y_mean,
             cex = df2$duration*0.002, col = 1)
    })
  }
  dev.off()
}

