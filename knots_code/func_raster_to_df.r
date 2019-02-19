
#'load libs
library(raster); library(dplyr)

#'raster to df function
raster_to_df = function(x){
  as.matrix(x) %>% as.data.frame() %>% `colnames<-`(1:ncol(.)) %>% mutate(row = 1:dim(.)[1]) %>% gather(col, val, -row) %>% mutate(col = as.numeric(col))
}