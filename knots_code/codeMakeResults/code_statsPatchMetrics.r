#### code for models ####

library(data.table); library(tidyverse)
library(lmerTest)

# simple ci function
ci = function(x){
  qnorm(0.975)*sd(x, na.rm = T)/sqrt((length(x)))}

#### load data ####
# read in patch data
patches <- read_csv("../data2018/oneHertzData/summary/data2018patches.csv") 

# read in behav scores
behavData <- read_csv("../data2018/behavScoresRanef.csv") %>% 
  select(id, contains("Score"))

# link behav score and patch size and area
patches <- left_join(patches, behavData, by= c("id"))

#### prep for models ####
# select patch duration, patch area, within patch distance,
# between patch distance, number of patches
modsPatches1 <- patches %>%
  select(duration, distInPatch, area, contains("Score"), tidalcycle, nFixes,id) %>% 
  drop_na() %>%
  # make long for score type, either transformed or cond ranef
  gather(scoreType, scoreval, -id, -tidalcycle, -duration, -distInPatch,
         -area, -nFixes) %>% 
  group_by(scoreType) %>% 
  # split into two dfs
  nest() %>% 
  # in each df, split by response variable
  mutate(data = map(data, function(df){
    df %>% gather(respVar, respval, -scoreval, -nFixes, -id, -tidalcycle) %>%
      nest(-respVar)
  })) %>% 
  # unnest one level
  unnest()


# check data availability
map_int(modsPatches1$data, nrow)
map(modsPatches1$data, function(z){length(unique(z$id))})

# run models for within patch metrics
modsPatches1 <- modsPatches1 %>% 
  mutate(model = map(data, function(z){
    lmer(respval ~ scoreval + log(nFixes) + (1|id) + (1|tidalcycle), data = z, na.action = na.omit)
  })) %>% 
  # get predictions with random effects and nfixes includes
  mutate(predMod = map2(model, data, function(a, b){
    b %>% 
      mutate(predval = predict(a, type = "response", re.form = NULL))
  }))

# code to get mod summary
map(modsPatches1$model, summary)
map(modsPatches1$model, car::Anova)

#### code for between patch metrics ####
dataBwPatches <- patches %>%
  mutate(tidestage = factor(ifelse(between(tidaltime_mean, 4*60, 9*60), "lowTide", "highTide"))) %>%
  drop_na(exploreScore) %>% 
  group_by(id, tidalcycle, tidestage, exploreScore) %>% 
  summarise(distBwPatch = mean(distBwPatch, na.rm = T),
            patchChanges = max(resPatch),
            nFixes = sum(nFixes))

# gather and run models
modsPatches2 <- dataBwPatches %>%
  ungroup() %>% 
  gather(respvar, empval, -exploreScore, -id, -tidalcycle, -tidestage, -nFixes) %>% 
  nest(-respvar)

# count available data
map_int(modsPatches2$data, nrow)
map(modsPatches2$data, function(z){length(unique(z$id))})

# run model and get preds
modsPatches2 <- modsPatches2 %>% 
  mutate(model = map(data, function(z){
    lmer(empval ~ exploreScore + log(nFixes) + tidestage + (1|tidalcycle), data = z, na.action = na.omit)
  })) %>% 
  # get predictions with random effects and nfixes includes
  mutate(predMod = map2(model, data, function(a, b){
    b %>% 
      mutate(predval = predict(a, type = "response", re.form = NULL))
  }))

# see mod summaries
map(modsPatches2$model, summary)
map(modsPatches2$model, car::Anova)

#### section for plots ####
# starting with within patch models
dataPlt <- map(list(modsPatches1, modsPatches2), function(z){
  
  df <- z %>% 
    select(respvar, predMod) %>% 
    unnest() %>% 
    group_by(respvar, 
             explorebin = plyr::round_any(exploreScore, 0.2)) %>% 
    mutate(empval = ifelse(respvar == "duration", empval/60, empval),
           predval = ifelse(respvar == "duration", predval/60, predval)) %>% 
    summarise_at(vars(empval, predval),
                 list(~mean(.), ~ci(.)))
}) %>% 
  bind_rows() %>% 
  ungroup()

# plot
source("codePlotOptions/ggThemeKnots.r")

# write a labeller
patchMetLabels <- c("area" = "Patch area (m²)",
                    "distInPatch" = "Dist. within patch (m)",
                    "distBwPatch" = "Dist. between patches (m)",
                    "duration" = "Time in patch (mins.)",
                    "patchChanges" = "Patch changes")

# plot with panels of three and two columns
# get first row of within patch plots
plotPatchMetrics01 <-
ggplot(dataPlt %>% 
         filter(respvar %in% c("duration", "distInPatch", "area")) %>% 
         mutate(respvar = factor(respvar, levels = c("duration",
                                                     "distInPatch",
                                                     "area"))))+
  geom_pointrange(aes(x = explorebin, y = empval_mean,
                      ymin = empval_mean - empval_ci,
                      ymax = empval_mean + empval_ci), size = 0.3)+
  
  geom_smooth(aes(x = explorebin, y = predval_mean), 
              col = 1, method = "lm", fill = "grey80", lwd = 0.3)+
  
  scale_x_continuous(breaks = seq(-0.4, 1, 0.2))+
  
  facet_wrap(~respvar, scales = "free",
             labeller = labeller(respvar = patchMetLabels),
             strip.position = "left")+
  themePubKnots()+
  theme(strip.placement = "outside", 
        strip.background = element_blank(),
        strip.text = element_text(face = "plain", hjust = 0.5))+
  labs(y = NULL, x = "Exploration score")

# get second row with between patch metrics
plotPatchMetrics02 <-
  ggplot(dataPlt %>% 
           filter(respvar %in% c("distBwPatch", "patchChanges")))+
  geom_pointrange(aes(x = explorebin, y = empval_mean,
                      ymin = empval_mean - empval_ci,
                      ymax = empval_mean + empval_ci), size = 0.3, shape = 15)+
  
  geom_smooth(aes(x = explorebin, y = predval_mean), 
              col = 1, method = "lm", fill = "grey80", lwd = 0.3)+
  
  scale_x_continuous(breaks = seq(-0.4, 1, 0.2))+
  
  facet_wrap(~respvar, scales = "free",
             labeller = labeller(respvar = patchMetLabels),
             strip.position = "left")+
  themePubKnots()+
  theme(strip.placement = "outside", 
        strip.background = element_blank(),
        strip.text = element_text(face = "plain", hjust = 0.5))+
  labs(y = NULL, x = "Exploration score")

# arrange using grid arrange
library(gridExtra)

{pdf(file = "../figs/fig05patchMetrics.pdf", width = 180/25.4, height = 150/25.4)
  
  grid.arrange(plotPatchMetrics01, plotPatchMetrics02, nrow = 2,
               layout_matrix = matrix(c(1,1,1,1,1,1,NA,2,2,2,2,NA), nrow = 2, byrow = T));
  # add subplot labels
  grid.text(c("a","b", "c", "d", "e"), x = c(0.075, 0.4, 0.725, 0.24, 0.56), 
            y = c(0.97, 0.97, 0.97, 0.475, 0.475), just = "left",
            gp = gpar(fontface = "bold"), vp = NULL)
  
  dev.off()}
