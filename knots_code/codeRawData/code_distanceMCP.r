#### code to get total distance and mcp ####

library(tidyverse); library(data.table)
library(glue)
library(sf)

# list files
dataFiles <- list.files("../data2018/oneHertzData/recursePrep/", full.names = T)

data <- map(dataFiles, function(filename){
  
  # read in data
  df <- fread(filename)[,.(x,y,time,id, tidalcycle, dist)]
  
  # message
  print(glue('bird {unique(df$id)} in tide {unique(df$tidalcycle)} has {nrow(df)} obs'))
  
  # makde df
  setDF(df)
  
  tryCatch(
    # make sf, union, get convex hull area
    {mcp <- st_as_sf(df, coords = c("x","y")) %>% st_union() %>% st_convex_hull() %>% st_area()},
    error = function(e){ print(glue('problems with bird {unique(df$id)} in tide {unique(df$tidalcycle)}'))})
  
  tryCatch(
  # sum distance
  {df <- setDT(df)[,.(totalDist = sum(dist, na.rm = T)), by=list(id, tidalcycle)]},
  error = function(e){ print(glue('problems with bird {unique(df$id)} in tide {unique(df$tidalcycle)}'))})
  
  # add area
  df[,mcpArea:=mcp]
  
  # make df
  setDF(df)
  
  # return
  return(df)
  
})

# filter data because there were problems with 1 row data
data <- keep(data, function(z){
  # check if both mcp area and dist are present
  sum(c("totalDist", "mcpArea") %in% names(z)) == 2
})

# bind to df
data <- bind_rows(data)

# write to file
fwrite(data, file = "../data2018/oneHertzData/dataMCParea.csv")

#### plot mcp and distance vs explore score ####
# read in behav scores
behavScore <- read_csv("../data2018/behavScores.csv")

# pot ops
source("codePlotOptions/ggThemeKnots.r")

# simple ci function
ci = function(x){
  qnorm(0.975)*sd(x, na.rm = T)/sqrt((length(x)))
}

# join explore score and area dist data
data = inner_join(data, behavScore, by = "id")

# get summary, all in KILOMETRES OR KM^2
dataSummary = data %>% 
  mutate(mcpArea = mcpArea/(1e3*1e3), totalDist = totalDist/1e3,
         exploreBin = plyr::round_any(exploreScore, 0.2)) %>% 
  select(totalDist, mcpArea, exploreBin) %>% 
  gather(variable, value, -exploreBin) %>% 
  group_by(exploreBin, variable) %>% 
  summarise_at(vars(value), list(~mean(.), ~ci(.)))

# plot
ggplot(dataSummary)+
  geom_pointrange(aes(x = exploreBin, y = mean, ymin=mean-ci, ymax=mean+ci))+
  facet_wrap(~variable, scales = "free")+
  scale_x_continuous(breaks = unique(dataSummary$exploreBin))+
  themePubLegKnots()+
  labs(x = "exploration score", y = bquote("mean ± 95% CI (km or km"^2~")"))

# save plot
ggsave(filename = "../figs/figMCPareaExploreScore.pdf", height = 3, width = 6)
