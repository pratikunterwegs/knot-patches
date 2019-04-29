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

#'source plot ops
source("codePlotOptions/ggThemePub.r")

#'check how many obs in foraging period per tide per id
ungroup(data) %>% count(tidalCycle, foragePos = between(timeToHiTide, 3*60, 10*60)) %>% 
  group_by(tidalCycle) %>% 
  mutate(propForage = n/sum(n)) %>% 
  filter(foragePos == T) %>% 
  ggplot()+
  geom_hline(yintercept = (7/13), lty = 2, col = 2)+
  geom_path(aes(x = tidalCycle, y = propForage))+
  geom_point(aes(x = tidalCycle, y = propForage), shape = 16, size = 2, col = "white")+
  geom_point(aes(x = tidalCycle, y = propForage), shape = 16)+
  themePub()

#'export for reference
ggsave("../figs/propForagePerTide.pdf", device = pdf(), height = 125, width = 125, units = "mm", dpi = 150); dev.off()

#'filter for data where greater than 67% of duration is tracked, and
#'filter where > 33% of positions are logged
goodData = data %>% 
  ungroup() %>% 
  group_by(id, tidalCycle) %>% 
  filter(between(timeToHiTide, 3*60, 10*60)) %>% 
  summarise(forageDur = as.numeric(difftime(max(time), min(time), units = "mins")),
         propForageFixes = length(time)/(forageDur*6)) %>% 
  filter(forageDur >= 0.67*7*60,
         propForageFixes >= 0.33)

#'write to file for use
write_csv(goodData, path = "../data2018/goodForageData.csv")

#'retain good data for foraging periods
data = data %>% 
  filter(id %in% goodData$id, tidalCycle %in% goodData$tidalCycle) %>% 
  filter(between(timeToHiTide, 3*60, 10*60))

#### visualise foraging period data ####

#'plot foraging summary
ggplot(goodData)+
  #geom_point(aes(day, factor(id), fill = ifelse(n/8640 >= 0.2, NA, 1)), 
  #size = 0.2, show.legend = F)+
  geom_tile(aes(tidalCycle, factor(id), fill = propForageFixes))+
  
  scale_fill_gradientn(colours = rev(colorspace::terrain_hcl(120)), 
                       name = "prop.",
                       breaks = seq(0, 1, 0.25),
                       limits = c(0,1),
                       na.value = "grey")+
  ylab("Bird id")+ xlab("Tidal cycles")+
  ggtitle("Proportion of expected positions")+
  themePubLeg()

ggsave(filename = "../figs/figureFixesPropForage2018.pdf", 
       device = pdf(), width = 210, height = 297, units = "mm", dpi = 300); 
dev.off()

#### real metrics of space use ####
#'WORK IN PROGRESS
