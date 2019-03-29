#### code for population level repeatability in movement ####

library(readr)

#'read in data with movement
data = read_csv("../data2018/data2018withDistances.csv")

#'summarise total distance per tide
library(tidyverse)
dataSummary = data %>%
  group_by(id, tidalCycle) %>%
  summarise(nFixes = length(distance),
            distPerTide = sum(distance, na.rm = T),
            durHrs = (max(timeNum) - min(timeNum))/3600,
            propFixes = nFixes*10/(max(timeNum) - min(timeNum)))


#'count propFixes below 0.33
count(ungroup(dataSummary), goodFix = propFixes >= 0.33) %>%
  ggplot()+
  geom_col(aes(x = goodFix, y = n, fill = goodFix))

#'remove id - tidalCycle combinations below 0.5 fix prop
dataSummary = filter(dataSummary, propFixes >= 0.33)

#'plot distance per tide scaled by propFixes
#'source plot theme
source("codePlotOptions/ggThemePub.r")
library(pals)

ggplot(dataSummary %>% 
         filter(propFixes <= 1.0))+
  geom_tile(aes(x = tidalCycle, y = factor(id), fill = distPerTide/1e3))+
  scale_fill_gradientn(colours = rev(pals::magma(120)),
                       name = "km per tide",
                       limits = c(0, 100))+
  themePubLeg()+
  guides(fill = guidePub)

#'which ids remain?
idsWanted = tibble(id = unique(dataSummary$id)) %>%
  mutate(rowNum = 1:nrow(.)) %>%
  select(rowNum, id)

#### get population repeatability ####

library(lme4)

modDistId = glmer(round(distPerTide) ~ durHrs + propFixes + (1|id) + (1|tidalCycle),
                 data = dataSummary, family = "poisson")

summary(modDistId)

#### function for repeatability ####
source("codeDataSummary/functionGetRepeatability.r")

