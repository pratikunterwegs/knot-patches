getwd()

library(tidyverse); library(readr)

data = read_csv("movement_model/data_sim.csv")

library(ggthemes); library(extrafont)

png(filename = "movement_model/fig2_elev_time.png", width = 800, height = 300, res = 150)
data %>% filter(iteration == 1, sim == 1) %>% 
  ggplot()+
  geom_path(aes(x = time, y = elev, group = factor(id)), size = 0.1)+
  geom_line(data = data_frame(a = 1:780/2, b = (-4*0.8*(1:780/780 - 0.5)^2)+0.8), aes(x = a, y = b), col = 2, size = 1)+
  theme_tufte(base_family = "serif")+
  labs(list(x = "Time since low tide (mins)", y = "Height"))+
  facet_wrap(~sim)
dev.off()


#### plot figure 3 ####
library(RColorBrewer)

fig3b = data %>% group_by(id, land_autocorr, iteration) %>% 
  summarise(totin = last(totalIntake), dist = sum(stepLength)) %>% 
  ggplot()+
  stat_density(aes(x = dist, group = land_autocorr, col = land_autocorr), size = 0.4, position = "identity", geom = "line")+
  theme_tufte()+
  labs(list(x = "Total distance travelled (grid units)", y = "Density", title = "(b)"))+
  theme(legend.position = "none")

fig3a = data %>% group_by(id, land_autocorr, iteration) %>% 
  summarise(totin = last(totalIntake), dist = sum(stepLength)) %>% 
  ggplot()+
  geom_density(aes(x = totin, group = land_autocorr, fill = land_autocorr), alpha = 0.5,size = 0.4, position = "identity")+
  theme_tufte()+
  scale_fill_gradientn(colours = brewer.pal(9,"RdBu"))+
  labs(list(x = "Net intake (food units)", y = "Density", title = "(a)"))+
  theme(legend.position = "none")

library(gridExtra)

png(filename = "movement_model/fig3_metrics_autocorr.png", width = 800, height = 300, res = 150)
grid.arrange(fig3a, fig3b, nrow = 1)
dev.off()
