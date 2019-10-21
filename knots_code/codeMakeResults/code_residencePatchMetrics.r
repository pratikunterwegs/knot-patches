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

# create output folder if not present
if(!dir.exists("../data2018/segmentData")){
  dir.create("../data2018/segmentData")
}

# read in the data and perform segmentation
map2(dataRevFiles, dataHtFiles, function(df1, df2){
  # make segmented data
  somedata <- watlasUtils::funcSegPath(revdata = df1, htdata = df2)
  
  if(nrow(somedata) > 5 & !is.na(nrow(somedata))){
    
    # write segmented data
    fwrite(x = somedata, file = glue::glue('../data2018/segmentData/seg_{unique(somedata$id)}_{unique(somedata$tidalcycle)}.csv'), dateTimeAs = "epoch")
  }
})

gc()

# list files
segFiles <- list.files("../data2018/segmentData", pattern = "seg", full.names=TRUE)


# remove data with fewer than 5 rows
# data <- purrr::keep(data, function(df) nrow(df) > 0 & !is.na(nrow(df)))

# make patches folder
if(!dir.exists("../data2018/patchData")){
  dir.create("../data2018/patchData")
}

# run the patch metric calculations
# do not return sf
map(segFiles[178:length(segFiles)], function(onThisData){
  # read in data
  data <- fread(onThisData)
  
  # prop inf
  preal <- data[,.N,by="type"][,p:=N/sum(N)][type=="real",p]
  
  # look if data are present
  if(length(preal) > 0){
    if(preal >= 0.2){
      
      # run patch function if
      patches <- watlasUtils::funcGetResPatches(df = data, returnSf = FALSE)
      
      # write data if patches not glue
      if(!"glue" %in% class(patches)){
        fwrite(x = patches, file = glue::glue('../data2018/patchData/patches_{unique(data$id)}_{unique(data$tidalcycle)}.csv'), dateTimeAs = "epoch")
      }
    }
  }
  
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
