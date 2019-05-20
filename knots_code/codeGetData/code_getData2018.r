
#### code to get 2018 ATLAS data ####
source("libs.R")
library(stringr)
library(readr)

# list files
funcs = as.list(list.files(pattern = "data_func_", full.names = T))

# run files
funcs[c(2,3)] %>% map(source)

# read in data sheet
library(readxl)
knots2018 <- read_excel("toa_knots_all_2018_22-10-2018.xlsx")

# get the wild knots
knots2018_wild <- knots2018 %>% filter(info == "Wild")

# use data retrieval and cleaning functions
# get temporal limits of tracking

tx <- knots2018_wild$Tag

# get the temporal limits -- first release to current day
from <- min(knots2018_wild$Date); to <- lubridate::today()

## remove beacons form tags; don't seem to be any beacons in the data in 2018?
tags<-tx[!tx%in%c(21,120, 253, 254, 255)]

## convert tags to three characters
tags<-str_pad(as.character(tags), 3, pad = "0")

# get 10 knots per go, save data and then erase data, clean garbage and get next 10
data2018.raw = list()

for(i in 1:length(tags)) {
 # get knots 1
  data2018.raw[[i]] <- lapply(tags[i], get_data, from=from, to=to, tag_prefix="31001000")
  if(i %% 10 == 0) {save(data2018.raw, file = paste("../data2018/knots2018raw",i-10,"to",i,".rdata",sep = "")); rm(data2018.raw);gc();data2018.raw = list()}

  if(i == length(tags)) {data2018.raw <- data2018.raw[unlist(lapply(data2018.raw, class))=="list"]; save(data2018.raw, file = paste("../data2018/knots2018rawfinal",".rdata",sep = "")); rm(data2018.raw);gc();data2018.raw = list()}
}

# load all the rdata objects and make one df
data.files <- list.files(path = "../data2018/", pattern = c("knots2018raw", "rdata"))

spacer <- 31001000; spacer.length = nchar(spacer)
# now, what we've done is very silly indeed, which is to save all the data in an object of the same name, which will result in overwriting when all of them are loaded at once.
# the solution is another loop. or some thought before coding high cost scripts

data2018 <- list()
for (i in 1:length(data.files)) {
  load(data.files[i])
  holding.list <- data2018.raw[unlist(lapply(data2018.raw, class)) == "list"]
  data2018 <- append(data2018, holding.list)
  rm(holding.list);rm(data2018.raw);gc()
}

# each track has become a list containing one df, bindrows on them. then on each df, remove the spacer value from the tag id for effective joining with the metadata
data2018 <- map(data2018, bind_rows) %>%
  map(data2018, function(x){
    x %>% mutate(TAG = substr(TAG, spacer.length+1, nchar(TAG)))
  })


# save data as an rdata object and a csv file. make COPIES on HDD!
save(data2018, file = "knots_data/data2018.rdata")

# make df for csv save
data2018 <- bind_rows(data2018)

# write csv?
write_csv(bind_rows(data2018), path = "knots_data/data2018.csv", col_names = T)
