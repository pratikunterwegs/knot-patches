#### prep id wise, tide wise data ####

# load libs
library(tidyverse); library(readr)

# load basic summary data
dataSummary = read_csv("../data2018/dataSummary2018.csv")

# load distances travelled
dataDistSummary = read_csv("../data2018/data2018withDistances.csv")
dataDistSummary = group_by(dataDistSummary, id, tidalCycle) %>%
  summarise(distPerTide = sum(distance, na.rm = T))
gc()

# load roost proportions
dataRoosts = read_csv("../data2018/dataRoostProp.csv") %>%
  filter(roost %in% c("griend", "derichel")) %>%
  spread(roost, n, fill = 0) %>%
  select(-roostProp) %>%
  gather(roost, nPos, -id, -tidalCycle) %>%
  group_by(id, tidalCycle) %>%
  summarise(roostGriendProp = nPos[2]/sum(nPos)) # this is a hack

# join data
dataSummary = left_join(dataSummary,
                        left_join(dataDistSummary, dataRoosts))

#### add experimental scores ####
# read experimental exploration scores
dataBehav = read_csv("../data2018/behavScores.csv")
# join to summary data
dataSummary = left_join(dataSummary, dataBehav, by = "id")

# remove some data
rm(dataBehav, dataDistSummary, dataRoosts);gc()

#### plot summary stats ####
# get useful data structure
dataSummary = dataSummary %>%
  select(-tagWeek, -timeStart, -timeStop, -AGE, -SEX) %>%
  gather(variable, value, -id, -exploreScore, -tidalCycle)

# plot
source("codePlotOptions/ggThemePub.r")

ggplot(dataSummary)+
  geom_hex(aes(x = exploreScore, y = value), bins = 10)+
  facet_wrap(~variable, scales = "free")+
  themePubLeg()+
  scale_fill_gradientn(colours = rev(colorspace::heat_hcl(120)))+
  xlab("mean transformed exploration score")+
  ylab("variable value (relevant units)")+
  ggtitle("Various metrics ~ field exploration score 2018")

# export to file
ggsave(filename = "../figs/figVarsVsExploreScore.pdf",
       device = pdf(), width = 210, height = 200, units = "mm"); dev.off()
