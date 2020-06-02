#' ---
#' editor_options: 
#'   chunk_output_type: console
#' ---
#' 
#' # Bathymetry of the Griend mudflats
#' 
#' ## Get data and plot basic trend
#' 
## ----load_libs_s01-------------------------------------
# load libs to read bathymetry
library(raster)
library(rayshader)
library(sf)

# data libs
library(data.table)
library(purrr)
library(stringr)

# plot libs
library(ggplot2)
library(ggthemes)

#' 
## ----load_data_s01-------------------------------------
# load bathymetry and subset
data <- raster("data/bathymetry_waddenSea_2015.tif")
griend <- st_read("griend_polygon/griend_polygon.shp") %>% 
  st_buffer(10.5e3)

# assign utm 31 crs and subset
crs(data) <- unlist(st_crs(griend)[2])
data <- crop(data, as(griend, "Spatial"))
data <- aggregate(data, fact = 2)
# remove 20m outliers
#data[data > 500] <- NA
data_m <- raster_to_matrix(data)

# get quantiles of the matrix
data_q <- quantile(data_m, na.rm = T, probs = 1:1000/1000)

#' 
## ----load_waterlevel_s01-------------------------------
# read in waterlevel data
waterlevel <- fread("data/data2018/waterlevelWestTerschelling.csv", sep = ";")

# select useful columns and rename
waterlevel <- waterlevel[,.(WAARNEMINGDATUM, WAARNEMINGTIJD, NUMERIEKEWAARDE)]

setnames(waterlevel, c("date", "time", "level"))

# make a single POSIXct column of datetime
waterlevel[,dateTime := as.POSIXct(paste(date, time, sep = " "), 
                                   format = "%d-%m-%Y %H:%M:%S", tz = "CET")]

waterlevel <- setDT(distinct(setDF(waterlevel), dateTime, .keep_all = TRUE))

#' 
## ----plot_bathymetry_quantiles-------------------------
# plot waterlevel quantiles with data from west terschelling
waterlimits <- range(waterlevel$level)

fig_waterlevel_area <- ggplot()+
  geom_line(aes(x = 1:1000/1000, y = data_q))+
  geom_hline(yintercept = waterlimits, col = "blue", lty = 2)+
  geom_hline(yintercept = 0, lty = 2, col = "red")+
  scale_x_continuous(labels = scales::percent)+
  theme_bw()+
  coord_flip(xlim = c(0.25, 1.01), ylim = c(-250, 250))+
  labs(x = "% area covered", y = "waterlevel (cm over NAP)")

ggsave(fig_waterlevel_area, filename = "figs/fig_waterlevel_area.png",
       dpi = 300, height = 4, width = 6); dev.off()

#' 
#' ## Plot as 3D maps
#' 
## ----make_water_seq------------------------------------
# make sequence
waterdepth <- seq(waterlimits[1], waterlimits[2], length.out = 30)
waterdepth <- c(waterdepth, rev(waterdepth))

#' 
#' 
## ----vis_data------------------------------------------
# make visualisation
for(i in 1:length(waterdepth)) {
  data_m %>%
    sphere_shade(texture = "imhof1", zscale = 50) %>%
    # add_water(detect_water(data_m, zscale = 100, 
    #                        max_height = waterdepth[i],cutoff = 0.1), 
    #           color = "desert") %>%
    add_shadow(hillshade = data_m) %>%
    plot_3d(data_m, zscale = 75, wateralpha = 0.6,
            solid =F, shadow=F,
            water = TRUE,
            waterdepth = waterdepth[i],
            watercolor = "dodgerblue1",
            phi = 90,
            theta = 0, zoom = 0.75, windowsize = c(1000, 800),
            background = "black", calculate_normals = F)
  render_label(data_m, x = 500, y = 500, z = 500,
               text = glue::glue('waterdepth = {round(waterdepth[i])} cm'), 
               freetype = F, textcolor = "black")
    
  rgl::snapshot3d(paste0("figs/tide_rise/fig",str_pad(i, 2, pad = "0"),".png"))
  rgl::rgl.close()
}

#' 
## ----make_tide_gif-------------------------------------
library(magick)
list.files(path = "figs/tide_rise/", pattern = "*.png", full.names = T) %>% 
  map(image_read) %>% # reads each path file
  image_join() %>% # joins image
  image_animate(fps=2) %>% # animates, can opt for number of loops
  image_write("figs/fig_tide_rise_anim.gif") # write to current dir

#' 
#' 
## ----include_gif, eval=TRUE, fig.cap="Waterlevel at West Terschelling and effect on coverage of mudflats around Griend."----
if (knitr:::is_latex_output()) {
  
} else {
  knitr::include_graphics("figs/fig_tide_rise_anim.gif")
}

#' 
