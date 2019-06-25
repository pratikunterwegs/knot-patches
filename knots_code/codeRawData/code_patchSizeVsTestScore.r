#### link patch size to exploration score ####

# load libs
library(tidyr); library(dplyr); library(readr)

# read in patch size data from shapefile
patches <- read_csv("../data2018/oneHertzData/data2018patches.csv") 

# read in behav scores
behavScore <- read_csv("../data2018/behavScores.csv")

# link behav score and patch size and area
patches <- left_join(patches, behavScore, by= c("id"))

# # filter out unreasonable data of greater than 100 x 100 m
# patches <- filter(patches)

# make exploratory plots
library(ggplot2)
source("codePlotOptions/geomFlatViolin.r")
source("codePlotOptions/ggThemeKnots.r")
source("codePlotOptions/ggThemeGeese.r")

# simple ci function
ci = function(x){
  qnorm(0.975)*sd(x, na.rm = T)/sqrt((length(x)))
}

#### make patch summary ####
patchSummary <- patches %>% 
  mutate(tidalCluster = plyr::round_any(tidalcycle, 15),
         tidalTimeHour = plyr::round_any(tidaltime_mean/60, 1)) %>% 
  filter(tidalTimeHour <= 12, tidalCluster <=120) %>% 
  group_by(tidalCluster, tidalTimeHour) %>% 
  summarise_at(vars(area, nFixes, distInPatch, distBwPatch),
               list(~mean(., na.rm = T), ~ci(.)))

#### area vs time ####
ggplot(patchSummary)+
  geom_pointrange(aes(x = factor(tidalTimeHour), 
                   y = area_mean, ymin = area_mean - area_ci,
                   ymax = area_mean + area_ci,
                   fill = between(tidalTimeHour, 4, 9)), shape = 21, lty = 1)+
  facet_wrap(~tidalCluster, scales = "free")+
  scale_fill_brewer(palette = "Greys", label = c("high tide","low tide"))+
  coord_cartesian(ylim = c(1e3, 4e3))+
  
  themePubKnots()+
  
  labs(x = "hours since high tide", y = bquote("patch area" (m^2)),
       title = "patch area ~ time since high tide ~ tidal cluster",
       caption = Sys.time(), fill = "rough tidal stage")
# plot
ggsave(filename = "../figs/figPatchAreaVsTime.pdf", width = 8, height = 6,
       device = pdf()); dev.off()

#### n Fixes vs time ####
ggplot(patchSummary)+
  geom_pointrange(aes(x = factor(tidalTimeHour), 
                      y = nFixes_mean, ymin = nFixes_mean - nFixes_ci,
                      ymax = nFixes_mean + nFixes_ci,
                      fill = between(tidalTimeHour, 4, 9)), shape = 21, lty = 1)+
  facet_wrap(~tidalCluster, scales = "free")+
  scale_fill_brewer(palette = "Reds", label = c("high tide","low tide"))+
  coord_cartesian(ylim = c(0, 3e2))+
  
  themePubKnots()+
  
  labs(x = "hours since high tide", y = bquote("nFixes"),
       title = "nFixes ~ time since high tide ~ tidal cluster",
       caption = Sys.time(), fill = "rough tidal stage")
# plot
ggsave(filename = "../figs/figPatchFixesVsTime.pdf", width = 8, height = 6,
       device = pdf()); dev.off()

#### distance within patch ####
ggplot(patchSummary)+
  geom_pointrange(aes(x = factor(tidalTimeHour), 
                      y = distInPatch_mean, ymin = distInPatch_mean - distInPatch_ci,
                      ymax = distInPatch_mean + distInPatch_ci,
                      fill = between(tidalTimeHour, 4, 9)), shape = 21, lty = 1)+
  facet_wrap(~tidalCluster, scales = "fixed")+
  scale_fill_brewer(palette = "Blues", label = c("high tide","low tide"))+
  #coord_cartesian(ylim = c(0, 3e2))+
  
  themePubKnots()+
  
  labs(x = "hours since high tide", y = bquote("distance within patch (m)"),
       title = "distWiPatches ~ time since high tide ~ tidal cluster",
       caption = Sys.time(), fill = "rough tidal stage")
# plot
ggsave(filename = "../figs/figPatchDistWithinVsTime.pdf", width = 8, height = 6,
       device = pdf()); dev.off()

#### distance between patch ####
ggplot(patchSummary)+
  geom_pointrange(aes(x = factor(tidalTimeHour), 
                      y = distBwPatch_mean, ymin = distBwPatch_mean - distBwPatch_ci,
                      ymax = distBwPatch_mean + distBwPatch_ci,
                      fill = between(tidalTimeHour, 4, 9)), shape = 21, lty = 1)+
  facet_wrap(~tidalCluster, scales = "free")+
  scale_fill_brewer(palette = "Greens", label = c("high tide","low tide"))+
  coord_cartesian(ylim = c(0, 5e2))+
  
  themePubKnots()+
  
  labs(x = "hours since high tide", y = bquote("distance b/w patch (m)"),
       title = "distBwPatches ~ time since high tide ~ tidal cluster",
       caption = Sys.time(), fill = "rough tidal stage")
# plot
ggsave(filename = "../figs/figPatchDistBetwnVsTime.pdf", width = 8, height = 6,
       device = pdf()); dev.off()
