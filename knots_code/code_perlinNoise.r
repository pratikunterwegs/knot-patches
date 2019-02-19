perlin_noise <- function( 
  n = 5,   m = 5,    # Size of the grid for the vector field
  N = 1e2, M = 1e2   # Dimension of the image
) {
  # For each point on this n*m grid, choose a unit 1 vector
  vector_field <- apply(
    array( rnorm( 2 * n * m ), dim = c(2,n,m) ),
    2:3,
    function(u) u / sqrt(sum(u^2))
  )
  f <- function(x,y) {
    # Find the grid cell in which the point (x,y) is
    i <- floor(x)
    j <- floor(y)
    stopifnot( i >= 1 || j >= 1 || i < n || j < m )
    # The 4 vectors, from the vector field, at the vertices of the square
    v1 <- vector_field[,i,j]
    v2 <- vector_field[,i+1,j]
    v3 <- vector_field[,i,j+1]
    v4 <- vector_field[,i+1,j+1]
    # Vectors from the point to the vertices
    u1 <- c(x,y) - c(i,j)
    u2 <- c(x,y) - c(i+1,j)
    u3 <- c(x,y) - c(i,j+1)
    u4 <- c(x,y) - c(i+1,j+1)
    # Scalar products
    a1 <- sum( v1 * u1 )
    a2 <- sum( v2 * u2 )
    a3 <- sum( v3 * u3 )
    a4 <- sum( v4 * u4 )
    # Weighted average of the scalar products
    s <- function(p) 3 * p^2 - 2 * p^3
    p <- s( x - i )
    q <- s( y - j )
    b1 <- (1-p)*a1 + p*a2
    b2 <- (1-p)*a3 + p*a4
    (1-q) * b1 + q * b2
  }
  xs <- #raster[,1]*5
   seq(from = 1, to = n, length = N+1)[-(N+1)]
  ys <- #raster[1,]*7
   seq(from = 1, to = m, length = M+1)[-(M+1)]
  outer(xs, ys, Vectorize(f) )
}

#### export images for spatial fig ####
seasons1 = perlin_noise()
image(seasons1, col = colorspace::terrain_hcl(120))
seasons2 = perlin_noise()
image(seasons2, col = colorspace::terrain_hcl(120))

spatialPlots = list(seasons1, seasons2) %>% 
  map(matrixToDf)
for(i in 1:length(spatialPlots)) spatialPlots[[i]]$id = i
spatialPlots = bind_rows(spatialPlots) %>% 
  mutate(id = ifelse(id == 1, "A: small patch size", "B: Large patch size"))

#### make spatial plots ####
spatialPatches = ggplot()+
  geom_tile(data = spatialPlots, aes(x = col, y = row, fill = val))+
  facet_wrap(~id)+
  scale_fill_gradientn(colours = colorspace::terrain_hcl(120))+
  theme_pub()+
  theme(legend.position = "none")+
  coord_equal(expand = F)+
  labs(list(x = "X coordinate", y = "Y coordinate"))
#'export
ggsave(filename = "plotSpatialPatchesGRC.eps", width = 200, height = 125, units = "mm",
       device = cairo_ps()); dev.off()

#' get rasters
rasters = vector("list", 1e2+1)

#'make landscapes
for(i in 1:length(rasters)){
  if(i %% 2 != 0){
    rasters[[i]] = perlin_noise()
  }
}

#### spatial autocorrelation ####
library(ncf)
#'for low patch size
corrLowPatch = correlog.nc(x = 1:100, y = 1:100, z = seasons1, increment = 10)$correlation
plot(corrLowPatch)
#'high patch size
corrHighPatch = correlog.nc(x = 1:100, y = 1:100, z = seasons2, increment = 10)$correlation
plot(corrHighPatch)

#'make df
corrDf = tibble(id = rep(c("A: small patch size", "B: Large patch size"), each = 15),
                acr = c(corrLowPatch, corrHighPatch),
                range = rep(seq(0, 140, 10),2))

#'make plot
spatialACF = ggplot()+
  geom_path(data = corrDf, aes(x = range, y = acr))+
  geom_point(data = corrDf, aes(x = range, y = acr), shape = 16, size = 2)+
  geom_hline(yintercept = 0.1, col = 2, lty = 2, lwd = 0.2)+
  facet_wrap(~id)+
  theme_pub()+
  labs(list(x = "Distance (landscape units)", y = "Autocorrelation"))

#'export plot
#'export
ggsave(filename = "plotSpatialACFGRC.eps", width = 200, height = 70, units = "mm",
       device = cairo_ps()); dev.off()

#'interpolate
for(i in 1:length(rasters)){
  if(i %% 2 == 0){
    rasters[[i]] = (rasters[[i-1]] + rasters[[i+1]])/2
  }
}

#'make seasonal landscapes
seasons = vector("list", 1e2+1); seasons1 = perlin_noise(); seasons5 = perlin_noise(); seasons3 = (seasons1 + seasons5)/2; seasons4 = (seasons3 + seasons5)/2; seasons2 = (seasons1 + seasons3)/2
seasonsList = list(seasons1, seasons3, seasons5)

#'get sequence
seqSeas = rep(c(1:3, 3:1),30)
seqSeas = seqSeas[diff(seqSeas)!=0]

#'rasterSeasons now
rasterSeasons = seasonsList[seqSeas]

#'make custom function
matrixToDf = function(x) {as.data.frame(x) %>% `colnames<-`(1:ncol(.)) %>% mutate(row = 1:dim(.)[1]) %>% gather(col, val, -row) %>% mutate(col = as.numeric(col))
}

#'map df function across list
library(tidyverse)
rasters = map(rasters, matrixToDf)
rasterSeasons = map(rasterSeasons, matrixToDf)

#'assign id
for(i in 1:length(rasters)) rasters[[i]]$id = i
for(i in 1:length(rasterSeasons)) rasterSeasons[[i]]$id = i

#'bind rows
rasters = rasters %>% bind_rows() #%>% filter(id %% 2 == 0)
rasterSeasons = rasterSeasons %>% bind_rows()

#'random change in time
acfTime = rasters %>% 
  plyr::dlply(c("col", "row")) %>% 
  map(function(x){
   tibble(acf = c(acf(x$val, plot = F)$acf), col = unique(x$col), row = unique(x$row),
          time = 1:21)
  })

#'seasonal change acf in time
acfTimeSeason = rasterSeasons %>% 
  plyr::dlply(c("col", "row")) %>% 
  map(function(x){
    tibble(acf = c(acf(x$val, plot = F, lag.max = 20)$acf), col = unique(x$col), row = unique(x$row),
           time = 1:21)
  })

#'prep for plot
acfTimePlot = acfTime %>% 
  bind_rows()

#'prep seasonal plot
acfTimePlotSeason = acfTimeSeason %>% bind_rows()

#'plot random change acf
acfPlot = 
  ggplot()+
  
  geom_line(data = acfTimePlot[c(1:nrow(acfTimePlot)/1e2),],
              aes(x = time, y = acf, group = interaction(col, row)), lwd = 0.1,
              se = F, col = "grey70")+
  geom_smooth(data = acfTimePlot[c(1:nrow(acfTimePlot)/1e2),],
              aes(x = time, y = acf), col = 1)+
  geom_hline(yintercept = 0, lwd = 0.2, lty = 2, col = 2)+
  theme_pub()+
  coord_cartesian(expand = F, ylim = c(-0.5, 1.1))+
  labs(list(x = "Timesteps", y = "Autocorrelation"))

#seasonsPlot = 
  ggplot()+
  
  geom_line(data = acfTimePlotSeason[c(1:nrow(acfTimePlotSeason)/1e2),],
            aes(x = time, y = acf, group = interaction(col, row)), lwd = 0.1,
            se = F, col = "grey70")+
  geom_smooth(data = acfTimePlotSeason[c(1:nrow(acfTimePlotSeason)/1e2),],
              aes(x = time, y = acf), col = 1)+
  geom_hline(yintercept = 0, lwd = 0.2, lty = 2, col = 2)+
  theme_pub()+
  coord_cartesian(expand = F, ylim = c(-1.1, 1.1))+
  labs(list(x = "Timesteps", y = "Autocorrelation"))

#'export random as eps
ggsave(filename = "plotAcfTimeGRC.eps", acfPlot, device = cairo_ps(), height = 100, width = 200, units = "mm")

#'export seasons as eps
ggsave(filename = "plotAcfSeasonsGRC.eps", seasonsPlot, device = cairo_ps(), height = 100, width = 200, units = "mm")


