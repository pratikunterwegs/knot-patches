## Determine tidal cycle and tidal stage

### Link overlaps with patch data

```{r}
# add a uid
data_patches <- mutate(data_patches, uid = 1:nrow(data_patches))

# select columns
data_patches <- select(data_patches,
                       id, uid, waterlevel_mean,
                       x_mean, y_mean)

# link overlaps with patches
data <- left_join(data, data_patches,
                  by = c("patch_i_unique_id" = "uid")) %>% 
  left_join(data_patches,
            by = c("patch_j_unique_id" = "uid"))
```

### Get consensus tide number waterlevel

The tide number and tidal stage will be used to divide the overlaps into classes, so that we can examine community structure in a particular tide and at a certain tidal stage.

```{r}
# get the consensus tide as first and the mean waterlevel
data <- data %>% 
  mutate(grp_id = 1:nrow(.)) %>% 
  group_by(grp_id) %>% 
  mutate(#tide_number = tide_number.x,
         waterlevel = mean(c(waterlevel_mean.x, waterlevel_mean.y)),
         
         # also add the 500m grid cell
         x = mean(c(x_mean.x, x_mean.y)),
         y = mean(c(y_mean.x, y_mean.y))) %>% 
  ungroup()

# remove bad cols and classify as high or low tide
data <- data %>% 
  ungroup() %>% 
  select(-grp_id) %>% 
  rename(id_x = id.x, id_y = id.y) %>% 
  select(-contains(c(".x", ".y")))

# classify as high or low and round x and y to 500m
data <- data %>% 
  mutate(tide_stage = if_else(waterlevel < 55, "low", "high"),
         x = plyr::round_any(x, 200),
         y = plyr::round_any(y, 200)) %>% 
  select(-waterlevel)
```

## Prepare network data

### Prepare subset-wise edgelist

Here, the subsets are the tide number and tidal stage. The edge-list indicates pairwise overlap. We now add subsets for 500m grid cells on the landscape.

```{r}
# get the total overlap between pairs as the edges df
edges_df <- data %>% 
  group_by(id_x, id_y, 
           #tide_number, 
           tide_stage,
           x, y) %>% 
  summarise_at(vars(temporal_overlap_seconds, spatial_overlap_area),
               .funs = sum) %>% 
  filter(id_x != id_y)

# group and nest
edges_df <- group_by(edges_df, 
                     #tide_number, 
                     tide_stage,
                     x, y) %>% 
  nest()
```

### Get individual data

```{r}
# make nodes data -- this the individual identities
# add individual data to patch data
data_id <- readxl::read_excel("data/data2018/Biometrics_2018-2019.xlsx") %>% 
  filter(str_detect(`TAG NR`, "[a-zA-Z]+", negate = TRUE))

# a function for gizzard mass
get_gizzard_mass <- function(x, y) {-1.09 + (3.78*(x*y))}

# add gizzard mass
data_id <- mutate(data_id,
                  gizzard_mass = get_gizzard_mass(SH1, SW1))

# rename columns and drop ids without mass and gizzard mass
data_id <- data_id %>% 
  select(id = `TAG NR`, 
         wing = WING, mass = MASS, 
         gizzard_mass) %>% 
  distinct(id, .keep_all = TRUE) %>% 
  drop_na(mass, gizzard_mass)

# add some exploration scores and tag info
data_behav <- read_csv("data/data2018/2018-19-all_exploration_scores.csv") %>% 
  filter(Exp == "F01")
data_tag <- read_csv("data/data2018/tag_info.csv") %>% 
  mutate(id = as.character(Toa_Tag))

# join all scores
data_id <- left_join(data_id, data_tag,
                     by = c("id")) %>% 
  left_join(data_behav, by = "FB")

# remove ids with no exploration
data_id <- mutate(data_id,
                  behav = Mean) %>% 
  # drop_na(behav) %>% 
  select(id, mass, gizzard_mass, behav)
```

### Prepare nodes data

```{r}
# expand nodes df to match edges data
nodes_df <-  
  summarise(edges_df, 
            id = map(data, function(df) {union(df$id_x, df$id_y)})) %>%
  mutate(id = map(id, function(df){
    
    df <- tibble(id = as.character(df)) %>% 
      left_join(data_id, by = "id")
    
    # remove nodes with no attributes
    df <- drop_na(df, mass, gizzard_mass, behav)
  }))
```

This data needs to be converted to `igraph` networks.

## Network metrics with igraph

### Convert to igraph

```{r}
# prepare a uniform network dataframe
network_df <- left_join(edges_df, nodes_df)

# filter for existing node data
network_df <- filter(network_df,
                     map_lgl(id, function(df){nrow(df)>1}))

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
```

### Get assortativity

Remove networks with no edges. *THIS IS UNRELIABLE.*

```{r}
# check which graphs are okay
network_df <- mutate(network_df, 
                     valid_graph = map_int(net, function(n){
                       E(n) %>% length()
                     })) %>% 
  ungroup()

# remove bad graphs
network_df <- filter(network_df, valid_graph > 0)
```


```{r}
# get weighred assortativity by gizzard mass
network_df <- mutate(network_df,
                     assort_g_mass = unlist(purrr::map(net, function(n){
                       
                       adj <- igraph::as_adjacency_matrix(n,
                                                          sparse = FALSE,
                                                          attr = "spatial_overlap_area")
                       
                       assortnet::assortment.continuous(adj, V(n)$gizzard_mass)
                     })))
```

```{r}
# get weighred assortativity by gizzard mass
network_df <- mutate(network_df,
                     assort_behav = unlist(purrr::map(net, function(n){
                       
                       adj <- igraph::as_adjacency_matrix(n,
                                                          sparse = FALSE,
                                                          attr = "spatial_overlap_area")
                       
                       assortnet::assortment.continuous(adj, V(n)$behav)
                     })))
```


## Plot assortativity

```{r}
# prepare the data
plot_df <- select(network_df, tide_stage,
                  x,y,
                  valid_graph,
                  contains("assort")) %>% 
  filter(valid_graph >= 3) %>% 
  pivot_longer(cols = contains("assort"))
```


```{r}
# get griend
griend <- sf::st_read("griend_polygon/")

# examine differences high and low tide
ggplot(plot_df)+
  geom_tile(aes(x,y, fill = value),
            alpha = 1)+
  geom_sf(data = griend, fill = NA, size = 0.5)+
  # geom_histogram(aes(assort_g_mass,
  #                fill = tide_stage),
  #              position = "identity",
  #              alpha = 0.5)+
  # coord_cartesian(ylim = c(-0.5, 0.5))+
  scale_fill_gradient2(low = "indianred",
                       mid = "white",
                       high = "blue")+
  # coord_sf(crs = 32631)+
  facet_grid(name~tide_stage, scales = "fixed")+
  theme_grey()+
  theme(legend.position = "top",
        legend.key.height = unit(0.2, "cm"),
        panel.border = element_rect(fill=NA,
                                        colour = "black"),
        axis.text = element_blank(),
        axis.title = element_blank())+
  coord_sf(expand = F)

ggsave("figs/fig_assort_gizzard.png", dpi = 600)
```

