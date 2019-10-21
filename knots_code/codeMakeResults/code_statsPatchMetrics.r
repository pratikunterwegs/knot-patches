#### code for models of fine-scale patch metrics vs exploration score ####

# Code author Pratik Gupte
# PhD student
# MARM group, GELIFES-RUG, NL
# Contact p.r.gupte@rug.nl

library(data.table); library(tidyverse)
library(lmerTest)
library(viridis)

# simple ci function
ci = function(x){
  qnorm(0.975)*sd(x, na.rm = T)/sqrt((length(x)))}

#### load data ####
# load file list
fileList <- list.files(path = "../data2018/patchData/", pattern = ".csv",
                       full.names = TRUE)
# read in patch data
patches <- purrr::map_df(fileList, fread)

# keep only low tide
# patches <- patches %>% filter(between(tidaltime_mean, 4*60, 9*60))

# read in behav scores
behavData <- read_csv("../data2018/behavScoresRanef.csv") %>% 
  select(id, contains("Score"))

# extreme <- quantile(behavData$tExplScore, probs = c(0.25, 0.75), na.rm = T)

# link behav score and patch size and area
patches <- left_join(patches, behavData, by= c("id"))

# remove extremes, the top and bottom 5%
# patches <- patches %>% filter(tExplScore %between% extreme)

#### prep for models ####
# select patch duration, patch area, within patch distance,
# between patch distance, number of patches
modsPatches1 <- patches %>%
  # get a predictor for tidal time, a sine transform to be cyclic
  mutate(tidestage = as.factor(ifelse(between(tidaltime_mean, 
                                              4*60, 9*60), "low", "high"))) %>% 
  select(duration, distInPatch, distBwPatch, area, tidestage, # responses
         tExplScore, tidalcycle, nfixes,id) %>% # predictors
  drop_na() %>%
  # make long for score type, either transformed or cond ranef
  # gather(scoreType, scoreval, -id, -tidalcycle, -tidestage,  
  #        -duration, -distInPatch, -distBwPatch, -area, -nfixes) %>% 
  # group_by(scoreType) %>% 
  # # split into two dfs
  # nest() %>% 
  # # in each df, split by response variable
 gather(respvar, respval, -tExplScore, -nfixes, -id, -tidalcycle, 
                  -tidestage) %>% 
  group_by(respvar) %>% 
  nest()

# check data availability
map_int(modsPatches1$data, nrow)
map(modsPatches1$data, function(z){length(unique(z$id))})

### models for within patch metrics ####
# run models for within patch metrics
modsPatches1 <- modsPatches1 %>% 
  mutate(model = map(data, function(z){
    lmer(respval ~ tExplScore + tidestage + (1|tidalcycle), data = z, na.action = na.omit)
  })) %>% 
  # get predictions with random effects and nfixes includes
  mutate(predMod = map2(model, data, function(a, b){
    b %>% 
      mutate(predval = predict(a, type = "response"))
  }))

# assign names
library(glue)
names(modsPatches1$model) <- glue("response = {modsPatches1$respvar} | predictor = tExplScore")

# code to get mod summary
map(modsPatches1$model, summary)

#### models for between patch metrics ####
# hereon, we use only the transformed exploration score
dataBwPatches <- patches %>%
  mutate(tidestage = factor(ifelse(between(tidaltime_mean, 4*60, 9*60), "low", "high"))) %>%
  drop_na(tExplScore) %>% 
  group_by(id, tidalcycle, tExplScore, tidestage) %>% 
  summarise(patchChanges = max(patch),
            nfixes = sum(nfixes))

# gather and run models
modsPatches2 <- dataBwPatches %>%
  ungroup() %>% 
  gather(respvar, respval, 
         -tExplScore, -id, -tidalcycle, -nfixes, -tidestage) %>% 
  nest(-respvar)

# count available data
map_int(modsPatches2$data, nrow)
map(modsPatches2$data, function(z){length(unique(z$id))})

# run model and get preds
modsPatches2 <- modsPatches2 %>% 
  mutate(model = map(data, function(z){
    lmer(respval ~ tExplScore + tidestage +
           (1|tidalcycle), data = z, na.action = na.omit)
  })) %>% 
  # get predictions with random effects and nfixes includes
  mutate(predMod = map2(model, data, function(a, b){
    b %>% 
      mutate(predval = predict(a, type = "response", re.form = NULL))
  }))

# assign names
names(modsPatches2$model) <- glue("response = {modsPatches2$respvar} | predictor = tExplScore")

# see mod summaries
map(modsPatches2$model, summary)

#### write model output to file ####
# make dir if absent
if(!dir.exists("../data2018/modOutput/")){
  dir.create("../data2018/modOutput/")
}

# write model output to text file
{writeLines(R.utils::captureOutput(map(modsPatches1$model, summary)), 
            con = "../data2018/modOutput/modOutPatchMods1.txt")}

{writeLines(R.utils::captureOutput(map(modsPatches2$model, summary)), 
            con = "../data2018/modOutput/modOutPatchMods2.txt")}

#### section for plots ####
# starting with within patch models
dataPlt <- map(list(modsPatches1, modsPatches2), function(z){
  
  df <- z %>% 
    select(respvar, predMod) %>% 
    unnest() %>% 
    group_by(respvar, 
             explorebin = plyr::round_any(tExplScore, 0.1)) %>% 
    mutate(respval = ifelse(respvar == "duration", respval/60, respval),
           predval = ifelse(respvar == "duration", predval/60, predval)) %>% 
    summarise_at(vars(respval, predval),
                 list(~mean(.), ~ci(.)))
}) %>% 
  bind_rows() %>% 
  ungroup()

#### plot figures ####
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
           # filter(respvar %in% c("duration", "distInPatch", "area", "distBwPatch")) %>% 
           mutate(respvar = factor(respvar, levels = c("duration",
                                                       "distInPatch",
                                                       "area",
                                                       "distBwPatch",
                                                       "patchChanges"))))+
  
  geom_smooth(aes(x = explorebin, y = predval_mean),
              method = "lm", fill = "grey80")+
  
  geom_pointrange(aes(x = explorebin, y = respval_mean,
                      ymin = respval_mean - respval_ci,
                      ymax = respval_mean + respval_ci), lwd = 0.3, fatten = 4)+
  
  
  scale_y_continuous(labels = scales::comma)+
  
  scale_x_continuous(breaks = seq(-0.4, 1, 0.2))+
  
  scale_shape_manual(values = c(16, 17))+
  
  scale_colour_manual(values = "grey40")+
  
  scale_fill_manual(values = "grey40")+
  
  facet_wrap(~respvar, scales = "free",
             labeller = labeller(respvar = patchMetLabels),
             strip.position = "left")+
  themePubKnots()+
  theme(strip.placement = "outside", 
        strip.background = element_blank(),
        strip.text = element_text(face = "plain", hjust = 0.5),
        panel.spacing.y = unit(2, "lines"))+
  labs(y = NULL, x = "Exploration score")


# send to file
{pdf(file = "../figs/fig05.2patchMetricsNoExtremes.pdf", width = 180/25.4, height = 120/25.4)
  
  # grid.arrange(plotPatchMetrics01, plotPatchMetrics02, nrow = 2,
  #              layout_matrix = matrix(c(1,1,1,1,1,1,NA,2,2,2,2,NA), nrow = 2, byrow = T));
  # add subplot labels
  print(plotPatchMetrics01)
  grid.text(c("(a)","(b)", "(c)", "(d)", "(e)"), x = c(0.075, 0.4, 0.725, 0.075, 0.4), 
            y = c(0.95, 0.95, 0.95, 0.48, 0.48), just = "left",
            gp = gpar(fontface = "bold"), vp = NULL)
  
  dev.off()}


