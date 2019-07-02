#### code to summarise various data ####

library(data.table); library(tidyverse); library(glue)
library(fasttime)

# read in data and add tidal cycles
dataFiles <- list.files(path = "../data2018/oneHertzData/", full.names = TRUE, pattern = "csv")

# check total data collected
dataSummary <- map_df(dataFiles, function(z){
  setDF(fread(z)[,.(startTime = min(TIME),
              endTime = max(TIME),
              fixes = length(X),
              xmin = min(X),
              ymin = min(Y),
              xmax = max(X),
              ymax = max(Y),
              id = as.character(unique(TAG - 3.1001e10)))])
})

# check for fixes order of magnitude
count(dataSummary, fixLog = floor(log10(fixes)))

# count total number of fixes
sum(dataSummary$fixes)

# get range of time as posixct
diff(as.POSIXct(range(c(dataSummary$startTime, dataSummary$endTime)), origin = "1970-01-01", tz = "Europe/Berlin"))

# get bounding box and convex hull area of the limits of the positions
library(sf)

bounds <- dataSummary %>% group_by(id) %>% nest()
boundBox <- map(bounds$data, function(z){
  st_bbox(c(xmin = z$xmin, xmax = z$xmax, ymin = z$ymin, ymax = z$ymax), crs = 32631) %>% 
    st_as_sfc()
}) %>% reduce(c) %>% 
  st_union()

# area of the bounding box
st_area(boundBox)


# read in behavioural scores for release times
behavData <- fread("../data2018/behavScores.csv")[,`:=`(Release_Date=as.POSIXct(Release_Date),
                                                        id=as.character(id))] %>% 
  as_tibble()

# how many transmitting before release
dataSummary = inner_join(dataSummary, behavData) %>% 
  distinct(id, .keep_all = T)
count(dataSummary, transmittingBeforeRelease = startTime < as.numeric(Release_Date))

# count how many positions removed
recPrepFiles <- list.files("../data2018/oneHertzData/recursePrep/", full.names = T)

# read in data and ask how many rows
recPrepData <- map_df(recPrepFiles, function(z){
  fread(z)[,.(startTime = min(time),
               endTime = max(time),
               fixes = length(x)),by=id]
})

recPrepDataSummary <- recPrepData[,.(nFixesFilter=sum(N)),by=id]
sum(recPrepData$nFixesFilter)

# get mean, sd of fixes per bird
recPrepData %>% summarise_at(vars(nFixesFilter), 
                             list(~mean(.), ~sd(.), ~min(.), ~max(.)))

# get mean per release week
recPrepData %>%
  mutate(id = as.character(id)) %>% 
  inner_join(dataSummary %>% mutate(relWeek = week(Release_Date)) %>% 
               select(id, relWeek)) %>% 
  group_by(relWeek) %>% 
  summarise_at(vars(nFixesFilter), 
               list(~mean(.), ~sd(.), ~min(.), ~max(.), ~length(.)))
