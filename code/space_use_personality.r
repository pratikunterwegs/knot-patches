## ----prep_libs_2, message=FALSE, warning=FALSE, eval=FALSE--------------------
## # libraries to process data
## library(readr) # using readr here since data is small
## library(purrr)
## library(glue)
## library(dplyr)
## library(tidyr)
## 
## # libraries for stats
## library(lmerTest)
## 
## # libraries for plotting
## library(ggplot2)
## library(ggthemes)
## library(scico)
## library(scales)
## library(gridExtra)
## library(cowplot)
## 
## # ci func
## # simple ci function
## ci <- function(x){
##   qnorm(0.975)*sd(x, na.rm = T)/sqrt((length(x)))}


## ----link_patches_explorescore, eval=FALSE, message=FALSE, warning=FALSE------
## # read in tag info
## tag_info <- read_csv("data/data2018/SelinDB.csv") %>%
##   select(RINGNR, Toa_Tag) %>%
##   filter(!is.na(Toa_Tag))
## 
## # read in updated behavioural data
## behav_score <- read_delim("data/data2018/Selindb-updated_2019-07-17.csv", delim = ";")
## 
## behav_score <- inner_join(tag_info, behav_score, by = c("RINGNR" = "FB")) %>%
##   filter(trial == "F01") %>%
##   select(Toa_Tag, texpl)


## ----eda_patches, eval=FALSE, message=FALSE-----------------------------------
## # read in patch data
## patch_data <- read_csv("data/data2018/patch_summary.csv")
## 
## # process data to plot histograms of area, duration, circularity, displacement
## # propfixes and tidal time
## patch_data <- patch_data %>%
##   select(id, tide_number, area, circularity, duration, dispInPatch, propfixes,
##          tidaltime_mean, distBwPatch) %>%
##   pivot_longer(cols = c(area, circularity, duration, dispInPatch, propfixes,
##                         tidaltime_mean, distBwPatch),
##                names_to = "variable",
##                values_to = "value")
## 
## # filter out 95% values in each variable
## patch_data <- patch_data %>%
##   group_by(variable) %>%
##   mutate(scaled_val = rescale(value)) %>%
##   filter(scaled_val < 0.90)
## 
## # plot histograms
## ggplot(patch_data)+
##   geom_histogram(aes(x = value))+
##   facet_wrap(~variable, scales = "free")+
##   theme_bw()
## 


## ----patch_models, eval=FALSE, message=FALSE, warning=FALSE-------------------
## # read in patch data
## patch_data <- read_csv("data/data2018/patch_summary.csv")
## # filter for patch quality on the proportion of expected fixes acheived
## patch_data <- filter(patch_data, propfixes %between% c(0.2, 1.0))
## 
## # join to behav data
## patch_data <- inner_join(patch_data, behav_score, by=c("id" = "Toa_Tag")) %>%
##   mutate(texpl = as.numeric(texpl)) %>%
##   filter(!is.na(texpl))
## 
## # prepare for simultaneous modelling
## model_data <- setDF(patch_data) %>%
##   pivot_longer(names_to = "response_variable", values_to = "response_value",
##                cols = c(duration, dispInPatch, distBwPatch, area)) %>%
##   group_by(response_variable) %>%
##   nest()
## 
## # run models using glmerTest and get predict output
## model_data <- mutate(model_data,
##                      model = map(data, function(z){
##                        lmer(response_value ~ texpl +
##                               (1|tide_number) +
##                               tidaltime_mean + I((tidaltime_mean)^2),
##                             data = z, na.action = na.omit)})) %>%
## 
##   mutate(predMod = map2(model, data, function(a, b){
##     mutate(b, predval = predict(a, type = "response", newdata = b,
##                                 allow.new.levels = TRUE))
##   }))
## 
## # assign names to model object
## names(model_data$model) <- glue("response = {model_data$response_variable} | predictor = tExplScore")


## ----plot_model_figs, eval=FALSE, message=FALSE-------------------------------
## # prepare data for plotting
## plot_data <- mutate(model_data,
##                     data_expl = map(data, function(df){
##                       select(df, texpl, response_value, tide_number) %>%
##                         filter(tide_number < 100) %>%
##                         mutate(texpl = plyr::round_any(texpl, 0.1)) %>%
##                         group_by(texpl) %>%
##                         summarise_at(vars(response_value),
##                                      .funs = c(~mean(., na.rm=T), ~ci(.)))}))
## 
## # prepare plots to arrange
## plots <- plot_data %>%
##   ungroup() %>%
##   mutate(y = c("time in patch (mins)",
##                "disp in patch (m)",
##                "dist b/w patch (m)",
##                "patch area (m.sq.)"),
##          title = glue::glue('{letters[1:4]} {y}')) %>%
## 
##   # plots column
##   mutate(plot = pmap(select(., data_expl, y, title), function(data_expl, y, title){
##     ggplot(data_expl)+
##       geom_pointrange(aes(x = texpl,
##                           y = mean,
##                           ymin = mean-ci,
##                           ymax = mean+ci),
##                       position = position_dodge(width = 0.01))+
##       scale_y_continuous(labels = scales::comma)+
## #      facet_grid(~phase, scales = "free_x")+
##       #scico::scale_colour_scico(palette = "cork")+
## 
## #
## #       coord_cartesian(xlim = c(0,1),
## #                       ylim = c(quantile(data_expl$mean, 0.00, na.rm = TRUE),
## #                                quantile(data_expl$mean, 0.999, na.rm = TRUE)))+
## 
##       scale_x_continuous(breaks = c(0,0.5,1))+
##       theme_few()+
##       theme(legend.position = "none",
##             #plot.background = element_rect(colour = 1),
##             #plot.margin = unit(rep(0.5, 4), "cm"),
##             #axis.text.y = element_text(angle = 90, vjust = 0.5),
##             plot.title = element_text(face = "bold"))+
##       labs(y = y, title = title,
##            x = "exploration score")
##   }),
##   plot = map(plot, cowplot::as_grob))
## 
## # arrange plots
## 
## plotlist = plots$plot
## 
## {
##   # pdf(file = "../figs/fig05patchMetrics.pdf", width = 8, height = 12)
##   grid.arrange(grobs = plotlist, ncol = 2)
##   # dev.off()
## }
