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


# remove data with fewer than 5 rows
data <- purrr::keep(data, function(df) nrow(df) > 0 & !is.na(nrow(df)))

gc()

# run the patch metric calculations
# do not return sf
patches <- map_df(data, function(onThisData){
  watlasUtils::funcGetResPatches(df = onThisData, returnSf = FALSE)
})

 # test some patches
library(ggplot2)
library(ggthemes)
ggplot(patches)+
  geom_point(aes(X_mean,Y_mean, size = duration, col = type))+
  geom_path(aes(X_mean,Y_mean), arrow = arrow(angle = 7))+
  theme(legend.position = "none")

# write data to file
fwrite(patches, file = "../data2018/oneHertzData/data2018patches.csv",
       dateTimeAs = "epoch")


# end here
