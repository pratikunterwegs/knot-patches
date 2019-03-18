#### script to make summary stats 2018 tracking data ####

#'load libs
library(tidyverse); library(readr)

#'list all 2018 csv data files
data2018names = list.files("../data2018/", pattern = ".csv", full.names = T)

#'get filesizes
sapply(data2018names, file.size, USE.NAMES = F)/1e6

#### bind all and count positions per bird ####
#'read all data
data2018 = lapply(data2018names, read_csv)
#'bind rows
data2018 = bind_rows(data2018) %>% 
  group_by(id) %>% 
  mutate(timeNum = time, time = as.POSIXct(time, origin = "1970-01-01"),
         week = week(time))

#### assign a tidal interval ####
#'read in tidal interval data
tides = read_csv("../data2018/tidesSummer2018.csv")

#'assign a tidal cycle to each position
#'use only low tides
#'first, split into each individual dataframe
data2018 = data2018 %>% 
  filter(!is.na(id)) %>% 
  plyr::dlply("id")

#'to each df, join the tidal interval frame
data2018 = map(data2018, function(x){
full_join(x, tides, by = "time") %>% 
    arrange(time) %>% 
  mutate(tide = ifelse(is.na(level), "other", tide),
         tidalCycle = cumsum(tide == "L")) %>% 
    filter(tide == "other")
})

#'bind the list to a single df
data2018 = bind_rows(data2018) %>% 
  mutate(tidalCycle = tidalCycle - min(tidalCycle))

#'make list column
data2018 = group_by(data2018, id) %>% 
  nest()

#'map on each df to get time to low tide
data2018 = data2018 %>% 
  mutate(data = map(data, function(x){
    #'arrange each df by time
    arrange(x, time) %>% 
      #'group by tidalCycle
      group_by(tidalCycle) %>% 
      mutate(timeToLowTide = as.numeric(time - min(time))) %>% 
      ungroup()
      
  }))

#### get df of proportion of actual/expected points ####
library(lubridate)
dataSummary = data2018 %>% 
  group_by(id) %>% 
  mutate(timeNum = time, time = as.POSIXct(time, origin = "1970-01-01"),
         week = week(time)) %>% 
  summarise(fixes = length(timeNum), duration = max(time) - min(time),
            propFixes = fixes/((max(timeNum) - min(timeNum))/10),
            tagWeek = min(week), timeStart = min(time), timeStop = max(time))

#### visualise data as columns ####

ggplot(dataSummary)+
  geom_col(aes(x = reorder(id, fixes), y = fixes,
               fill = propFixes))+
  
  scale_fill_viridis_c()+
  #geom_hline(yintercept = 0.5, col = 1)+
  xlab("ids (omitted here)") + ylab("fixes")+
  theme_bw()+
  theme(axis.text.x = element_blank(),
        panel.border = element_blank(),
        legend.position = "top", panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        axis.ticks = element_blank())

ggsave("../figs/data2018propFixes.pdf", device = pdf(),width = 125,
       height = 80, units = "mm", dpi = 300); dev.off()

#### get fixes frequency over time ####
dataFreqDay = data2018 %>% 
  ungroup() %>% 
  mutate(day = yday(time) - min(yday(time)),
         tagWeek = min(week(time))) %>% 
  count(id, tagWeek, day) %>% 
  mutate(prop = n/8640)

library(colorspace); library(RColorBrewer)
#'now plot
ggplot(dataFreqDay)+
  #geom_point(aes(day, factor(id), fill = ifelse(n/8640 >= 0.2, NA, 1)), size = 0.2, show.legend = F)+
  geom_tile(aes(day, factor(id), fill = n/8640))+
  
  scale_fill_gradientn(colours = brewer.pal(9, "YlOrRd"), values = c(0.20, 0.5, 1), name = "prop.", na.value = "grey80", breaks = seq(0.2, 1, 0.2))+
  ylab("Bird id")+ xlab("Days since 16th Aug 2018 ")+
  ggtitle("Proportion of daily positions")+
  theme_bw()+
  theme(panel.border = element_blank(),
        panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        axis.ticks = element_blank(),
        axis.text.y = element_text(size = 4))

#'export as png
ggsave(filename = "../figs/figureFixesPropPerDay2018.pdf", device = pdf(), width = 210, height = 297, units = "mm", dpi = 300); dev.off()


