#### code for polygons around residence patches ####

library(tidyverse); library(data.table)

# read in recurse data for selected birds
dataRevFiles <- list.files("../data2018/selRawData/recurseData/", full.names = T)
# read in the data
data <- purrr::map(dataRevFiles, fread)
# get id.tide names
library(glue)
names <- purrr::map_chr(data, 
                        function(x){ glue(unique(x$id), 
                                          stringr::str_pad(unique(x$tidalCycle), 3, pad = 0),
                                          .sep = ".") })
# assign names
names(data) <- names

# prep to assign sequence to res patches
data <- purrr::map(data, function(df) {
  df[!is.na(fpt),][,resTime:= ifelse(resTime <= 10, F, T)
                   ][,resPatch:= c(as.numeric(resTime[1]),
                                   diff(resTime))
                     ][resTime == T,
                       ][,resPatch:= cumsum(resPatch)]
})

# make residence patches
dataPatch <- list()
library(sf)
for(i in 1:length(data[c(1:2)])){
  df <- data[[i]]
  
  df <- group_by(df, resPatch) %>% 
    st_as_sf(coords = c("x", "y")) %>% 
        `st_crs<-`(32631) %>% 
        st_buffer(10) %>% 
        group_by(resPatch) %>% 
    summarise()
  
}



