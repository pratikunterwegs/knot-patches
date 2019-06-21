#### link patch size to exploration score ####

# load libs
library(tidyr); library(dplyr); library(readr); library(sf)

# read in patch size data from shapefile
patches <- st_read("../data2018/oneHertzDataSubset/patch/patches.shp") 
# make an sf copy
patchSf <- patches

# read in behav scores
behavScore <- read_csv("../data2018/behavScores.csv") %>% 
  mutate(bird = factor(id))

# link behav score and patch size and area
patches <- left_join(patches, behavScore, by= c("bird")) %>% 
  st_drop_geometry()

# # filter out unreasonable data of greater than 100 x 100 m
# patches <- filter(patches)

# make exploratory plots
library(ggplot2)
source("codePlotOptions/geomFlatViolin.r")
source("codePlotOptions/ggThemePub.r")

#### patch area vs tidal stage over season ####
# plot boxplots of foraging vs non-foraging patches
patches %>% 
  mutate(highTideHour = floor(tidaltime_mean/60),
         foraging = ifelse(between(highTideHour, 4, 9), "low-tide", "high-tide")) %>%
  ggplot()+
  geom_boxplot(aes(x = factor(highTideHour), 
                   y = area, fill = highTideHour %in% c(4:9)),
               position = position_dodge(preserve = "single", width = 1))+
  facet_wrap(~tidalCycle)+
  scale_fill_brewer(palette = "Accent", label = c("high tide","low tide"))+
  themePubLeg()+
  ylim(0,1e4)+
  labs(x = "hours since high tide", y = bquote("patch area" (m^2)),
       title = "patch area ~ time since high tide",
       caption = Sys.time(), fill = "rough tidal stage")+
  theme(legend.position = c(0.9, 0.1))

ggsave(filename = "../figs/figPatchAreaVsTime.pdf", width = 11, height = 8,
       device = pdf()); dev.off()

#### patch count plot ####
patches %>% 
  mutate(highTideHour = floor(tidaltime_mean/60),
         foraging = ifelse(between(highTideHour, 4, 9), "low-tide", "high-tide")) %>%
  count(bird, highTideHour, name = "nPatches") %>% 
  
  ggplot()+
  geom_flat_violin(aes(x = factor(highTideHour), y = nPatches, 
                       fill = highTideHour %in% c(4:9)),
                   col = "transparent",
                   position = position_nudge(x = .1, y = 0),
                   scale = "width")+
  geom_boxplot(aes(x = factor(highTideHour), 
                   y = nPatches, col = highTideHour %in% c(4:9)),
               position = position_nudge(x = -.1, y = 0),
               width = 0.2,
               size = 0.5,
               outlier.colour = stdGry, outlier.size = 0.5)+
  #facet_wrap(~tidalCycle)+
  scale_fill_brewer(palette = "Accent", label = c("high tide","low tide"))+
  scale_colour_brewer(palette = "Accent", label = c("high tide","low tide"))+
  themePubLeg()+
  #ylim(0,1e4)+
  labs(x = "hours since high tide", y = "# patches",
       title = "number of patches ~ time since high tide",
       caption = Sys.time(), fill = "rough tidal stage", colour = "rough tidal stage")+
  theme(legend.position = c(0.9, 0.9))

ggsave(filename = "../figs/figPatchNumberVsTidalTime.pdf", width = 6, height = 5,
       device = pdf()); dev.off()

#### patch distance plot ####
patches %>% 
  mutate(highTideHour = floor(tidaltime_mean/60),
         foraging = ifelse(between(highTideHour, 4, 9), "low-tide", "high-tide")) %>%
  
  ggplot()+
  geom_flat_violin(aes(x = factor(highTideHour), y = dist, fill = foraging),
                   col = "transparent",
                   position = position_nudge(x = .1, y = 0),
                   scale = "width")+
  geom_boxplot(aes(x = factor(highTideHour), y = dist, col = foraging), 
               position = position_nudge(x = -.1, y = 0), 
               width = 0.2,
               size = 0.3,
               outlier.colour = stdGry, outlier.size = 0.5)+
  facet_wrap(~tidalCycle)+
  labs(x = "hours since high tide", y = "distance between patches (m)",
       caption = Sys.time(), title = "inter-patch distance ~ tidal time",
       fill = "rough tidal stage", colour = "rough tidal stage")+
  ylim(0, 2e3)+
  
  scale_fill_brewer(palette = "Accent", label = c("high tide","low tide"))+
  scale_colour_brewer(palette = "Accent", label = c("high tide","low tide"))+
  themePubLeg()+
  theme(legend.position = c(0.9, 0.1))

ggsave(filename = "../figs/figPatchDistanceVsTime.pdf", width = 11, height = 8,
       device = pdf()); dev.off()

# plot patch area vs other predictors
patches %>% #filter(area < 1e5) %>% 
  as_tibble() %>% 
  select(area, WING, MASS, gizzard_mass, pectoral, exploreScore, bird, tdlCycl) %>% 
  gather(predictor, value, -bird, -area, -tdlCycl) %>% 
  group_by(predictor, bird, value) %>% 
  summarise_at(vars(area), list(mean=mean, sd=sd)) %>% 

ggplot()+
  geom_pointrange(aes(x = value, y = mean, ymin = mean-sd, ymax = mean+sd, group = bird), size= 0.5, alpha = 0.2)+
  geom_smooth(aes(x = value, y = mean), method = "glm")+
  facet_wrap(~predictor, scales = "free_x")+
  coord_cartesian(ylim = c(0,1e4))+
  labs(x = "predictor value", y = "patch area (m^2)", caption = Sys.time(),
       title = "patch area ~ various predictors")+
  themePub()

ggsave(filename = "../figs/figPatchAreaVsPredictors2.pdf", width = 11, height = 8,
       device = pdf()); dev.off()

#### plot one set of patches ####
randBirds <- sample(unique(patchSf$bird), 15, replace = FALSE)
patchSfsubset <- patchSf %>% filter(tdlCycl == "005", bird %in% randBirds)

# read griend
griend <- st_read("../griend_polygon/griend_polygon.shp")

# plot subset
mapPlot <- ggplot()+
  geom_sf(data = griend)+
  geom_sf(data = patchSfsubset, aes(fill = bird))+
  
  geom_path(data = patchSfsubset, aes(x_mean, y_mean, group = bird, col = bird), 
            size = 0.1)+
  geom_text(data = patchSfsubset, aes(x_mean, y_mean, label = patch, group = bird))

library(plotly); library(htmlwidgets)

mapInt <- ggplotly(mapPlot)

htmlwidgets::saveWidget(mapInt, file = "mapInteractivePatches.html")
