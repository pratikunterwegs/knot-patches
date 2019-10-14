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
dataRevFiles <- list.files("../data2018/oneHertzData/recurseData/", full.names = T)

# get time to high tide from written data
dataHtFiles <- list.files("../data2018/oneHertzData/recursePrep/", full.names = T)

# gather in a dataframe
data <- as_tibble(dataRevFiles, dataHtFiles)

# read in the data and perform segmentation
data <- purrr::pmap_df(data, funcSegPath)



# write data to file
fwrite(data, file = "../data2018/oneHertzData/data2018patches.csv",
       dateTimeAs = "epoch")


# end here
