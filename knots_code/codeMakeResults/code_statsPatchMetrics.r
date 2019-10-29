#### code for models of fine-scale patch metrics vs exploration score ####

# Code author Pratik Gupte
# PhD student
# MARM group, GELIFES-RUG, NL
# Contact p.r.gupte@rug.nl

library(data.table); library(tidyverse)
library(lmerTest)
library(viridis)

# simple ci function
ci <- function(x){
  qnorm(0.975)*sd(x, na.rm = T)/sqrt((length(x)))}

#### load data ####
# load file list
fileList <- list.files(path = "../data2018/patchData/", pattern = ".csv",
                       full.names = TRUE)
# read in patch data
patches <- purrr::map_df(fileList, fread)

# read in behav scores
behavData <- read_csv("../data2018/behavScoresRanef.csv") %>% 
  select(id, tExplScore)

# extreme <- quantile(behavData$tExplScore, probs = c(0.25, 0.75), na.rm = T)

# link behav score and patch size and area
patches <- left_join(patches, behavData, by= c("id"))

#### sanity checks ####
# count patches where prop fixes > 1
{
  count(patches, propFixes >= 1.0)
  # remove such patches
  patches <- filter(patches, propFixes < 1)
  # count patches with fewer than 20% data
  count(patches, propFixes < 0.2)
  # remove those too
  patches <- filter(patches, propFixes > 0.2)
  
  # remove high tide patches
  patches <- filter(patches, tidaltime_start %between% c(4*60, 10*60))
}

#### prep for models and plotting ####

# select patch duration, patch area, within patch distance,
# between patch distance, number of patches
modsPatches1 <- patches %>%
  drop_na(duration, distInPatch, distBwPatch, area, 
          tExplScore, tidalcycle, nfixes, id) %>%
  
  # make duration mins
  mutate(duration = duration/60) %>% 
  # # in each df, split by response variable
  pivot_longer(names_to = "respvar", values_to = "respval",
               cols = c(duration, distInPatch, distBwPatch, area)) %>% 
  group_by(respvar) %>% 
  nest()

# check data availability
map_int(modsPatches1$data, nrow)
map_int(modsPatches1$data, function(z){length(unique(z$id))})


#### plot metric ~ explorescore ####
# prep data for plots
plotdata <- modsPatches1 %>% 
  # round to 0.1 increments of exploration score
  mutate(data_expl = map(data, function(df){
    select(df, tExplScore, tidaltime_mean, respval) %>% 
      mutate(tExplScore = plyr::round_any(tExplScore, 0.1),
             tidalHour = round(tidaltime_mean/60)) %>% 
      filter(tidalHour <= 9) %>% 
      group_by(tExplScore, tidalHour) %>% 
      summarise_at(vars(respval), .funs = c(~mean(.), ~ci(.)))}),
    
    # round to 30 min intervals of tidal cycle
    # data_tide = map(data, function(df){
    #   select(df, tidaltime_start, respval) %>% 
    #     mutate(tidaltime = plyr::round_any(tidaltime_start, 20)) %>% 
    #     group_by(tidaltime) %>% 
    #     summarise_at(vars(respval), .funs = c(~mean(.), ~ci(.)))}
    # )
    )# %>% 
  
  # combine data
  # mutate(data_plot = map2(data_expl, data_tide, function(df1, df2){
  #   df2 <- pivot_longer(df2, cols = tidaltime,
  #                       names_to = "predictor", values_to = "predictor_value")
  #   
  #   df1 <- pivot_longer(df1, cols = tExplScore,
  #                       names_to = "predictor", values_to = "predictor_value")
  #   
  #   return(bind_rows(df1, df2))
  # }))

# prepare total number of patches
dataPatchShift <- patches %>% 
  drop_na(tExplScore, tidalcycle, nfixes, id) %>%
  mutate(tidalHour = round(tidaltime_mean/60)) %>% 
  filter(tidalHour <= 9) %>% 
  group_by(id, tidalcycle, tidalHour, tExplScore) %>%
  # count patch changes
  summarise(patchChanges = max(patch)) %>% 
  
  # summarise by explore score
  mutate(tExplScore = plyr::round_any(tExplScore, 0.2)) %>% 
  group_by(tExplScore, tidalHour) %>% 
  summarise_at(vars(patchChanges),
               .funs = c(~mean(.), ~ci(.)))

# make plots for within patch metrics
plots <- plotdata %>% 
  ungroup() %>% 
  mutate(y = c("time in patch (mins)",
               "dist in patch (m)",
               "dist b/w patch (m)",
               "patch area (m.sq.)"),
         title = glue::glue('{letters[1:4]} {y}')) %>% 
  
  # plots column
  mutate(plot = pmap(.[,c("data_expl", "y", "title")], function(data_expl, y, title){
    ggplot(data_expl)+
      geom_pointrange(aes(x = tExplScore,
                          y = mean,
                          ymin = mean-ci,
                          ymax = mean+ci,
                          col = tidalHour),
                      position = position_dodge(width = 0.01))+
      facet_grid(~tidalHour, scales = "free_x")+
      scico::scale_colour_scico(palette = "cork")+
      scale_y_continuous(labels = scales::comma)+
      
      coord_cartesian(xlim = c(0,1),
                      ylim = c(0, 
                               quantile(data_expl$mean, 0.99)))+
      
      scale_x_continuous(breaks = c(0,0.5,1))+
      ggthemes::theme_clean()+
      theme(legend.position = "none",
            #plot.background = element_rect(colour = 1),
            #plot.margin = unit(rep(0.5, 4), "cm"),
            #axis.text.y = element_text(angle = 90, vjust = 0.5),
            plot.title = element_text(face = "bold"))+
      labs(y = y, title = title, 
           x = "explore score")
  }),
  plot = map(plot, cowplot::as_grob))

# patch changes plot
plotPatchShift <- 
  ggplot(dataPatchShift)+
  geom_pointrange(aes(x = tExplScore, y = mean,
                      ymin = mean-ci, ymax = mean+ci,
                      col = tidalHour))+
  scale_x_continuous(breaks = c(0,0.5,1))+
  scico::scale_colour_scico(palette = "cork")+
  facet_grid(~tidalHour)+
  ggthemes::theme_clean()+
  theme(legend.position = "none",
       # plot.background = element_rect(colour = 1),
        plot.margin = unit(rep(0.5, 4), "cm"),
        axis.text.y = element_text(angle = 90),
        plot.title = element_text(face = "bold"))+
  labs(x = "explore score", y = "# patches", title = "e patch changes")

plotPatchShift <- cowplot::as_grob(plotPatchShift)

# print list of plots
library(gridExtra)
plotlist = plots$plot
plotlist[[5]] <- plotPatchShift

{
  pdf(file = "../figs/fig05patchMetrics.pdf", width = 8, height = 12)
  grid.arrange(grobs = plotlist, ncol = 1)
  dev.off()
}

#### models for within patch metrics ####
# run models for within patch metrics
modsPatches1 <- modsPatches1 %>% 
  mutate(model = map(data, function(z){
    lmer(respval ~ tExplScore + (1|tidalcycle) + tidaltime_start, data = z, na.action = na.omit)
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
  drop_na() %>% 
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
map_int(modsPatches2$data, function(z){length(unique(z$id))})

# run model and get preds
modsPatches2 <- modsPatches2 %>% 
  mutate(model = map(data, function(z){
    lmer(respval ~ tExplScore + tidestage +
           (1|tidalcycle), data = z, na.action = na.omit)
  })) %>% 
  # get predictions with random effects and nfixes includes
  mutate(predMod = map2(model, data, function(a, b){
    b %>% 
      mutate(predval = predict(a, type = "response", re.form = NULL, allow.new.levels = T))
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
    group_by(respvar, tidestage,
             explorebin = plyr::round_any(tExplScore, 0.1)) %>% 
    mutate(respval = ifelse(respvar == "duration", respval/60, respval),
           predval = ifelse(respvar == "duration", predval/60, predval)) %>% 
    summarise_at(vars(respval, predval),
                 list(~mean(.), ~ci(.)))
}) %>% 
  bind_rows() %>% 
  ungroup()

#### plot figures ####
#source("codePlotOptions/ggThemeKnots.r")

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
  
  geom_line(aes(x = explorebin, y = predval_mean, col = tidestage), lty = 1)+
  geom_line(aes(x = explorebin, y = predval_mean + predval_ci, col = tidestage), lty = 2)+
  
  geom_line(aes(x = explorebin, y = predval_mean - predval_ci, col = tidestage), lty = 2)+
  
  geom_pointrange(aes(x = explorebin, y = respval_mean,
                      ymin = respval_mean - respval_ci,
                      ymax = respval_mean + respval_ci,
                      col = tidestage), lwd = 0.3, fatten = 4,
                  position = position_dodge(width = 0.1))+
  
  
  scale_y_continuous(labels = scales::comma)+
  
  scale_x_continuous(breaks = seq(-0.4, 1, 0.2))+
  
  scale_shape_manual(values = c(16, 17))+
  
  scale_colour_brewer(palette = "Set1")+
  
  scale_fill_manual(values = "grey40")+
  
  facet_wrap(~respvar, scales = "free",
             labeller = labeller(respvar = patchMetLabels),
             strip.position = "left")+
  ggthemes::theme_few()+
  theme(strip.placement = "outside", 
        strip.background = element_blank(),
        strip.text = element_text(face = "plain", hjust = 0.5),
        panel.spacing.y = unit(2, "lines"))+
  labs(y = NULL, x = "Exploration score")


# send to file
library(grid)
{
  png(file = "../figs/fig05patchMetrics.png", width = 1200, height = 600, res = 150)
  
  # grid.arrange(plotPatchMetrics01, plotPatchMetrics02, nrow = 2,
  #              layout_matrix = matrix(c(1,1,1,1,1,1,NA,2,2,2,2,NA), nrow = 2, byrow = T));
  # add subplot labels
  print(plotPatchMetrics01)
  # grid.text(c("(a)","(b)", "(c)", "(d)", "(e)"), x = c(0.075, 0.4, 0.725, 0.075, 0.4), 
  #           y = c(0.95, 0.95, 0.95, 0.48, 0.48), just = "left",
  #           gp = gpar(fontface = "bold"), vp = NULL)
  
  dev.off()
}


