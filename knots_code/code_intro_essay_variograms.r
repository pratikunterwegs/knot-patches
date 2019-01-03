#### variograms for neutral landscapes ####

library(tidyverse);library(NLMR);library(raster)

#### how does sill vary with mag var ####

landscape_params = rep(data_frame(acr = (1:10), mag = (1:10)*5) %>% expand(acr, mag) %>% 
  plyr::dlply(c("acr","mag")))

landscapes = map(landscape_params, function(x) {nlm_gaussianfield(1e2, 1e2, autocorr_range = x$acr, mag_var = x$mag, rescale = F)})

#'raster to df function
raster_to_df = function(x){
  as.matrix(x) %>% as.data.frame() %>% `colnames<-`(1:ncol(.)) %>% mutate(row = 1:dim(.)[1]) %>% gather(col, val, -row) %>% mutate(col = as.numeric(col))
}

landscape_df = map(landscapes, raster_to_df)

landscape_df = landscape_df %>% bind_rows()

landscape_params = landscape_params %>% bind_rows() %>% mutate(id = paste(stringi::stri_pad(acr, 3, pad = 0), stringi::stri_pad(mag, 2, pad = 0), sep = "_"))

landscape_df = landscape_df %>% 
  mutate(id = rep(landscape_params$id, each = 1e4)) %>% 
  mutate(acr = substr(id, 1, 3), mag = substr(id, 5, 6))

library(RColorBrewer)

ggplot(landscape_df)+
  geom_raster(aes(x = col, y = row, fill = plyr::round_any(val, 0.1)))+
  facet_grid(acr~mag)+
  scale_fill_gradientn(colours = plasma(20))+
  theme_classic()+theme(legend.position = "none")


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
