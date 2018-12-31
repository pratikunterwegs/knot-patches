#### rayshader examples #####

library(rayshader);library(NLMR)

localtif = (1-nlm_distancegradient(100,100, origin = c(50,50,50,50)))*100 + (nlm_gaussianfield(100, 100, autocorr_range = 20)*10)
elmat = matrix(raster::extract(localtif,raster::extent(localtif),buffer=1e3),
               nrow=ncol(localtif),ncol=nrow(localtif))

png("elevation_shading.png", width=ncol(localtif), height=nrow(localtif), units = "px", pointsize = 1)

par(mar = c(0,0,0,0), xaxs = "i", yaxs = "i") #Parameters to create a borderless image

raster::image(
  localtif,
  col = viridis(120),
  maxpixels = raster::ncell(localtif),
  axes = FALSE
)

dev.off()

terrain_image <- png::readPNG("elevation_shading.png")

rgl.open()
mfrow3d(3,2, byrow = T, parent = NA)

for(i in 1:5){
  
terrain_image %>% 
  #add_water(detect_water(elmat, min_area = 50, remove_edges = FALSE), color="imhof4") %>%
  add_shadow(ray_shade(elmat,zscale=5,maxsearch = 300),0.7) %>%
 plot_3d(elmat,zscale=10,fov=0,theta=40,zoom=0.75,phi=50, windowsize = c(1000,800),
          water = T, waterdepth = i, wateralpha = 0.5)

}
rgl.close()

#### plot at once #####

library(magick)
images = list.files(path = "~/git/knots/knots_texts/", pattern = "tidal_landscape", full.names = T) %>% map(image_read)

par(mfrow = c(3,2))
for(i in 1:6){
  plot(as.raster(images[[i]]))
}