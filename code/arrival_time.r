## Do exploratory birds arrive earlier at clusters?

We predict that exploratory individuals arrive at a site before sedentary indviduals.

Patches are clustered into _time_chunks_ and into spatial _modules_ within each time chunk; these form spatio-temporal clusters. Within each time-chunk -- module combination, at each time-scale -- spatial scale combination, our prediction would hold only if exploratory birds were present in a cluster before sedentary birds. 
We expect that the starting point of the first patch (id-chunk-module specific `min(time_start)`) should negatively correlated with exploration score.

We further expect an effect of spatial scale [tbd what exactly] and an effect of the tidal cycle, and the season [tbd].

### Prepare start time data

```{r module_time_summary, eval=FALSE}
# join patch data to modules
modules <- left_join(modules, 
                     data %>% 
                       select(id, tide_number, patch, 
                              time_start,
                              time_end,
                              tidaltime_start,
                              waterlevel_start))
```

```{r bird_time_relative, eval=FALSE}
# what is the minimum time_start in each module, chunk, for each id
# at each scale
module_start_times <- modules %>% 
  ungroup() %>% 
  group_by(time_scale, spatial_scale, module, time_chunk, id) %>% 
  summarise(module_arrival = min(time_start),
            module_depart = max(time_end))

# what is the mean arrival tide for each module-timechunk across birds
module_start_times <- module_start_times %>% 
  ungroup() %>% 
  group_by(time_scale, spatial_scale, module, time_chunk) %>% 
  mutate(median_module_arrival = median(module_arrival),
         median_module_depart = median(module_depart),
         delta_module_arrival = module_arrival - median_module_arrival,
         delta_module_depart = module_depart - median_module_depart)

# get the mean arrival difference for each bird at each time and spatial scale
# module_start_times <- module_start_times %>% 
#   ungroup() %>% 
#   group_by(time_scale, spatial_scale, id) %>% 
#   summarise_at(vars(delta_module_arrival), list(~median(.)))
```

### Prepare exploration score

Add the exploration score to the module arrival data.

```{r link_personality_time, eval=FALSE}
# read in exploration score data
data_behav <- read_csv("data/data_2018_behav.csv")

# join to module time data
module_start_times <- module_start_times %>% 
  ungroup() %>% 
  inner_join(data_behav, by = "id")

# summarise over 0.1 increments of explore score
module_time_summary <- module_start_times %>%
  # mutate(exploreScore = plyr::round_any(exploreScore, 0.1)) %>%
  # mutate(gizzard_mass = plyr::round_any(gizzard_mass, 1)) %>%

  # calcualte rounded score wise mean and ci, also count
  group_by(time_scale, spatial_scale, gizzard_mass) %>% 
  summarise_at(vars(delta_module_depart), 
               list(~mean(./60), ~ci(./60))) %>%

  # remove NA values
  filter(!is.nan(gizzard_mass), !is.na(gizzard_mass))

```

### Figure: Arrival time differences

```{r plot_personality_time, eval=FALSE}
# plot by scale
#fig_timediff_module <- 
ggplot(module_time_summary, 
       aes(gizzard_mass, mean))+
  geom_hline(yintercept = 0, col = "red", lty = 2, size = 0.1)+
  # geom_vline(xintercept = 0, col = "red", lty = 2, size = 0.1)+

  geom_pointrange(aes(ymin = mean-ci, ymax = mean+ci),
                  size = 0.1, col = "grey40")+
  geom_smooth(method = "glm", lwd = 0.3)+
  # geom_jitter(size = 0.2, alpha = 0.2)+
  scale_y_continuous(trans=ggallin::pseudolog10_trans)+
  # geom_pointrange(aes(ymin = mean-ci, 
  #                     ymax = mean+ci),
  #                 shape = 21)+
  theme_test(base_size = 6)+
  facet_grid(time_scale~spatial_scale, 
             scales = "free_y",
             labeller = label_both, as.table = FALSE,
             switch = "both")+
  labs(x = "exploration score", y = "individual arrival - mean arrival (mins)")

# save figure
ggsave(fig_timediff_module, filename = "figs/fig_timediff_module.png", 
       dpi = 300, height = 5, width = 5)
```

## Arrival times over the tidal cycle

It is possible that the tidal stage -- high or low, advancing or receding, modulates module arrival times.

```{r get_tidal_time_per_module, eval=FALSE}
# overwrite data here
# find the mean tide since high tide (tidaltime) in each time chunk
module_start_times <- modules %>% 
  ungroup() %>% 
  group_by(time_scale, spatial_scale, time_chunk) %>% 
  mutate(waterlevel = median(waterlevel_start),
         
         # round the tidal time to the nearest 60 mins
         
         waterlevel = plyr::round_any(waterlevel, 50)) %>% 
  
  # beginning and ends of tide are unreliable, remove
  # filter(between(tidaltime, 240, 540)) %>% 
  ungroup()

# within this data, find the module-chunk-id specific delta arrival time
module_start_times <- module_start_times %>% 
  group_by(time_scale, spatial_scale, module, time_chunk, waterlevel, id) %>% 
  summarise(module_arrival = min(time_start)) %>% 
  
  ungroup() %>% 
  group_by(time_scale, spatial_scale, module, time_chunk, waterlevel) %>% 
  mutate(median_module_arrival = median(module_arrival),
         delta_module_arrival = module_arrival - median_module_arrival)
```

Add the exploration score to the module arrival data.

```{r link_personality_timev2, eval=FALSE}
# read in exploration score data
data_behav <- read_csv("data/data_2018_behav.csv")

# join to module time data
module_start_times <- module_start_times %>% 
  ungroup() %>% 
  inner_join(data_behav, by = "id")

# summarise over 0.1 increments of explore score
module_time_summary <- module_start_times %>%
  mutate(exploreScore = plyr::round_any(exploreScore, 0.1)) %>%

  # calcualte rounded score wise mean and ci, also count
  group_by(time_scale, spatial_scale, waterlevel, exploreScore) %>% 
  summarise_at(vars(delta_module_arrival), 
               list(~mean(./60), ~ci(./60))) %>%

  # remove NA values
  filter(!is.nan(exploreScore)) %>% 
  
  # remove scales 6 and 12
  filter(time_scale < 7)
```

Plot figure, adding the tidal time axis.

```{r add_tidal_time_axis, eval=FALSE}
ggplot(module_time_summary, 
       aes(exploreScore, mean,
           col = factor(time_scale)))+
  geom_hline(yintercept = 0, col = "black", lty = 2, size = 0.2)+
  geom_vline(xintercept = 0, col = "black", lty = 2, size = 0.2)+

  geom_point(aes(ymin = mean-ci, ymax = mean+ci),
                  size = 1.5,
                  position = position_dodge(width = 0.2))+
  geom_smooth(method = "glm", lwd = 0.3, se = F)+
  # geom_jitter(size = 0.2, alpha = 0.2)+
  scale_y_continuous(trans=ggallin::ssqrt_trans)+
  # geom_pointrange(aes(ymin = mean-ci, 
  #                     ymax = mean+ci),
  #                 shape = 21)+
  # theme_test(base_size = 6)+
  facet_grid(waterlevel~spatial_scale, 
             scales = "free_y",
             labeller = label_both, as.table = FALSE,
             switch = "both")+
  labs(x = "exploration score", y = "individual arrival - mean arrival (mins)",
       col = "time scale")
```

