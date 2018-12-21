getwd()
#'load tidyverse
library(tidyverse)
#'load NLMR
library(NLMR)
#'load raster
library(raster)

#### make tidal landscape ####
landscape_tide = nlm_gaussianfield(ncol = 100, nrow = 100, autocorr_range = 50)

#landscape_tide_df = as.matrix(landscape_tide) %>% as.data.frame() %>% 
#  `colnames<-`(1:ncol(.)) %>% 
#  mutate(row = 1:nrow(.)) %>% gather(col, val, -row) %>% 
#  mutate(col = as.numeric(col))

#plot(landscape)
#'make matrix
landscape_tide_csv = as.matrix(landscape_tide)

#'write to csv
write_delim(as.data.frame(landscape_tide_csv), path = "movement_model/tide_landscape.csv", col_names = F, delim = " ")


# 3d plot tide landscape
library(plot3D)
library(RColorBrewer)
persp3D(x = 1:100, y = 1:100, z = as.matrix(landscape_tide), zlim = c(0, 7), clim = c(0, 0.6), NAcol = "goldenrod", col = rev(brewer.pal(9, "GnBu")), phi = 10, box = F, legend = F)

#### make food landscape ####
#'map nlm gaussian field onto 2:20 as autocorr range
food_landscapes = map(2:20, function(x){
                        nlm_gaussianfield(ncol = 100, nrow = 100, autocorr_range = x)}) %>% 
  map(as.matrix)

#'write to csv using for loop
#'
for(i in 1:length(food_landscapes)){
  write_delim(as.data.frame(food_landscapes[[i]]), path = paste("movement_model/food_landscape", i+ 1, ".csv", sep = ""), col_names = F, delim = " ")
}

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
