getwd()

library(tidyverse); library(readr)

a = (0.8 - (0.4*cos((2*pi/780)*(1:7800)) + 0.4))

data = read_csv("movement_model/data_sim.csv")

library(ggthemes)
a = 1:7800; b = b = (0.9 - (0.45*cos((2*pi/780)*(1:7800)) + 0.45))
#png(filename = "movement_model/fig2_elev_time.png", width = 800, height = 300, res = 150)
data %>% group_by(id) %>% 
  mutate(vardir = c(zoo::rollapply(direction, var, fill = NA, width = 150))) %>% 
  ggplot()+
  geom_path(aes(x = time, y = vardir, col = factor(id)), size = 0.1)+
  geom_line(data = data_frame(a,b), 
                              aes(x = a, y = b), col = "dodgerblue")+
  geom_vline(xintercept = c(780 * (1:10)), col = 2)+
  theme_void()+
  labs(list(x = "Time since low tide (mins)", y = "Height"))
#dev.off()

data %>% #filter(iteration == 1, sim == 1) %>% 
  ggplot()+
  geom_path(aes(x = time, y = expectation, col = factor(id)), size = 0.1)+
  #geom_line(data = data_frame(a,b), aes(x = a, y = b), col = "dodgerblue")+
  geom_vline(xintercept = c(780 * (1:10)), col = 2)+
  labs(list(x = "Time since low tide (mins)", y = "expectation"))

data %>% filter(id == 1) %>% 
  ggplot()+
  geom_path(aes(x = x, y = y, col = totalIntake))+
  coord_equal()

#### plot figure 3 ####
library(RColorBrewer)

#fig3b = 
data %>% group_by(id, land_autocorr, iteration) %>% 
  summarise(totin = last(totalIntake), dist = sum(stepLength)) %>% 
  ggplot()+
  stat_density(aes(x = dist, group = land_autocorr, col = land_autocorr), size = 0.4, position = "identity", geom = "line")+
  labs(list(x = "Total distance travelled (grid units)", y = "Density", title = "(b)"))+
  theme(legend.position = "none")

#fig3a = 
  data %>% group_by(id, land_autocorr, iteration) %>% 
  summarise(totin = last(totalIntake), dist = sum(stepLength)) %>% 
  ggplot()+
  geom_density(aes(x = totin, group = land_autocorr, fill = land_autocorr), alpha = 0.5,size = 0.4, position = "identity")+
  scale_fill_gradientn(colours = brewer.pal(9,"RdBu"))+
  labs(list(x = "Net intake (food units)", y = "Density", title = "(a)"))+
  theme(legend.position = "none")

library(gridExtra)

png(filename = "movement_model/fig3_metrics_autocorr.png", width = 800, height = 300, res = 150)
grid.arrange(fig3a, fig3b, nrow = 1)
dev.off()
