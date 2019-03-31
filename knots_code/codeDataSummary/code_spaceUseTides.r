#### code to get home ranges ####

#'NB: is there really a space-use metric that can be called a
#'home range for a wintering wader? up for debate.
#'
#'further, what space use should be considered?
#'during the foraging period? overall?
#'how is the true foraging period to be found? using behavioural classification?
#'using waterlevel and bathymetry?
#'
#'this code calculates space use as:
#'1. dynamic browning bridges
#'2. in the foraging period: 3 - 10 hours post high tide
#'3. for cases when 3 - 10 hours post high tide is daylight hours.


#### load libs ####
library(tidyverse); library(readr)

#'load position data
data = read_csv("../data2018/data2018posWithTides.csv")
#'load summary data
dataSummary = read_csv("../data2018/dataSummary2018.csv")

#'filter for data where greater than 33% positions are available,
#'and putative foraging periods 3 - 10 hrs post high tide
goodData = dataSummary %>% filter(propFixes >= 0.33)
data = data %>% 
  filter(id %in% goodData$id, tidalCycle %in% goodData$tidalCycle) %>% 
  filter(between(timeFromHiTide, 3*60, 10*60))

#### separate into lists per id and tidal cycle ####
#'summarise the foraging period data
dataForageSummary = group_by(data, id, tidalCycle) %>% 
  #filter(timeFromHiTide >= 3*60, timeFromHiTide <= 9*60) %>% 
  summarise(fixes = length(timeNum), 
            duration = as.numeric(difftime(max(time), min(time),
                                           units = "mins")),
            propFixes = fixes/(duration*6*60),
            tagWeek = min(week), timeStart = min(time), timeStop = max(time)) %>% 
  filter(duration > 7*0.33*60)

#'plot foraging summary
#'source plot function
source("codePlotOptions/ggThemePub.r")
ggplot(dataForageSummary)+
  #geom_point(aes(day, factor(id), fill = ifelse(n/8640 >= 0.2, NA, 1)), 
  #size = 0.2, show.legend = F)+
  geom_tile(aes(tidalCycle, factor(id), fill = propFixes))+
  
  scale_fill_gradientn(colours = rev(colorspace::terrain_hcl(120)), 
                       values = c(0.2, 1), 
                       name = "prop.", 
                       na.value = "grey")+
  ylab("Bird id")+ xlab("Tidal cycles")+
  ggtitle("Proportion of expected positions")+
  themePubLeg()

ggsave(filename = "../figs/figureFixesPropForage2018.pdf", 
       device = pdf(), width = 210, height = 297, units = "mm", dpi = 300); 
dev.off()

#### dynamic brownian bridges ####
#'get dynamic brownian bridges
library(move)
data = data %>% arrange(id, time)
#'convert each individual id to move, exclude larger data
dataMove = move(x = data$x, y = data$y,
                time = data$time, data = as.data.frame(data),
                proj = "+proj=utm +zone=31 +ellps=WGS84 +datum=WGS84 +units=m +no_defs",
                animal = data$id)
dataMove = split(dataMove)

#'pass this movestack to dynBBMM
#'choose a 'raster' size of 100 map units, here metres
forageDBMM = list()

for(i in 1:length(dataMove)){
  forageDBMM[[i]] = brownian.bridge.dyn(dataMove[[i]], raster = 1000,
                        location.error = abs(dataMove[[i]]$covxy),
                        ext = 5)
}
