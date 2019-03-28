#### script to make summary stats 2018 tracking data ####

#'load libs
library(tidyverse); library(readr)

#'list all 2018 csv data files
data2018names = list.files("../data2018/", pattern = c("data_", ".csv"), full.names = T)

#'get filesizes
sapply(data2018names, file.size, USE.NAMES = F)/1e6

#### bind all and count positions per bird ####
#'read all data
data2018 = lapply(data2018names, read_csv)
#'assert that the right number of files were read
assertthat::assert_that(length(data2018) == 14)

library(lubridate)
#'bind rows
data2018 = bind_rows(data2018) %>% 
  group_by(id) %>% 
  mutate(timeNum = time, time = as.POSIXct(timeNum, origin = "1970-01-01"), week = week(time))

#### assign a tidal interval ####
#'read in tidal interval data
tides = read_csv("../data2018/tidesSummer2018.csv") %>% 
  filter(tide == "H")

#'assign a tidal cycle to each position
#'use only low tides
#'first, nest into each individual dataframe
data2018 = data2018 %>% 
  filter(!is.na(id)) %>% 
  group_by(id) %>% nest()

#'to each df, join the tidal interval frame
#'then get the high tide interval
data2018$data = map(data2018$data, function(x){
full_join(x, tides %>% filter(tide == "H"), by = "time") %>% 
    arrange(time) %>% 
  mutate(tide = ifelse(is.na(level), "other", tide),
         tidalCycle = cumsum(tide == "H")) %>% 
    filter(tide == "other")
})

#'bind the list to a single df
data2018 = unnest(data2018) %>% 
  mutate(tidalCycle = tidalCycle - min(tidalCycle))

#'make list column by nesting again
data2018 = group_by(data2018, id) %>% 
  nest()

#'map on each df to get time to high tide
data2018 = data2018 %>% 
  mutate(data = map(data, function(x){
    #'arrange each df by time
    arrange(x, time) %>% 
      #'group by tidalCycle
      group_by(tidalCycle) %>% 
      mutate(timeFromHiTide = as.numeric(time - min(time))) %>% 
      ungroup()
      
  }))

#'unnest the data
data2018 = unnest(data2018)

#'write data to file
write_csv(data2018, path = "../data2018/data2018posWithTides.csv")

#### plot proportion of actual/expected points ####
#'get the actual/expected ratio in each tidal cucle 
library(lubridate)
dataSummary = data2018 %>% 
  group_by(id, tidalCycle) %>% 
  #filter(timeFromHiTide >= 3*60, timeFromHiTide <= 9*60) %>% 
  summarise(fixes = length(timeNum), 
            duration = as.numeric(difftime(max(time), min(time),
                                                         units = "mins")),
            propFixes = fixes/(duration*6),
            tagWeek = min(week), timeStart = min(time), timeStop = max(time)) %>% 
  filter(propFixes < 1.01)


library(colorspace); library(RColorBrewer)
#'now plot
ggplot(dataSummary)+
  #geom_point(aes(day, factor(id), fill = ifelse(n/8640 >= 0.2, NA, 1)), 
  #size = 0.2, show.legend = F)+
  geom_tile(aes(tidalCycle, factor(id), fill = propFixes))+
  
  scale_fill_gradientn(colours = rev(heat_hcl(120)), 
                       values = c(0.2, 1), 
                       name = "prop.", 
                       na.value = "grey")+
  ylab("Bird id")+ xlab("Tidal cycles")+
  ggtitle("Proportion of expected positions")+
  theme_bw()+
  theme(panel.border = element_blank(),
        panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        axis.ticks = element_blank(),
        axis.text.y = element_text(size = 4))

#'export as png
ggsave(filename = "../figs/figureFixesPropPerDay2018.pdf", 
       device = pdf(), width = 210, height = 297, units = "mm", dpi = 300); 
dev.off()


