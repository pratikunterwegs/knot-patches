getwd()
#'load tidyverse
library(tidyverse)
#'load NLMR
library(NLMR)
#'load raster
library(raster)

#### make tidal landscape ####
plot(nlm_edgegradient(100,100))
plot(nlm_planargradient(100,100))
landscape_tide = (1-nlm_distancegradient(100,100, origin = c(50,50,50,50)))
#'make matrix
landscape_tide_csv = as.matrix(landscape_tide)

#'write to csv
write_delim(as.data.frame(landscape_tide_csv), path = "movement_model/tide_landscape.csv", col_names = F, delim = " ")

landscape_tide_2 = as.matrix(landscape_tide) %>% as.data.frame() %>% `colnames<-`(1:100) %>% mutate(row = 1:100) %>% gather(col, val, -row) %>% mutate(col = as.numeric(col))


#' 3d plot tide landscape
library(plot3D)
library(RColorBrewer)
persp3D(x = 1:100, y = 1:100, z = as.matrix(landscape_tide), zlim = c(0, 7), clim = c(0, 0.9), NAcol = "goldenrod", col = rev(brewer.pal(9, "GnBu")), phi = 10, box = T, legend = F)

##'save the raster layer
writeRaster(landscape_tide, filename = "circular_tidal_raster.tif")


a = rev(colorRampPalette(brewer.pal(9, "BuPu")[c(3:9)])(20))
b = rev(colorRampPalette(brewer.pal(9, "BrBG")[c(1:5)])(20))
#c = rev(colorRampPalette(brewer.pal(9, "BrBG")[c(3:9)])(5))
#c = viridis(20, begin = 0.5, end = 1, direction = -1)

ggplot(landscape_tide)+
  geom_tile(aes(x = col, y = row, fill = ifelse(val > 0.9, 2, val)))+
  #scale_fill_gradientn(colours = c(a,b))+
  coord_equal()+
  theme_void()+theme(legend.position = "none")

#### make food landscape ####


#'map nlm gaussian field onto 2:20 as autocorr range
food_landscapes = map(2:20, function(x){
                        nlm_gaussianfield(ncol = 100, nrow = 100, autocorr_range = x)})# %>% 
  map(as.matrix)

#'write to csv using for loop
#'
for(i in 1:length(food_landscapes)){
  write_delim(as.data.frame(food_landscapes[[i]]), path = paste("movement_model/food_landscape", i+ 1, ".csv", sep = ""), col_names = F, delim = " ")}

landscape_food_df = as.matrix(landscape_food) %>% as.data.frame() %>% 
  `colnames<-`(1:ncol(.)) %>% 
  mutate(row = 1:nrow(.)) %>% gather(col, val, -row) %>% 
  mutate(col = as.numeric(col))

#plot(landscape)
#'make matrix
landscape_food_csv = as.matrix(landscape_food)

#'write to csv
write_delim(as.data.frame(landscape_food_csv), path = "movement_model/food_landscape.csv", col_names = F, delim = " ")


# 3d plot food landscape
library(plot3D); library(viridis)
library(RColorBrewer)
persp3D(x = 1:100, y = 1:100, z = as.matrix(landscape_food), zlim = c(0, 20), clim = c(0, 1), NAcol = 2, col = brewer.pal(9, "RdYlBu"), phi = 10, box = F, legend = F)
