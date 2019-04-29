#### code to clean data by release date ####

#'load libs
library(tidyverse); library(readr)

#'list all 2018 csv data files
data2018names = list.files("../data2018/", pattern = c("data_", ".csv"), full.names = T)

#'get filesizes
sapply(data2018names, file.size, USE.NAMES = F)/1e6

#### bind all ####
#'read all data
data2018 = lapply(data2018names, read_csv)

# bind and split by id
data2018 = bind_rows(data2018)# %>% plyr::dlply("id")

# read in behavScores.csv
behavScores = read_csv("../data2018/behavScores.csv")

# left join by id on raw data
nOriginalRows = nrow(data2018)

data2018 = left_join(data2018, behavScores %>% select(id, Release_Date))

# check release time and difference to first fix
checkTagOnDate = group_by(data2018, id) %>% filter(time == min(time)) %>% 
  mutate(timeDiff = (time - as.numeric(Release_Date))/3600) # 3600 s/hr

# histogram of release-on lag
library(ggplot2)
source("codePlotOptions/ggThemePub.r")

ggplot()+
  geom_rect(aes(xmin = c(-700, 0), xmax = c(0, 50), ymin = 0, ymax = 45), 
            fill = c(litRed, litBlu), alpha = 0.3)+
  geom_histogram(data = checkTagOnDate,
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

# remove fixes before release and check how many
data2018 = data2018 %>% filter(time >= as.numeric(Release_Date))
print(paste(nOriginalRows - nrow(data2018), "rows of data removed"))

#### write data without pre-release fixes to file ####
write_csv(data2018, path = "../data2018/data2018cleanPreRelease.csv")
