#### code to explore first passage time ####

#'load libs
library(readr); library(dplyr); library(tidyr)

#'load data
data = read_csv("../data2018/data2018WithRecurse.csv")
#'count the number of unique id-tide combos
count(data, id, tidalCycle)

#'load good data summary, check if same number of id-tides present
goodData = read_csv("../data2018/goodData2018.csv")

#### load explore score data ####
explData = read_csv("../data2018/behavScores.csv")

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

dataRevDay = left_join(dataRevDay, explData)

#'get tagging week
dataTagWeek = data %>% 
  group_by(id) %>% 
  summarise(tagWeek = lubridate::week(min(time)))
#'add tagweek to datarevday
dataRevDay = left_join(dataRevDay, dataTagWeek)

#'load time difference
dataTimeDiff = read_csv("../data2018/timeDiffRelease2018.csv")

#'add timelag to release to revisit summary
dataRevDay = left_join(dataRevDay, dataTimeDiff)

#'plot distr over 2 day intervals
ggplot(dataRevDay %>% 
         filter(variable != "fpt"))+
  geom_histogram(aes(x = value, fill = day2, group = day2), col = drkGry, 
                 size = 0.3, position = "stack")+
  scale_fill_gradientn(colours = (colorspace::terrain_hcl(16)),
                    name = "tidal \ncycle \nbin")+
  facet_wrap(~variable, scales = "free")+
  xlab("minutes / # times")+
  themePubLeg()+
  ggtitle("Fig. 2. Space use metrics distribution: Bins 8 tidal cycles (~2 days)")

#'save to file
ggsave(filename = "../figs/figFPT8tideBin.pdf", 
       device = pdf(), width = 210, height = 80, units = "mm"); dev.off()

#### plot revisit over time ####
ggplot(dataRevDay %>% 
         filter(!tagWeek %in% c(34,39)))+
  geom_jitter(aes(day2*13, value, col = timeDiff,
                  #shape = !is.na(exploreScore)
                  ))+
  scale_colour_gradientn(colours = pals::brewer.gnbu(9),
                        limits = c(-100, NA),
                        na.value = altRed)+
  # scale_colour_manual(values = c(stdRed, drkGry),
  #                     name = "Tent \nexplore \nscore \ntested?")+
  # scale_shape_manual(values = c(1, 16),
  #                     name = "Tent \nexplore \nscore \ntested?")+
  facet_grid(variable~tagWeek, scales = "free_y")+
  scale_x_continuous(breaks = 13*seq(0, 120, 20))+
  themePubLeg()+
  xlab("# tidal cycle")+ ylab("# visits / minutes / minutes")+
  ggtitle("Fig. 1. Space use metrics ~ time in 8 tidal cycle bins")

#'save to file
ggsave(filename = "../figs/figSpaceUseTime.pdf", 
       device = pdf(), width = 210, height = 125, units = "mm"); dev.off()

#### relate first fpt with release-transmit diff ####
dataRevDay %>% 
  filter(!tagWeek %in% c(34,39), variable == "fpt") %>% 
  group_by(id) %>% 
  filter(day2 == min(day2), timeDiff >= -150) %>% 
  ggplot()+
  geom_point(aes(x = timeDiff, y = value), col = drkGry)+
  geom_smooth(aes(x = timeDiff, y = value), col = altBlu, method = "glm",
              fill = stdGry)+
  geom_hline(yintercept = c(0, 48), lty = 2, lwd = 0.2, col = rep(c(1, 2), 3))+
  geom_vline(xintercept = 0, lwd = 0.2, col = 2)+
  facet_grid(~tagWeek, scales = "free_x")+
  themePub()+
  labs(x = "first posn. time - release time (hrs)",
            y = "first passage time (hrs)")

#'save to file
ggsave(filename = "../figs/figTimelagReleaseFPT.pdf", 
       device = pdf(), width = 210, height = 100, units = "mm"); dev.off()
