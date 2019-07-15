#### code to test different distributions ####

# load libs
library(data.table)
library(tidyr); library(dplyr); library(purrr)
library(stringr)

# source movement lib
source("codeMoveMetrics/functionEuclideanDistance.r")

# simple ci function
ci = function(x){
  qnorm(0.975)*sd(x, na.rm = T)/sqrt((length(x)))}

# read data and nest, separating into random walk and levy flight data frames
data <- fread("simMoveDiff/dataSimMoveDiff.csv") %>% 
  setDF() %>% 
  group_by(id, replicate, moveProb, moveScale) %>% nest() %>% 
  # separate using select
  mutate(Rw = map(data, function(df){
    df %>% select(-matches(c("Lf"))) %>% rename("x" = "xRw", "y"="yRw") %>% 
      mutate(simtype = "rw")
  }),
  Lf = map(data, function(df){
    df %>% select(-matches(c("Rw"))) %>% rename("x" = "xLf", "y" = "yLf") %>% 
      mutate(simtype = "lf")
  })) %>% 
  # gather by sim type
  select(-data) %>% 
  gather(sim, data, -id, -replicate, -moveProb, -moveScale)

# subsample data at 10 - 60% to mimic imperfect sampling  
data <- data %>% 
  mutate_at(vars(data), list(~map(., function(df){
    sample_frac(df, runif(1, 0.1, 0.6))})))

# calculate total distance, MCP area, nFixes as for emp data
library(sf)

dataSummary <- data %>% 
  # on each of the two kinds of sim data
  mutate_at(vars(data), 
            # map the following funcs
            list(#~map_chr(., function(df){unique(df$simtype)}),
                 ~map_int(., nrow),
                 ~map_dbl(., function(df){
                   # sum the distance
                   sum(funcDistance(df), na.rm = T)
                 }),
                 ~map_dbl(., function(df){
                   # get the MCP area
                   st_as_sf(df, coords = c("x","y")) %>% 
                     st_union() %>% 
                     st_convex_hull() %>% 
                     st_area()
                 }))) %>% 
  select(-data)

# rename cols
names(dataSummary) <- c("id", "replicate", "moveProb", "moveScale",
                        "simtype", "fixes","distance","area")

# prep for model
modData <- dataSummary %>% 
  # gather by response variable
  gather(respvar, simval, -id, -replicate, -fixes, -moveProb, -moveScale, -simtype) %>% 
  # group by sim type and resp and nest, allows same model code on each df
  group_by(simtype, respvar) %>% 
  nest()
