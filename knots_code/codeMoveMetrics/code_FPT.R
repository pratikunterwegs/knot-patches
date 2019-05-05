#### estimating first passage time ####
# load the data and estimate first passage time using the
# recurse function or similar

rm(list = ls()); gc()

# load libs
library(tidyverse); library(readr)

# read in the data
data = read_csv("../data2018/data2018posWithTides.csv")

# subset for good data
# 
# A NOTE ON GOOD DATA
# GOOD DATA ARE:
#  PER-ID PER-TIDE DATA WHERE:
#   > 0.33 OF THE DURATION
# HAS BEEN COVERED, IE, 139 MINUTES BETWEEN START AND END OF TRACKING
# AND
# AND
# WHERE:
#  > 0.33 OF THE EXPECTED FIXES ARE PRESENT.
#  
#  EACH ID-TIDE COMBINATION THUS HAS AT LEAST 831 OBSERVATIONS
# 
goodData = read_csv("../data2018/dataSummary2018.csv") %>% 
  mutate(id.tide = paste(id,stringr::str_pad(tidalCycle, 3, pad = "0"),sep = ".")) %>% 
  filter(propDur >= 0.33, propFixes >= 0.33)

# write good data to file
write_csv(goodData, path = "../data2018/goodData2018.csv")

data = mutate(data, 
              id.tide = paste(id,stringr::str_pad(tidalCycle, 3, pad = "0"),sep = ".")) %>% 
  filter(id.tide %in% goodData$id.tide)

#### prepare for recursion analysis ####
# make list of id - tidalCycle combination
data = plyr::dlply(data, "id.tide")
# remove dataframes with less than 33% points, ~139
#data = purrr::keep(data, function(x) nrow(x) >= 150)

# prepare for recurse by exporting to file
for(i in 1:length(data)){
  write_csv(data[[i]] %>% select(-level), path = paste("../data2018/dataRecurse/id.tide", 
                                    unique(data[[i]]$id.tide),".csv", sep = ""))
}

# prepare files list to read in data
recurseFiles = list.files(path = "../data2018/dataRecurse/", full.names = T)

library(recurse)

#### run recurse ####

# in a for loop, read files, make recurse, write to file, remove data
for(i in 1:length(recurseFiles)){
  x = as.data.frame(read_csv(recurseFiles[i],
               col_types = list("n", "T", "n", "n",
                             "?", "?", "?", "?",
                             "?", "?", "?", "?",
                             "c")))

  id.tide = as.character(unique(x$id.tide))
  #id = unique(x$id); tide = unique(x$tidalCycle)

  x = x[,c("x", "y", "time", "id")]

  # get revisits from a radius of 100m
  # threshold of 10 minutes
  xRecurse = getRecursions(x = x, radius = 100, threshold = 10,
    timeunits = "mins", verbose = TRUE)

  # get FPT as first residence time
  xFpt = xRecurse[["revisitStats"]] %>%
          group_by(coordIdx) %>%
          summarise(fpt = first(timeInside))

  # make tibble
  xRecurseData = tibble(id.tide = id.tide,
            residenceTime = xRecurse[["residenceTime"]],
            revisits = xRecurse[["revisits"]],
            fpt = xFpt$fpt)

  # clear memory
  rm(x, xRecurse, xFpt); gc()

  # write recurse to file
  write_csv(xRecurseData, path = paste("../data2018/dataRecurseStats/", 
            id.tide, ".csv"))

  # remove data
  rm(xRecurseData, id.tide); gc()
}

#### read data back in and get FPT ####
# list files
recurseFiles = list.files(path = "../data2018/dataRecurseStats",
                          full.names = T)

# read the files in
recurseData = lapply(recurseFiles, function(x){
  read_csv(x, col_types = list("_", "n", "n", "n"))
})

# bind to existing data, then bind rows
data = map2(data, recurseData, cbind)
data = bind_rows(data)

# check to see if each id.tide combo has 831 obs
count(data, id.tide) %>% count(n > 830)
# 14 do not fit this criterion

# remove recurse data
rm(recurseData); gc()

#### write good recurse data to file ####
write_csv(data, path = "../data2018/data2018WithRecurse.csv")
