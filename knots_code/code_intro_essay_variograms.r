#### variograms for neutral landscapes ####

library(tidyverse);library(NLMR);library(raster)

a = nlm_gaussianfield(1e2, 1e2, autocorr_range = 50, rescale = T, nug = 0.9)
plot(a, col = viridis(20))

#'raster to df function
raster_to_df = function(x){
  as.matrix(x) %>% as.data.frame() %>% `colnames<-`(1:ncol(.)) %>% mutate(row = 1:dim(.)[1]) %>% gather(col, val, -row) %>% mutate(col = as.numeric(col))
}

b = raster_to_df(a)
c = b; sp::coordinates(c) =  ~ col+row

#'make variogram
library(gstat)
fit = variogram(val ~ col+row, data = c)

#'plot variogram
plot(fit, pch = 16, type = "b")
