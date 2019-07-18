#### code for models ####

library(data.table); library(tidyverse)
library(lmerTest)

# simple ci function
ci = function(x){
  qnorm(0.975)*sd(x, na.rm = T)/sqrt((length(x)))}

#### load data ####
# read mcp and dist data
data <- fread("../data2018/dataMCParea.csv")
setDF(data)

# read number of fixes
recPrepFiles <- list.files("../data2018/oneHertzData/recursePrep/", full.names = T)

# read in data and ask how many rows
recPrepData <- map_df(recPrepFiles, function(z){
  fread(z)[,.N,by=list(id, tidalcycle)]
})

#save to file
fwrite(recPrepData, "../data2018/data2018idTideCount.csv")

# read in file
recPrepData <- fread("../data2018/data2018idTideCount.csv")

data <- merge(data, recPrepData, all = FALSE, no.dups = TRUE)

#### run coarse scale area and distance models ####
# prepare the data for both models at the same time
modsCoarse <- data %>% 
  # mutate(tidestage = factor(ifelse(between(tidaltime_mean, 4*60, 9*60), "lowTide", "highTide"))) %>% 
  select(totalDist, mcpArea, exploreScore, fixes = N, id, tidalcycle) %>% 
  drop_na() %>% 
  gather(respVar, empVal, -exploreScore, -fixes, -id, -tidalcycle) %>% 
  nest(-respVar)

# add the model object as a new list column
# can't use tidal cycle as a random effect because it causes singularities
# ie, only one measure per combination of random effects
modsCoarse <- modsCoarse %>% 
  # run models with id as a random effect
  mutate(
    model = map(data, function(z){
      lmer(empVal ~ exploreScore + log(fixes) + (1|id), 
           data = z, na.action = na.omit)
    }))

# get model predictions for explore score,k
# and no random effects
modsCoarse <- modsCoarse %>% 
  mutate(
    # for models without id
    pred = map2(model, data, function(a,b){
      b %>% 
        mutate(predval = predict(a, type = "response", re.form = NULL))
    })
  )

# unnest data for use and summarise
modsCoarseData <- modsCoarse %>% select(respVar, pred) %>% 
  unnest() %>% 
  # now summarise by respVar and binned explore score
  group_by(respVar,
           exploreBin = plyr::round_any(exploreScore, 0.2)) %>% 
  
  mutate(empVal = ifelse(respVar == "totalDist", empVal/1e3, empVal/1e6),
         predval = ifelse(respVar == "totalDist", predval/1e3, predval/1e6)) %>% 
  
  # get mean and ci for plots
  summarise_at(vars(empVal, predval),
               list(~mean(.), ~ci(.)))

# plot
source("codePlotOptions/ggThemeKnots.r")

# write a labeller
coarseMetLabels <- c("mcpArea" = "MCP area (km²)",
                     "totalDist" = "Total distance (km)")


# plot with panels
plotCoarseMetrics <- ggplot(modsCoarseData)+
  geom_pointrange(aes(x = exploreBin, y = empVal_mean,
                      ymin = empVal_mean - empVal_ci,
                      ymax = empVal_mean + empVal_ci#,
                      # shape = tidestage
                      ), size = 0.3)+
  geom_smooth(aes(x = exploreBin, y = predval_mean#, lty = tidestage
                  ), 
              col = 1, method = "lm", fill = "grey80", lwd = 0.3)+
  
  scale_x_continuous(breaks = seq(-0.4, 1, 0.2))+

  scale_shape_manual(values = c(16, 15))+
  
  facet_wrap(~respVar, scales = "free_y",
                 labeller = labeller(respVar = coarseMetLabels),
                 strip.position = "left")+
  themePubKnots()+
  theme(strip.placement = "outside", 
        strip.background = element_blank(),
        strip.text = element_text(face = "plain", hjust = 0.5))+
  labs(y = NULL, x = "exploration score")

# save plot


{pdf(file = "../figs/fig04coarseMetrics.pdf", width = 180/25.4, height = 80/25.4)
  
  print(plotCoarseMetrics);
  grid.text(c("a","b"), x = c(0.1, 0.575), y = 0.95, just = "left",
            gp = gpar(fontface = "bold"), vp = NULL)
  
  dev.off()}

# write model output to file
# write model output to text file
{writeLines(R.utils::captureOutput(map(modsCoarse$model, summary)), 
            con = "../data2018/textCoarseMods.txt")}
