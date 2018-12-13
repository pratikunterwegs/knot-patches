getwd()
setwd("~/git/cri_2018/")
#'load tidyverse
library(tidyverse)
#'load NLMR
library(NLMR)
#'load raster
library(raster)

#'make landscape
landscape = nlm_gaussianfield(ncol = 100, nrow = 100, autocorr_range = 2)
landscape_df = as.matrix(landscape) %>% as.data.frame() %>% 
  mutate(row = 1:nrow(.)) %>% gather(col, val, - row)

plot(landscape, col = viridis::plasma(50))
#'make matrix
landscape_csv = as.matrix(landscape)

#'write to csv
write_delim(as.data.frame(landscape_csv), path = "../cri_2018/landscape.csv", col_names = F, delim = " ")

#'read data
data = read_csv("data_sim.csv")

#### plot1 ~ movement tracks ####
#plot1 = 
  ggplot(data %>% filter(sim %in% 20:23), aes(x = iteration, y = expectation, col = factor(behav)))+
  geom_point(size = 0.3)+
  facet_wrap(~sim)+
  theme_void()+
  theme(panel.border = element_rect(fill = "transparent"),
        legend.position = "top")+
  labs(list(col = "behavioural type"))

#### plot 2 ~ distance vs strategy ####
plot2 = 
  data %>% 
  group_by(sim, id, behav) %>% 
  summarise(totaldist = sum(stepLength)) %>% 
  ungroup() %>% 
ggplot(aes(x = factor(behav), y = totaldist, fill = factor(behav)))+
  geom_boxplot(size = 0.3)+
  theme_void()+
  theme(panel.border = element_rect(fill = "transparent"),
        legend.position = "top")+
  labs(list(fill = "behavioural type"))

#### plot 3 ~ intake vs iteration ####
plot3 = data %>% 
  group_by(behav, it50 = plyr::round_any(iteration, 50)) %>% 
  summarise(totalIntake = mean(totalIntake)) %>% 
  ggplot()+
  geom_point(aes(x = interaction(factor(behav), it50), y = totalIntake, col = factor(behav)), size = 6)+
  theme_void()+theme(legend.position = "top", legend.background = element_rect(fill="transparent"))+
  labs(list(col = "behavioural type"))



ggplot(data %>% filter(sim %in% 250:300), aes(x = iteration, y = totalIntake, col = factor(behav)))+
  geom_smooth()+
  theme_bw()
  

ggplot(data %>% filter(sim == 50), aes(x = iteration, y = expectation))+geom_smooth(aes(col = factor(behav)))

ggplot(data,aes(x = expectation - sample, y = stepLength))+geom_point()

data2 = data %>% mutate(id = as.factor(id)) %>% 
  plyr::dlply("id") %>% 
  map(function(x){
    x %>% dplyr::select(x,y) %>% as.matrix()
  }) %>% 
  map(function(x){
    sp::spDists(x, segments = T)
  }) %>% 
  map(function(x){
    data_frame(distances = c(NA, x))
  })

data2 = bind_rows(data2)

ggplot(data2)+geom_histogram(aes(x = distances), bins = 150)+xlim(0,10)
