#### code to test different distributions ####

# load libs
library(data.table)
library(tidyr); library(dplyr); library(purrr)

# source movement lib
source("codeMoveMetrics/functionEuclideanDistance.r")

# simple ci function
ci = function(x){
  qnorm(0.975)*sd(x, na.rm = T)/sqrt((length(x)))}

# read data
data <- fread("simMoveDiff/dataSimMoveDiff.csv") %>% 
  setDF() %>% 
  group_by(replicate, id, moveScale) %>% 
  nest() %>% 
  mutate(data = map(data, funcDistance)) %>% 
  unnest() %>%
  drop_na() %>% 
  group_by(moveScaleRound = round(moveScale)) %>% 
  summarise_at(vars(data), list(~mean(.), ~ci(.)))

# plot data
library(ggplot2)

ggplot(data)+
  geom_pointrange(aes(x=moveScaleRound, y=mean, ymin=mean-ci, ymax=mean+ci))+
  geom_abline(slope = 0.1)


