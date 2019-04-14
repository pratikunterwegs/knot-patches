#### script to reduce 2018 tracking data ####

#'load libs
library(tidyverse)

#### data loading ####
#'list all files in data2018
data2018names = list.files("../data2018/", pattern = "knots2018", full.names = T)

#'for each file, get a size and plot
fileSizes = sapply(data2018names, file.size, USE.NAMES = F)/1e6; barplot(fileSizes)

#### data compression to 10 seconds ####
#'for each rdata object:
#'1. load
#'2. convert to basic x,y,t
#'3. reduce to 10 second intervals
#'4. export as csv

for(i in 1:length(data2018names))
{
  data = load(data2018names[i])
  
  #'remove empty elements
  data = data2018.raw %>% 
    keep(function(x)length(x)>0) %>% 
    map(bind_rows)
  
  #'remove raw data
  rm(data2018.raw)
  
  #'convert to x,y,t
  data = data %>% 
    map(function(x) select(x, time=TIME, x=X, y=Y, covxy = COVXY, towers = NBS, id = TAG)) %>% 
    map(function(x) mutate(x, time = plyr::round_any(time/1000, 10), id = id - 3.1001e10)) %>% 
    map(function(x) x %>% filter(towers > 3) %>% group_by(time) %>% summarise_all(mean))
  
  #'bind rows
  data = bind_rows(data)
  
  #'write as csv
  write_csv(data, paste("../data2018/data",
                        i*10 - 10, "to", i*10,
                        ".csv", sep = "_"))
  
  rm(data); gc()
  
}