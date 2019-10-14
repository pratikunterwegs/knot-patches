#### function for residence time segmentation ####
funcSegPath <- function(revdata, htData, resTimeLimit = 2, travelSeg = 5,
                        inferPatches = TRUE){
  
  # adding the inferPatches argument to prep for inferring
  # residence patches from missing data between travel segments
  
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
  
  if(inferPatches == TRUE){
    # get the max and min time
    maxtime = max(df$time); mintime= min(df$time)
    
    # make a df with id, tidalcycle and time seq, with missing x and y
    # identify where there are missing segments more than 2 mins long
    # there, create a sequence of points with id, tide, and time in 3s intervals
    # merge with true df
  }
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
  
}