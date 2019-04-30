#### code to segment on residence ####

#### load libs ####
library(tidyverse); library(readr)
rm(list = ls()); gc()

# load position data with residence times
data = read.csv("../data2018/data2018WithRecurse.csv") %>% 
  select(id.tide, timeNum, x, y, residenceTime)

# split by id and tide
data = plyr::dlply(data, "id.tide")

# run segclust2d on residence time
library(segclust2d)

# write segmentation function for data
# choose lmin = 5
# choose Kmax = auto
# seg.var = "residenceTime"
# no subsampling
funcSegment = function(x){
  assertthat::assert_that(is.data.frame(x), msg = "x is not a df!")
  x1 = segmentation(x, lmin = 15, seg.var = "residenceTime")
  return(x1)
}

# function to add data to position data
funcAugment = function(y){
  assertthat::assert_that(class(y) == "segmentation",
                          msg = "input is not a segclust2d output")
  
  y1 = augment(y)[c("state_ordered")]
  return(y1)
}

# run across the list of dfs
for (i in 1:length(data)) {
  
  segmentedDf = funcSegment(data[[i]])
  augmentedDf = funcAugment(segmentedDf)
  data[[i]]$segment = augmentedDf$state_ordered
  
  write_csv(data[[i]], 
            path = paste("../data2018/segmentation/", data[[i]]$id.tide[1], "segmented.csv", sep = ""))
  
  gc()
}
