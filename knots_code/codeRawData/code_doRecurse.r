#### code do recurse ####

library(tidyverse); library(data.table)

#### segmentation process ####

# list files
dataFiles <- list.files("../data2018/oneHertzDataSubset/recursePrep/", full.names = T)

# create dir for output
if(!dir.exists("../data2018/oneHertzDataSubset/recurseData")){
  dir.create("../data2018/oneHertzDataSubset/recurseData")
}

library(recurse)

## recurse params#
radius <- 50 # in metres
timeunits <- "mins"

map(dataFiles, function(filename) {
  
  # read in data
  df <- as.data.frame(fread(filename)[,.(x,y,time,id, tidalcycle)])
  
  # assign bird and tidal cycle
  bird <- unique(df$id); tide <- str_pad(unique(df$tidalcycle),3,pad = 0)
  
  # run recurse
  dfRecurse <- getRecursions(x = df[,c("x","y","time","id")], radius = radius, 
                             timeunits = timeunits, verbose = TRUE)
  
  # get residence time as sum of first 1 hour
  dfRes <- setDT(dfRecurse[["revisitStats"]]                          # select rev stats
  )[,cumlTime:=cumsum(timeInside),                     # calc cumulative time
    by=.(coordIdx,x,y)                                 # for each coordinate
    ][cumlTime <= 60,                                  # remove times > 60
      ][,.(resTime = sum(timeInside),                  # calc metrics
           fpt = first(timeInside),
           revisits = max(visitIdx)), .(coordIdx,x,y)] # for each coordinate
  
  # join to data, for some reason, data.table converts time to posixct
  # this conversion is both wrong and unwanted
  df <- left_join(df, dfRes, by = c("x","y"))
  
  # write to file
  fwrite(df, file = glue("../data2018/oneHertzDataSubset/recurseData/recurse", bird,
                         "_", tide), dateTimeAs = "epoch")
  
  rm(df, dfRecurse, dfRes)
  
  print(glue('recurse on bird {bird} in tide {tide} ... done'))
  
  return('all recurse finished...')
})
