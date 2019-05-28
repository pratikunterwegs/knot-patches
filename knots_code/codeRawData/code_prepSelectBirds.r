#### code to deal with raw data from selected birds ####
# selected birds are

selected_birds <- c(439, 547, 550, 572, 593)

# load libs
library(tidyverse)

# list files
dataFiles <- list.files("../data2018/", pattern = "knots2018", full.names = T)

# selected data
selectData <- list()

for(i in 1:length(dataFiles))
{
  load(dataFiles[i])
  
  # prep data to compare
  data <- data2018.raw %>%
    keep(function(x) length(x) > 0) %>% # keep non null lists
    flatten() %>% # flatten this list structure
    keep(function(x) nrow(x) > 0) # keep dfs with data
    
  data <- keep(data, function(x) unique(x$TAG - 3.1001e10) %in% selected_birds)
  
  # if the list is non-empty, add to a another list
  if(length(data) > 0){
    selectData <- append(selectData, data)
    rm(data); gc()
  } else { rm (data); gc() }
  
}

# output selectData as csv with some mods
selectData <- map(selectData, function(df){
  select(df, time=TIME, x=X, y=Y, covxy=COVXY, towers=NBS, id=TAG) %>% 
  mutate(time = time/1e3, id = id - 3.1001e10)
}) %>% 
  bind_rows()

# make output dir if non existent
if(!dir.exists("../data2018/selRawData")){
  dir.create("../data2018/selRawData")
}

# write to file
data.table::fwrite(selectData, file = "../data2018/selRawData/birdsForSeg.csv")