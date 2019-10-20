#### code for polygons around residence patches ####

# Code author Pratik Gupte
# PhD student
# MARM group, GELIFES-RUG, NL
# Contact p.r.gupte@rug.nl

library(tidyverse); library(data.table)
library(glue); library(sf)

# install from devbranch
devtools::install_github("pratikunterwegs/watlasUtils", ref="devbranch", force = T)
library(watlasUtils)

# read in recurse data for selected birds
dataRevFiles <- list.files("../data2018/oneHertzData/recurseData/", full.names = T)[1:3]

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
