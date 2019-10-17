#### code for polygons around residence patches ####

# Code author Pratik Gupte
# PhD student
# MARM group, GELIFES-RUG, NL
# Contact p.r.gupte@rug.nl

library(tidyverse); library(data.table)
library(glue); library(sf)

# load the custom library
devtools::install_github("pratikunterwegs/watlasUtils", ref="devbranch", force = TRUE)
library(watlasUtils)

# read in recurse data for selected birds
dataRevFiles <- list.files("../data2018/oneHertzData/recurseData/", full.names = T)

# read in ht data
dataHtFiles <- list.files("../data2018/oneHertzData/recursePrep/", full.names = T)

# read in the data and perform segmentation
data <- map2(dataRevFiles, dataHtFiles, function(df1, df2){
  watlasUtils::funcSegPath(revdata = df1, htdata = df2)
})

# run the patch metric calculations
# do not return sf
patches <- map_df(data, function(onThisData){
  watlasUtils::funcGetResPatches(df = onThisData)
})

# test some patches
library(ggplot2)
ggplot(patches)+
  geom_point(aes(X_mean,Y_mean, size = duration))

# write data to file
fwrite(patches, file = "../data2018/oneHertzData/data2018patches.csv",
       dateTimeAs = "epoch")


# end here
