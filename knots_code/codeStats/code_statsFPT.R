#### code to explore first passage time ####

#'load libs
library(readr); library(dplyr); library(tidyr)

#'load data
data = read_csv("../data2018/data2018WithRecurse.csv")
#'count the number of unique id-tide combos
count(data, id, tidalCycle)

#'load good data summary, check if same number of id-tides present
goodData = read_csv("../data2018/goodData2018.csv")

#'summarise data as means
dataRevSummary = mutate(data, hourHt = plyr::round_any(timeToHiTide, 120, floor)/60) %>% 
  group_by(id, tidalCycle, hourHt) %>% 
  summarise_at(vars(residenceTime, revisits, fpt), list(mean)) %>% 
  gather(variable, value, -id, -tidalCycle, -hourHt)

#### plot data ####
source("codePlotOptions/ggThemePub.r")
library(ggplot2)
ggplot(dataRevSummary)+
  geom_histogram(aes(x = value), col = drkGry, fill = stdGry, size = 0.3)+
  facet_grid(hourHt~variable, scales = "free")+
  xlab("minutes / minutes / # times")+
  themePub()

#'save to file
ggsave(filename = "../figs/figAvgFPTPerHour.pdf", 
       device = pdf(), width = 125, height = 125, units = "mm"); dev.off()

#### look at between tide differences ####
#'summarise data per tide over
dataRevDay = mutate(data, 
                    day2 = plyr::round_any(tidalCycle, 8)) %>% 
  group_by(id, day2) %>% 
  summarise_at(vars(residenceTime, revisits, fpt), list(mean)) %>% 
  gather(variable, value, -id, -day2)

#'plot trends over 2 day intervals
ggplot(dataRevDay %>% 
         filter(variable != "fpt"))+
  geom_histogram(aes(x = value, fill = day2, group = day2), col = drkGry, size = 0.3, position = "stack")+
  scale_fill_gradientn(colours = (colorspace::terrain_hcl(16)),
                    name = "tidal \ncycle \nbin")+
  facet_wrap(~variable, scales = "free")+
  xlab("minutes / # times")+
  themePubLeg()+
  ggtitle("Space use etrics distribution: Bins 8 tidal cycles (~2 days)")

#'save to file
ggsave(filename = "../figs/figFPT8tideBin.pdf", 
       device = pdf(), width = 210, height = 80, units = "mm"); dev.off()

#### load explore score data ####
explData = read_csv("../data2018/behavScores.csv")

dataRevSummary = left_join(dataRevSummary, explData)

#'explore plots
ggplot(dataRevSummary)+
  geom_density_2d(aes(x = exploreScore, y = value), contour = T)+
  facet_wrap(hourHt ~ variable, scales = "free", ncol = 3)+
  themePub()

#'export



#### make a revisit and residence raster ####
#'first get an extent object
library(raster)
extentGriend = raster::extent(c(xmin = min(data$x), xmax = max(data$x),
                          ymin = min(data$y), ymax = max(data$y)))
#'make an empty raster
emptyRaster = raster::raster(x = extentGriend, resolution = 100,
                             crs = CRS("+proj=utm +zone=31 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"),
                             vals = 0)

#'split data into per-id list
dataList = plyr::dlply(data, "id")

#'now make 3 rasters per id of summed revisits, residence, mean FPT

for(i in 1:2){
  a = dataList[[i]]
  dataList[[i]][[1]] = rasterize(x = as.matrix(a[c("x", "y")]),
                            y = emptyRaster,
                            field = a$revisits,
                            fun = "sum")
  dataList[[i]][[2]] = rasterize(x = as.matrix(a[c("x", "y")]),
                                 y = emptyRaster,
                                 field = c("revisits"),
                                 fun = "sum")
}
