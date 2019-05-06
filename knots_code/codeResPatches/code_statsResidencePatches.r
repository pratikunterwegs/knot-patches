#### code to examine residence patches ####

# load libs
library(tidyverse); library(readr)
source("codePlotOptions/ggThemePub.r")
# load data
dataFiles = list.files("../data2018/segmentation/", full.names = T)
# read data
data = map(dataFiles, read_csv)
# bind rows
data = bind_rows(data)

# separate id tide
data = data %>%
  mutate(id = substr(id.tide, 1, 3), tidalCycle = substr(id.tide, 5, 7))

# get summary of number and duration of segments
dataSummary = data %>%
  group_by(id, tidalCycle) %>%
  summarise(nSeg = length(unique(segment)))

# plot this
ggplot(dataSummary)+
  geom_histogram(aes(x = nSeg), col = 1, fill = stdGry, size = 0.2)+
  facet_wrap(~plyr::round_any(as.numeric(tidalCycle), 8))+
  themePub()+
  labs(x = "number of residence patches",
       y = "# movement tracks",
       title = "number of residence patches: tidal cycle bins (0 - 120)")

ggsave(filename = "../figs/figResPatchCountDistr.pdf",
       device = pdf(), width = 200, height = 200, units = "mm"); dev.off()

segLength = data %>%
  mutate(tidalCycleBin = plyr::round_any(as.numeric(tidalCycle), 8)) %>%
  group_by(id, tidalCycleBin, segment) %>%
  summarise(segLength = length(x))

# plot number of segments per tidal segments

ggplot(segLength)+
  geom_histogram(aes(x = segLength, y = ..ncount..),
               col = 1, fill = stdGry, size = 0.2)+
  facet_wrap(~tidalCycleBin, scales = "fixed")+
  xlim(0, 1e3)+
  themePub()+
  labs(x = "duration of residence (fixes, 1 fix = 10s)",
       y = "# residence patches",
       title = "distribution of duration of residence: tidal cycle bins (0 - 120) ")

# export to file
ggsave(filename = "../figs/figResPatchDurDistr.pdf",
       device = pdf(), width = 200, height = 200, units = "mm"); dev.off()
