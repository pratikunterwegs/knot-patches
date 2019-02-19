#### making poster standin figs ####

library(NLMR)
library(viridis)
library(colorspace)
library(tidyverse)
source("func_raster_to_df.r")

#'make landscapes using NLMR
#'high autocorrelation range
landHiACR = nlm_gaussianfield(1e2, 1e2, autocorr_range = 1e2)
#'low autocorrelation range
landLoACR = nlm_gaussianfield(1e2, 1e2, autocorr_range = 1e1)
#'medium acr
landMdACR = nlm_gaussianfield(1e2, 1e2, autocorr_range = 5e1)

#'get colour palettes
cols = rev(terrain_hcl(120))

#'plot each
{par(mfrow = c(1,2));
raster::plot(landHiACR, col = cols, bty = "n", box = F, axes = F, legend = F);
raster::plot(landLoACR, col = cols, bty = "n", box = F, axes = F, legend = F);
  par(mfrow = c(1,1))
}

#'make timeseries from raster values
#'make the landscapes dataframes
landList = list(landHiACR, landLoACR, landMdACR)

#'map the raster to df across the list
landList = map(landList, raster_to_df)

#'run a sim across each cell of each raster
#'write function
waterHeight = function(x) {x - ((x/2) * cos(((2.0 * pi)/maxT) * t)) - (x/2)}
#'set maxT and t
maxT = 1e2; t = seq(1,1e3, 1e1)

#'run sim data
landList = landList %>% 
  map(function(x){
    x %>% as_tibble() %>% 
      mutate(valSeq = map(.$val, waterHeight))
  })

landTempACF = landList %>% 
  map(function(x){
    map(x %>% sample_n(1e2) %>% .$valSeq, function(y) {acf(unlist(y), plot = F)$acf})
  })
