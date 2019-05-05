#### script to assign tidal cycles and print summary ####

# load libs
library(tidyverse); library(readr)

# read in master data file
data2018 = read_csv("../data2018/data2018cleanPreRelease.csv")

#### bind all and count positions per bird ####
library(lubridate)
# bind rows
data2018 = bind_rows(data2018) %>%
  group_by(id) %>%
  mutate(timeNum = time, time = as.POSIXct(timeNum, origin = "1970-01-01"), week = week(time))

#### assign a tidal interval ####
# read in tidal interval data
tides = read_csv("../data2018/tidesSummer2018.csv") %>%
  filter(tide == "H")

# assign a tidal cycle to each position
# use only low tides
# first, nest into each individual dataframe
data2018 = data2018 %>%
  filter(!is.na(id)) %>%
  group_by(id) %>% nest()

# to each df, join the tidal interval frame
# then get the high tide interval
data2018$data = map(data2018$data, function(x){
full_join(x, tides, by = "time") %>% # join the tidal times df
    arrange(time) %>% # sort by time
  mutate(tide = ifelse(is.na(level), "other", tide),
         tidalCycle = cumsum(tide == "H")) %>% # assign tidal cycle
    ungroup() %>%
    group_by(tidalCycle) %>%
    mutate(timeToHiTide = difftime(time, min(time), units = "mins")) %>%
    filter(!is.na(x)) # get time to high tide and remove tidal times
})

# bind the list to a single df and correct for excess tidal cycles
data2018 = unnest(data2018) %>%
  mutate(tidalCycle = tidalCycle - min(tidalCycle) + 1)

# write data to file
write_csv(data2018, path = "../data2018/data2018posWithTides.csv")

#### plot proportion of actual/expected points ####
# get the actual/expected ratio in each tidal cycle
library(lubridate)
dataSummary = data2018 %>%
  ungroup() %>%
  group_by(id, tidalCycle) %>%
  #filter(timeFromHiTide >= 3*60, timeFromHiTide <= 9*60) %>%
  summarise(fixes = length(timeNum),
            duration = as.numeric(difftime(max(time), min(time),
                                                         units = "mins")),
            propFixes = fixes/(duration*6),
            propDur = duration/(13*60),
            tagWeek = min(week), timeStart = min(time), timeStop = max(time)) %>%
  filter(propFixes < 1.01)


# now plot as a mosaic
source("codePlotOptions/ggThemePub.r")
ggplot(dataSummary)+
  geom_tile(aes(tidalCycle, factor(id)), fill = "grey70")+
  #geom_point(aes(day, factor(id), fill = ifelse(n/8640 >= 0.2, NA, 1)),
  #size = 0.2, show.legend = F)+
  geom_tile(aes(tidalCycle, factor(id), fill = propFixes, alpha = propDur))+


  scale_fill_gradientn(colours = rev(viridis::magma(120)),
                       values = c(0.2, 1),
                       name = "prop.",
                       na.value = "grey")+
  ylab("Bird id")+ xlab("Tidal cycles")+
  ggtitle("Proportion of expected positions")+
  themePubLeg()

# export as pdf
ggsave(filename = "../figs/figureFixesPropPerDay2018.pdf",
       device = pdf(), width = 210, height = 297, units = "mm", dpi = 300);
dev.off()

#### export data on which tides are good ####
write_csv(dataSummary, path = "../data2018/dataSummary2018.csv")
