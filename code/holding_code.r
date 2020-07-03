
## Network modelling

Make a population network from the subsetted edgelist. First prep the data.

### Prepare the data

```{r}
# make an edges dataframe
net_df <- data_summary %>% 
  select(matches("id."),
         matches("tide"),
         n_associations,
         -uid_pair) %>% 
  group_by(tide_number, tide_stage) %>% 
  nest()

# make a node df
net_df <- net_df %>% 
  mutate(id = map(data, function(df) {
    unique_ids <- union(df$id.x, df$id.y)
    
    df <- tibble(id = as.character(unique_ids)) %>% 
      left_join(data_id, by = "id")
    
    # remove nodes with no attributes
    df <- drop_na(df, gizzard_mass)
    
  }))
```

### Make the networks

```{r}
net_df <- mutate(net_df,
                 net = map2(data, id, function(e, n){
                   
                   # exclude edges with no vertex attributes
                   e <- filter(e, 
                               id.x %in% n$id,
                               id.y %in% n$id) 
                   
                   tmp_net <- igraph::graph_from_data_frame(d = e,
                                                            directed = FALSE,
                                                            vertices = n)
                 }))
```

### Visualise some networks

```{r}
library(ggraph)
# visualise a network
ggraph(net_df$net[[1]], layout = "dh") + 
    geom_edge_fan(show.legend = FALSE,
                  edge_colour = "grey",
                  edge_alpha = 0.5,
                  aes(edge_width = n_associations)) + 
    geom_node_point(aes(size = gizzard_mass)) + 
    theme_graph(foreground = 'steelblue', fg_text_colour = 'white')+
    theme(legend.position = "none")
```

### Get network assortativity

```{r}
net_df <- mutate(net_df,
                 assort_gm = purrr::map_dbl(net, function(n){
                       
  adj <- igraph::as_adjacency_matrix(n,
                                     attr = "n_associations",
                                     sparse = FALSE)
  
  assort_gizzard <- assortnet::assortment.continuous(adj,
                                                     V(n)$gizzard_mass)
  assort_gizzard <- unlist(assort_gizzard)
                 }))
```

Plot to see.

```{r}
# plot figure
ggplot(net_df)+
  geom_histogram(aes(assort_gm,
                     y = ..density..),
                 fill = "steelblue")+
  geom_boxplot(aes(x = assort_gm, y = -1),
               width = 1)+
  geom_vline(xintercept = 0, lty = 2)+
  coord_flip()+
  theme_grey(base_size = 8,
             base_family = "TT Arial") +
  facet_grid(~ tide_stage, 
             labeller = label_both)+
  labs(x = "assortativity of gizzard mass")

ggsave(filename = "figs/fig_assort_tidestage.png",
       dpi = 300, height = 4, width = 4)
```

Plot assortativity over tide stages.