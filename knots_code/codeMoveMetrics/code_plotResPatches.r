#### code to test plot resPatch segmentation ####

# load libs
library(ggplot2)

ggplot(patchSummary)+
  geom_path(aes(x_mean, y_mean, col = c(distBwPatch[-1],NA)), size =2)+
  geom_point(aes(x_mean, y_mean, size = duration), pch = 21, fill = "white")+
  scale_colour_distiller(palette = "Reds", direction = 1)
