#### variograms for neutral landscapes ####

library(tidyverse);library(NLMR);library(raster)

#### how does sill vary with mag var ####

landscape_params = rep(data_frame(acr = (c(2, 20, 80))) %>% 
  plyr::dlply(c("acr")))

landscapes = map(landscape_params, function(x) {nlm_gaussianfield(1e2, 1e2, autocorr_range = x$acr, rescale = T)})

#### plot direct from raster ####
{
  x11()
  par(mfrow = c(10,10))
  for(i in 1:100){
    plot(landscapes[[i]])
  }
}

#'raster to df function
raster_to_df = function(x){
  as.matrix(x) %>% as.data.frame() %>% `colnames<-`(1:ncol(.)) %>% mutate(row = 1:dim(.)[1]) %>% gather(col, val, -row) %>% mutate(col = as.numeric(col))
}

#### make df from raaster ####
landscape_df = map(landscapes, raster_to_df)


landscape_params = landscape_params %>% bind_rows() %>% mutate(id = paste(stringi::stri_pad(acr, 3, pad = 0)))

landscape_df = landscape_df %>% bind_rows() #%>% mutate(id = paste(stringi::stri_pad(acr, 3, pad = 0), stringi::stri_pad(mag, 2, pad = 0), sep = "_"))

landscape_df = landscape_df %>% 
  mutate(id = rep(landscape_params$id, each = 1e4)) %>% 
  mutate(acr = as.numeric(substr(id, 1, 3)))

library(RColorBrewer)
library(viridis); library(plot3D)

fig2a = ggplot(landscape_df)+
  geom_raster(aes(x = col, y = row, fill = plyr::round_any(val, 0.1)))+
  facet_wrap(~acr)+
  scale_fill_gradientn(colours = brewer.pal(7, "RdBu"))+
  theme_pub()+theme(legend.position = "none")+
  labs(list(x = NULL, y = NULL, title = "(a)"))

#### plot variability ####
landscape_df %>% group_by(acr, size) %>% summarise(var = var(val)) %>% ggplot()+geom_col(aes(x = 1, y = var))+facet_grid(acr~size)

library(gstat)
for(i in 1:length(landscapes)){
  landscapes[[i]] = raster_to_df(landscapes[[i]])
  coordinates(landscapes[[i]]) = ~ col + row
  landscapes[[i]] = variogram(val ~ col+row, data = landscapes[[i]])
  
}

landscape_vargrams = landscapes %>% map(function(x){x %>% as.data.frame() %>% dplyr::select(dist, gamma)})

source("ggplot.pub_geese.r")

landscape_vargrams = landscape_vargrams %>% bind_rows() %>% mutate(acr = rep(c(2,20,80), each = 15))

fig2b = 
  ggplot(data = landscape_vargrams, aes(dist, (1/gamma)/1e3))+
  geom_point()+
  geom_line()+
  facet_wrap(~acr)+
  theme_pub()+
  geom_hline(yintercept = 0.1, col = 2)+
  labs(list(y = "Autocorrelation", x = "Distance (grid cells)", title = "(b)"))

library(gridExtra)

grid.arrange(fig2a, fig2b, nrow = 2)  
