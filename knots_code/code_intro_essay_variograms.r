#### variograms for neutral landscapes ####

library(tidyverse);library(NLMR);library(raster)

#### how does sill vary with mag var ####

landscape_params = rep(data_frame(acr = (1:10)*20, mag = (1:10)*5) %>% expand(acr, mag) %>% 
  plyr::dlply(c("acr","mag")))

landscapes = map(landscape_params, function(x) {nlm_gaussianfield(1e2, 1e2, autocorr_range = x$acr, mag_var = x$mag)})

#'raster to df function
raster_to_df = function(x){
  as.matrix(x) %>% as.data.frame() %>% `colnames<-`(1:ncol(.)) %>% mutate(row = 1:dim(.)[1]) %>% gather(col, val, -row) %>% mutate(col = as.numeric(col))
}

landscape_df = map(landscapes, raster_to_df)

library(gstat)
for(i in 1:length(landscape_df)){
  coordinates(landscape_df[[i]]) = ~ col + row
  landscape_df[[i]] = variogram(val ~ col+row, data = landscape_df[[i]])
  
}

landscape_df = landscape_df %>% map(function(x){x %>% as.data.frame() %>% dplyr::select(dist, gamma)})

landscape_df = landscape_df %>% bind_rows() %>% mutate(acr = rep((1:10)*20, each = 150), mag = rep(rep((1:10)*5, each = 15), 10))

ggplot(landscape_df)+
  geom_point(aes(dist, gamma))+
  facet_grid(acr ~ mag)
