getwd()

library(tidyverse); library(readr)

data = read_csv("data_sim.csv")

ggplot()+
  geom_raster(data = landscape_df, aes(x = col, y = row, fill = val))+
  scale_fill_scico(palette = "oleron")+
  geom_path(data = data, aes(x = x, y = y, col = factor(id)))+
  facet_wrap(~behav)
