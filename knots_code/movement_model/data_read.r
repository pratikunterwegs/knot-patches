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

library(ggthemes); library(extrafont)

png(filename = "movement_model/fig2_elev_time.png", width = 800, height = 300, res = 150)
data %>% group_by(id) %>% 
  mutate(distance = cumsum(stepLength)) %>% 
  ggplot()+
  geom_path(aes(x = iteration, y = elev, group = factor(id)), size = 0.1)+
  geom_line(data = data_frame(a = 1:780, b = (-4*0.8*(1:780/780 - 0.5)^2)+0.8), aes(x = a, y = b), col = 2, size = 1)+
  theme_tufte(base_family = "serif")+
  labs(list(x = "Time since low tide (mins)", y = "Height"))
dev.off()

count(data, landOpen)

