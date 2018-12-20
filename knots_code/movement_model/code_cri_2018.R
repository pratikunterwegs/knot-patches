getwd()
#'load tidyverse
library(tidyverse)
#'load NLMR
library(NLMR)
#'load raster
library(raster)
library(viridis)
library(scico)

#'make landscape
landscape = nlm_gaussianfield(ncol = 100, nrow = 100, autocorr_range = 50)

landscape_df = as.matrix(landscape) %>% as.data.frame() %>% 
  `colnames<-`(1:ncol(.)) %>% 
  mutate(row = 1:nrow(.)) %>% gather(col, val, -row) %>% 
  mutate(col = as.numeric(col))

ggplot(landscape_df)+
  geom_tile(aes(x = col, y = row, fill = val))+
  geom_contour(aes(x = col, y = row, z = val), binwidth = 0.2, col = 1, alpha = 0.2)+
  scale_fill_scico(palette = "oleron", begin = 0, end = 0.8)+
  #scale_fill_gradientn(colours = magma(9))+
  theme_void()#+theme(legend.position = "none")

#plot(landscape)
#'make matrix
landscape_csv = as.matrix(landscape)

#'write to csv
write_delim(as.data.frame(landscape_csv), path = "movement_model/tide_landscape.csv", col_names = F, delim = " ")


#### 3d plot landscape
library(plot3D)

persp3D(x = 1:100, y = 1:100, z = as.matrix(landscape), zlim = c(0, 10), clim = c(0, 0.3), NAcol = 2, col = rev(brewer.pal(9, "GnBu")), phi = 10)

contour3D(x = 1:100, y = 1:100, z = as.matrix(landscape), zlim = c(0, 10), clim = c(0, 1), NAcol = 1, colvar = z)
