#### code to make restime by time plots ####

# code to look at smoother effects on residence time based 
# patch classification

# data loading yet to happen

#### plot smoothed data ####
# plot restime over time with smoothed classifier
ggplot(data)+
  geom_point(aes(time, resTime, col = rollResTime), size = 0.1)+
  geom_hline(aes(yintercept = resTimeLimit), col = 2)+
  scale_y_log10()+
  facet_grid(resTimeLimit~tidalcycle, scales = "free_x")