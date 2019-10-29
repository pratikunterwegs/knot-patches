#### code do recurse ####

# Code author Pratik Gupte
# PhD student
# MARM group, GELIFES-RUG, NL
# Contact p.r.gupte@rug.nl

library(tidyverse); library(data.table)

# list files
dataFiles <- list.files("../data2018/oneHertzData/recursePrep/", full.names = T)

# create dir for output
if(!dir.exists("../data2018/oneHertzData/recurseData")){
  dir.create("../data2018/oneHertzData/recurseData")
}

library(recurse)

## recurse params#
radius <- 50 # in metres
timeunits <- "mins"

map(dataFiles, function(filename) {
  
  # read in data
  df <- setDF(fread(filename)[,.(x,y,time,id, tidalcycle)])
  
  # assign bird and tidal cycle
  bird <- unique(df$id); tide <- str_pad(unique(df$tidalcycle),3,pad = 0)
  
  print(glue('read in bird {bird} in tidal cycle {tide}'))
  
  # run recurse
  dfRecurse <- getRecursions(x = df[,c("x","y","time","id")], radius = radius, 
                             timeunits = timeunits, verbose = TRUE)
  
  print(glue('recursed {bird} _ {tide} with radius = {radius}m'))
  
  # get residence time in the following steps
  # first select the revisit stats df and make dt
  dfRes <- setDT(dfRecurse[["revisitStats"]]
                 # if the time since last visit is NA, that was the first visit
                 # set that time to -Inf to pass all less than checks
  )[,timeSinceLastVisit:= ifelse(is.na(timeSinceLastVisit), -Inf, timeSinceLastVisit)
    # remove visits where the bird left for 60 mins, and then returned
    # this is regardless of whether after its return it stayed there
    # the removal counts the cumulative sum of all (timeSinceLastVisit <= 60)
    # thus after the first 60 minute absence, all points are assigned TRUE
    # this must be grouped by the coordinate
    ][,longAbsenceCounter:= cumsum(timeSinceLastVisit > 60), by= .(coordIdx)
      # keep points where the long absence pointer is < 1
      ][longAbsenceCounter < 1,]
  
  # calculate the residence time, fpt, revisits, and the x and y coords
  dfRes <- dfRes[,.(resTime = sum(timeInside),                  
           fpt = first(timeInside),
           revisits = max(visitIdx)), by=.(coordIdx,x,y)] # for each coordinate
  
  # assign a row id called coordIdx, helps with merging later, make df a dt
  setDT(df)[,coordIdx:=1:nrow(df)]
  
  # merge df and dfRes on x, y, and coord id, remove coord id after merge
  df <- merge(setDT(df), dfRes, by = c("x","y","coordIdx"))
  
  setorder(df, time)
  
  # write to file
  fwrite(df, file = glue("../data2018/oneHertzData/recurseData/recurse", bird,
                         "_", tide, ".csv"), dateTimeAs = "epoch")
  
  rm(df, dfRecurse, dfRes)
  
  print(glue('recurse on bird {bird} in tide {tide} ... done'))
  
  return('all recurse finished...')
})
