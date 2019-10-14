#### code for polygons around residence patches ####

# Code author Pratik Gupte
# PhD student
# MARM group, GELIFES-RUG, NL
# Contact p.r.gupte@rug.nl

library(tidyverse); library(data.table)
library(glue); library(sf)

# source distance function
source("codeFunctions/functionEuclideanDistance.r")

# source segmentation function
source("codeFunctions/func_segmentPath.r")

# function for resPatches arranged by time
source("codeFunctions/func_residencePatch.r")


# read in recurse data for selected birds
dataRevFiles <- list.files("../data2018/oneHertzData/recurseData/", full.names = T)[1:3]

# get time to high tide from written data
dataHtFiles <- list.files("../data2018/oneHertzData/recursePrep/", full.names = T)[1:3]

# gather in a dataframe# make dataframe of assumption parameters
resTimeLimit = c(4); travelSeg = c(5)
assumpData <- crossing(resTimeLimit, travelSeg)

# make data - param assump combo df
dataToTest <- tibble(revdata = dataRevFiles, 
                     htData = dataHtFiles, 
                     assump = list(assumpData)) %>% 
  unnest(cols = assump)

# read in the data and perform segmentation
data <- pmap(dataToTest, funcSegPath)

# run the patch metric calculations
# do not return sf
patches <- map_df(data, funcGetResPatches)

# write data to file
fwrite(data, file = "../data2018/oneHertzData/data2018patches.csv",
       dateTimeAs = "epoch")


# end here
