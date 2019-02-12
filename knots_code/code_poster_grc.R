#### making poster standin figs ####

library(NLMR)
library(viridis)

a = nlm_gaussianfield(1e2, 1e2)

raster::plot(a, col = rev(inferno(120)))
