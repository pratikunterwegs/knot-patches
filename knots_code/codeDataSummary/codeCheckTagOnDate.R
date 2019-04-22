#### code to check if tags on before release ####

library(readr); library(tidyr); library(dplyr)

#'load move data summary
dataSummary = read_csv("../data2018/dataSummary2018.csv") %>% 
  distinct(id, .keep_all = T)
#'load tagging data
behavData = read_csv("../data2018/behavScores.csv")
#'join the two
#'
dataSummary = left_join(dataSummary, behavData)

dataTimeDiff = select(dataSummary, id, timeStart, Release_Date) %>% 
  mutate(timeDiff = as.numeric(difftime(time2 = Release_Date, 
                                        time1 = timeStart, units = "hours")))

#'write to file
write_csv(dataTimeDiff, path = "../data2018/timeDiffRelease2018.csv")

#### histogram of release-on lag ####
library(ggplot2)
source("codePlotOptions/ggThemePub.r")

ggplot()+
  geom_rect(aes(xmin = c(-700, 0), xmax = c(0, 50), ymin = 0, ymax = 45), 
            fill = c(litRed, litBlu), alpha = 0.3)+
  geom_histogram(data = dataTimeDiff,
                 aes(x = timeDiff), col = drkGry, fill = stdGry,
                 bins = 50, lwd = 0.3)+
  geom_vline(xintercept = 0, col = 1, lty = 2, lwd = 0.2)+
  geom_text(aes(x = c(-200, 50), y = 20, 
                label = c("transmitting before release",
                          "transmitting after release")), angle = 90)+
  scale_x_continuous(breaks = c(seq(-150, 50, 50), -500, -600, -700))+
  themePub()+
  xlab("first position -- official release time (hrs)")+
#  xlim(-50, 600)+
  ylab("# birds")

#'export as png
ggsave(filename = "../figs/figTimeTagRelease.pdf", 
       device = pdf(), width = 125, height = 100, units = "mm", dpi = 300); 
dev.off()
