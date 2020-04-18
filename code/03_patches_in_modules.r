---
editor_options: 
  chunk_output_type: console
---

# Knots in modules

## Prepare libraries

```{r prep_libs_03, eval=FALSE}
library(tidyverse)
# for plots
library(ggplot2)
library(scico)

# for models
library(lmerTest)
library(rptR)

# ci function
ci <- function(x){qnorm(0.975)*sd(x, na.rm = TRUE)/sqrt(length(x))}
```

## Read in data

### Read in module and patch data

```{r read_modules_03, eval=FALSE}
# read in data
modules <- read_csv("data/data_2018_patch_modules_small_scale.csv")
data <- read_csv("data/data_2018_good_patches.csv")
```

### Prepare exploration data

```{r prep_exploration_data}
# get a crude exloration score as distance between patches
# and number of patches
exploration_data <- data %>% 
  group_by(id, tide_number) %>%
  summarise(n_patches = max(patch),
            total_distance = sum(distBwPatch))

# filter data
distance_lims = quantile(exploration_data$total_distance, 
                         probs = c(0.05, 0.95), na.rm = T)
patch_lims = quantile(exploration_data$n_patches, 
                         probs = c(0.05, 0.95), na.rm = T)

# remove NAs and filter by lims
exploration_data <- exploration_data %>% 
  drop_na() %>% 
  filter(between(n_patches, patch_lims[1], patch_lims[2]),
         between(total_distance, distance_lims[1], distance_lims[2]))

# scale data
exploration_data <- exploration_data %>% 
  ungroup() %>% 
  mutate_at(vars(n_patches, total_distance),
            list(~scales::rescale(.)))

# split into two dataframes
exploration_data <- pivot_longer(exploration_data,
                                 cols = c("n_patches", "total_distance")) %>% 
  group_by(name) %>% 
  nest()


# run rptr models for each
exploration_data <- mutate(exploration_data,
                             models = map(data, function(df){
                               rpt(value ~ (1 | id) + (1 | tide_number), grname = "id", 
                                   data = df, datatype = "Gaussian",
                                   nboot = 10, npermut = 0,
                                   parallel = TRUE) # risky but try
                             }))

```

```{r get_module_chunk_variance, eval=FALSE}
# get variance and variance
module_explore_variance <- modules %>% 
  filter(!is.na(exploreScore), !is.nan(exploreScore)) %>% 
  group_by(time_scale, spatial_scale, time_chunk, module) %>%
  mutate(n_uid = length(unique(id))) %>% 
  summarise(explore_var = var(exploreScore),
            n_uid = n_uid[1])

# remove modules with only one id
module_explore_variance <- filter(module_explore_variance, n_uid > 1)
```

```{r}
ggplot(module_explore_variance)+
  geom_tile(aes(time_chunk, module, fill = explore_var))+
  scale_fill_scico(limits = c(0, 0.1))+
  facet_grid(time_scale~spatial_scale,
             scales = "free_y",
             labeller = label_both)
```

