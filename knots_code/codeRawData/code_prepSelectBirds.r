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
 
  rm(data2018.raw); gc()
     
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

# remove select data
rm(selectData); gc()

#### assign tidal cycles ####
# load tidal data
tides <- read_csv("../data2018/tidesSummer2018.csv") %>%
  filter(tide == "H")

# read in sample data as data
data <- fread("../data2018/selRawData/birdsForSeg.csv")

# filter out 24 hours after release
# read in release time
releaseData <- read_csv("../data2018/behavScores.csv") %>% 
  mutate(timeNumRelease = as.numeric(Release_Date))

# join to data and keep data where time >= release date + 24 h
data <- left_join(data, releaseData %>% select(id, timeNumRelease)) %>% 
  filter(time >= timeNumRelease + (24 * 3600)) %>% 
  select(-timeNumRelease)

# bind tides and data on time
data <- split(data, f = data$id) %>% 
  map(function(df){
    full_join(df, tides, by = c("time" = "timeNum")) %>% 
      arrange(time) %>%                                 # arrange by time
      mutate(tide = ifelse(is.na(level), "other", tide),# classify points
             tidalCycle = cumsum(tide == "H")) %>%      # assign tidal cycle
      filter(!is.na(x)) %>%                             # remove non positions
      select(-tide, -level, -time.y)                    # remove tidal data
  }) %>% bind_rows() %>% 
  mutate(tidalCycle = tidalCycle - min(tidalCycle) + 1) %>% 
  group_by(id, tidalCycle) %>% 
  mutate(timeToHiTide = (time - min(time)) / 3600)

# plot positions per tidal cycle
count(data, id, tidalCycle) %>% 
  ggplot(aes(x = factor(tidalCycle), y = factor(id), fill = n))+
  geom_tile(col = "white", size = 0.2)+
  scale_fill_viridis_c(option = "magma")+
  theme_bw()+
  theme(axis.text.x = element_text(angle = 45, size = 4))+
  labs(x = "tidal cycle", y = "id", fill = "fixes")

# make plot
ggsave("../figs/figRdSampleFixesPerTide.pdf", device = pdf(), height = 5,
       width = 12); dev.off()

# write to file
fwrite(data, file = "../data2018/selRawData/rawdataWithTides.csv")