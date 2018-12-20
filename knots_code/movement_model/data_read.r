getwd()

library(tidyverse); library(readr)

data = read_csv("movement_model/data_sim.csv")

ggplot()+
  geom_raster(data = landscape_df, aes(x = col, y = row, fill = val))+
  geom_contour(data = landscape_df, aes(x = col, y = row, z = val), binwidth = 0.2, col = 1, alpha = 0.2)+
  scale_fill_gradientn(colours = scico(10, palette = "oleron"), values = c(0,0.8,1))+
  #scale_fill_scico(palette = "oleron")+
  geom_point(data = data, aes(x = x, y = y, col = id, group = id), size = 1)+
  coord_equal()+
  scale_color_scico(palette = "berlin")+
  theme_void()+theme(legend.position = "none")
  #facet_wrap(~behav)

data %>% group_by(id) %>% 
  mutate(distance = cumsum(stepLength)) %>% 
  ggplot()+
  geom_point(aes(x = iteration, y = distance, col = factor(id)))

count(data, landOpen)

