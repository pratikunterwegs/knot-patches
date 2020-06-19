# prepare network objects for assortnet via igraph
network_df <- mutate(network_df,
                     net = map2(data, id, function(e, n){
                       
                       # exclude edges with no vertex attributes
                       e <- filter(e, 
                                   id_x %in% n$id,
                                   id_y %in% n$id)
                       
                       tmp_net <- igraph::graph_from_data_frame(d = e,
                                                                directed = FALSE,
                                                                vertices = n)
                     }))

### Get assortativity

Remove networks with few (< 3) edges.

```{r}
# check which graphs are okay
network_df <- mutate(network_df, 
                     n_edges = map_int(net, function(n){
                       E(n) %>% length()
                     })) %>% 
  ungroup()

# remove bad graphs, ie, with fewer than 3 edges
# this is both for quality and practical reasons
min_edges <- 1
min_id <- 2
network_df <- filter(network_df, valid_graph > min_edges)
```

### Get assortativity

```{r}
# get weighred assortativity by gizzard mass
network_df <- mutate(network_df,
                     assort_metrics = purrr::map(net, function(n){
                       
  adj <- igraph::as_adjacency_matrix(n,
                                     sparse = FALSE,
                                     attr = "spatial_overlap_area")
                       
  assort_gizzard <- assortnet::assortment.continuous(adj, 
                                                     V(n)$gizzard_mass,
                                                     SE = TRUE)
                         
  # assort_behav <- assortnet::assortment.continuous(adj, 
  #                                                    V(n)$behav,
  #                                                    SE = TRUE)
  #                        
  # assort_mass <- assortnet::assortment.continuous(adj, 
  #                                                    V(n)$mass,
  #                                                    SE = TRUE)
  
  assortment <- map_df(list(assort_gizzard
                            # , assort_behav, assort_mass
                            ),
                       as_tibble) %>% 
    mutate(trait = c("gizzard"
                     # , "behav", "mass"
                     ))
                     }))
```

Unnest the data.

```{r}
# prepare the data
plot_df <- select(network_df, 
                  flock, id, valid_graph,
                  contains("assort")) %>% 
  filter(valid_graph > 1) %>% 
  
  # count flock size
  mutate(flock_size = map_int(id, nrow)) %>% 
  select(-id) %>% 
  pivot_longer(cols = contains("assort"))

# unnest
plot_df <- unnest(plot_df, "value")
```

## Visualise assortativity over space

### Link flock assortativity and patch data

```{r}
# subset network data
data_sp_assort <- select(network_df,
                         flock, n_edges,
                         id,
                         contains("assort"))

# add flock data to patch data
data_patches <- left_join(data_patches,
                          flock_id,
                          by = c("uid" = "patch"))

# get mean x, y and waterlevel for flocks
data_flock_attrs <- select(data_patches,
                           uid,
                           matches("(x|y|waterlevel)(_mean)"),
                           flock) %>% 
  filter(uid %in% flock_id$patch) %>% 
  group_by(flock) %>% 
  summarise_at(vars(contains("mean")),
               .funs = mean)

# add flock size
data_sp_assort <- data_sp_assort %>% 
  mutate(flock_size = map_int(id, nrow))

# join flock attributes to assort data and classify tide
data_sp_assort <- left_join(data_sp_assort,
                            data_flock_attrs) %>% 
  mutate(tide_stage = if_else(waterlevel_mean < 55, "low", "high"))

# melt data
data_sp_assort <- select(data_sp_assort,
                         -waterlevel_mean) %>% 
  pivot_longer(cols = contains("assort"))

# unnest data
data_sp_assort <- select(data_sp_assort, -name) %>% 
  unnest(cols = "value")
```

### Histogram of assortativity

```{r}
#fig_assort_hist <-
ggplot(data_sp_assort)+
  geom_histogram(aes(r, fill = tide_stage),
                 col = "black", lwd = 0.1,
                 binwidth = 0.1,
                 show.legend = F)+
  geom_text(data = tibble(pos = c(-1,0,1),
                          label = c(c("dissimilar\ntogether",
                                "random\nmixing",
                                "similar\ntogether"))),
            aes(pos, 150, label=label),
            size = 3,
            hjust = "inward",
            vjust = "inward")+
  scale_x_continuous(breaks = c(-1,0,1))+
  scale_fill_scico_d(palette = "broc",
                     begin = 0.2, end = 0.7)+
  theme_bw()+
  geom_vline(xintercept = 0, lty = 2)+
  facet_grid(tide_stage~trait, labeller = label_both)+
  labs(x = "assortativity",
       y = "% flocks")

ggsave(fig_assort_hist, filename = "figs/fig_assort_hist.png",
       dpi = 300, height = 4, width = 8)
```


### Plot assortativity vs flock size

```{r}
#fig_assortativity_flock_size <-
  ggplot(data_sp_assort)+
  geom_text(data = tibble(pos = c(-1,0,1),
                          label = c(c("dissimilar\ntogether",
                                "random\nmixing",
                                "similar\ntogether"))),
            aes(4, pos, label=label),
            size = 3,
            hjust = "inward",
            vjust = "inward")+
  geom_jitter(aes(flock_size, 
                 r,
                 alpha = se,
                 col = tide_stage),
             shape = 16,
             show.legend = F, width = 0.02)+
  geom_smooth(aes(flock_size, r),
              method = "glm",
              size = 0.5,
              col = "black")+
  geom_hline(yintercept = 0, lty = 2)+
  scale_colour_scico_d(palette = "broc",
                     begin = 0.1, end = 0.9)+
  facet_grid(tide_stage~trait, labeller = label_both)+
  scale_x_log10(breaks = c(seq(3,8,1), seq(10,30,10)))+
  theme_bw()+
  theme(panel.grid.minor = element_blank(),
        axis.text.y = element_text(angle = 90, hjust = "0.5"))+
  labs(x = "# unique individuals in flock",
       y = "assortativity")

ggsave(fig_assortativity_flock_size,
       filename = "figs/fig_assort_flock_size.png",
       dpi = 300)
```

### Plot assort in space

```{r}
# get griend
griend <- sf::st_read("griend_polygon/griend_polygon.shp")

bbox <- sf::st_bbox(griend %>% sf::st_buffer(4000))

# make tile data
# data_tile <- data_sp_assort %>% 
#   mutate(x_round = plyr::round_any(x_mean, 100),
#          y_round = plyr::round_any(y_mean, 100)) %>% 
#   group_by(x_round, y_round, tide_stage, trait) %>% 
#   summarise_at(vars(r), median)

# examine differences high and low tide
ggplot(data_sp_assort)+
  geom_point(aes(x_mean, y_mean,
                 col = r, size = flock_size),
            alpha = 0.5)+
  # geom_tile(aes(x_round, y_round,
  #               fill = r))+
  geom_sf(data = griend, fill = NA, size = 0.5)+
  # geom_histogram(aes(assort_g_mass,
  #                fill = tide_stage),
  #              position = "identity",
  #              alpha = 0.5)+
  # coord_cartesian(ylim = c(-0.5, 0.5))+
  scale_colour_gradient2(low = "red",
                       mid = "white",
                       high = "blue")+
  
  # coord_sf(crs = 32631)+
  facet_grid(tide_stage~trait, scales = "fixed")+
  theme_grey()+
  theme(legend.position = "top",
        legend.key.height = unit(0.2, "cm"),
        panel.border = element_rect(fill=NA,
                                        colour = "black"),
        axis.text = element_blank(),
        axis.title = element_blank())+
  coord_sf(expand = F,
           xlim = c(bbox['xmin'], bbox['xmax']),
           ylim = c(bbox['ymin'], bbox['ymax']))

ggsave("figs/fig_assort_traits.png", dpi = 600,
       height = 8, width = 6)
```

### Flock assortativity in 3D space

Are there distinct clusters in assortativity, i.e, do flocks assort similarly by different traits?

```{r}
# prepare data
data_plotly <- data_sp_assort %>% 
  pivot_wider(names_from = "trait", 
              values_from = c("r", "se"))

# load libs
library(plotly)

fig_assort_clust <- plot_ly(data_plotly,
                            x = ~r_mass,
                            y = ~r_gizzard,
                            z = ~r_behav,
                            size = ~flock_size) %>% 
  add_markers() %>% 
  layout(scene = list(xaxis = list(title = 'r body mass'),
                      yaxis = list(title = 'r gizzard mass'),
                      zaxis = list(title = 'r exploration')))

plotly::orca(fig_assort_clust, file = "figs/fig_assort_correlation.png",
             format = "png")
```

## What drives disassortativity?

### Assortativity and light levels

How does assortativity change over light levels?

```{r}
# get the mean time for all patches in the flock
flock_times <- select(data_patches,
                      uid, time_mean,
                      flock) %>% 
  filter(uid %in% flock_id$patch) %>% 
  group_by(flock) %>% 
  summarise_at(vars(contains("mean")),
               .funs = median)

# get light levels on unique dates
# get sunrise and sunset per unique date
{
  unique_dates = flock_times$time_mean %>% 
    as.POSIXct(origin = "1970-01-01") %>% 
    as.Date() %>% 
    unique()
  
  # get some extra dates
  unique_dates = c(min(unique_dates-1), unique_dates, unique_dates+1)
  sun_event_times = suncalc::getSunlightTimes(date = unique_dates,
                                              lat = 53.25, lon = 5.3,
                                              keep = c("sunrise", "sunset"),
                                              tz = "CET")
  
  }

# classify flock as light or dark
flock_times <- mutate(flock_times,
                      date = as.POSIXct(time_mean,
                                        origin = "1970-01-01"),
                      date = as.Date(date)) %>% 
  left_join(sun_event_times, by = "date")

flock_times <- mutate_at(flock_times,
                         vars(matches("sun")),
                         as.numeric)

flock_times <- mutate(flock_times,
                      lightlevel = if_else(between(time_mean, sunrise, sunset),
                                           "light", "dark"))

# merge light level with assort data
data_assort_light <- data_sp_assort %>% 
  left_join(flock_times, by = "flock")
```

Plot assortativty distribution by tide stage and light levels.

```{r}
ggplot(data_assort_light)+
  geom_histogram(aes(r, fill = tide_stage),
                 col = "black", lwd = 0.1,
                 binwidth = 0.1,
                 show.legend = F)+
  geom_text(data = tibble(pos = c(-1,0,1),
                          label = c(c("dissimilar\ntogether",
                                "random\nmixing",
                                "similar\ntogether"))),
            aes(pos, 300, label=label),
            size = 3,
            hjust = "inward",
            vjust = "inward")+
  scale_x_continuous(breaks = c(-1,0,1))+
  scale_fill_scico_d(palette = "broc",
                     begin = 0.2, end = 0.7)+
  theme_bw()+
  geom_vline(xintercept = 0, lty = 2)+
  facet_grid(tide_stage~lightlevel, labeller = label_both)+
  labs(x = "assortativity",
       y = "# flocks")
```


### Assortativity in moving and stationary flocks

Are flocks with a lower median circularity score more or less assortative?

```{r}
# get median circularity of flocks
flock_circularity <- select(data_patches,
                            uid, circularity,
                            flock) %>% 
  filter(uid %in% flock_id$patch) %>% 
  group_by(flock) %>% 
  summarise_at(vars(contains("circularity")),
               .funs = min)

# join with data
data_assort_circle <- data_sp_assort %>% 
  left_join(flock_circularity, by = "flock")

```


```{r}
data_assort_circle <- data_assort_circle %>% 
  mutate(circularity_round = plyr::round_any(circularity, 0.1))

ggplot(data_assort_circle,
       aes(circularity_round, r))+
  geom_hline(yintercept = 0)+
  geom_jitter(size = 0.2, alpha = 0.2,
              width = 0.01)+
  stat_summary(fun.data = "mean_cl_boot",
               colour = "red")
```



