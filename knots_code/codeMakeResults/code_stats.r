#### code for models ####

library(data.table); library(tidyverse)
library(lme4)

#### load data ####
# read mcp and dist data
data <- fread("../data2018/dataMCParea.csv")
setDF(data)

# read number of fixes
recPrepFiles <- list.files("../data2018/oneHertzData/recursePrep/", full.names = T)

# read in data and ask how many rows
recPrepData <- map_df(recPrepFiles, function(z){
  fread(z)[,.N,by=list(id, tidalcycle)]
})

#save to file
fwrite("../data2018/data2018idTideCount.csv")

data <- merge(data, recPrepData, all = FALSE, no.dups = TRUE)

#### run coarse scale area and distance models ####
library(lme4)

modsCoarse <- map(c("totalDist", "mcpArea"), function(z){
  lmer(data[,z] ~ exploreScore + log(N) + (1|id) + (1|tidalcycle), data = data)
}) %>% `names<-`(c("totalDist", "mcpArea"))

# get model summary
map(modsCoarse, summary)

# get p values whatever they're worth
map(modsCoarse, car::Anova)

#### prep for plotting ####
# get summary, all in KILOMETRES OR KM^2
dataSummary = data %>% 
  mutate(mcpArea = mcpArea/(1e3*1e3), totalDist = totalDist/1e3,
         exploreBin = plyr::round_any(exploreScore, 0.2)) %>% 
  select(totalDist, mcpArea, exploreBin) %>% 
  gather(variable, value, -exploreBin) %>% 
  group_by(exploreBin, variable) %>% 
  summarise_at(vars(value), list(~mean(.), ~ci(.)))

# plot
ggplot(dataSummary)+
  geom_pointrange(aes(x = exploreBin, y = mean, ymin=mean-ci, ymax=mean+ci))+
  facet_wrap(~variable, scales = "free")+
  scale_x_continuous(breaks = unique(dataSummary$exploreBin))+
  themePubLegKnots()+
  labs(x = "exploration score", y = bquote("mean ± 95% CI (km or km"^2~")"))

# save plot
ggsave(filename = "../figs/figMCPareaExploreScore.pdf", height = 3, width = 6)