# #### code to get residence patches manually ####

# all of this uses algorithmic segmentation, which is just silly 

# # load libs
# library(tidyverse); library(data.table)
# 
# #### segmentation ####
# # list files
# dataRevFiles <- list.files("../data2018/oneHertzDataSubset/recurseData/", full.names = T)
# # read in the data
# data <- purrr::map(dataRevFiles, fread)
# 
# # get id.tide names
# library(glue)
# names <- purrr::map_chr(data, function(x){ glue(unique(x$id), 
#                                                 stringr::str_pad(unique(x$tidalcycle), 3, pad = 0),
#                                                 .sep = ".") })
# names(data) <- names
# 
# # subset data, remove 
# data <- data[c(1:5)]
# 
# # get distance data
# dataDist <- fread("../data2018/selRawData/rawdataWithTidesDists.csv")
# 
# ## prep for segmentation
# data <- purrr::map(data, function(df) {
#   df[!is.na(fpt),][,resTime:= ifelse(resTime <= 2, 0, 1e2)][,resTime:= resTime + runif(length(resTime), 0, 0.1)]
# })
# 
# # run segclust on res time
# library(segclust2d)
# # this works fairly well
# dataSeg <- purrr::map(data, function(df){
#   segclust(df, seg.var = c("resTime"), lmin = 50, Kmax = 20,
#            ncluster = 2, 
#            scale.variable = FALSE,
#            diag.var = c("resTime"), sameV = TRUE) %>% 
#     augment()
# })
# 
# #### make plot ####
# # read in griend
# library(ggplot2)
# #griend = sf::st_read("../griend_polygon/griend_polygon.shp")
# plotlist1 <- map(dataSeg, function(df){
#   ggplot(griend)+
#     geom_sf()+
#     geom_point(data = df,
#                aes(x,y, col = resTime > 2),
#                size = 0.2, shape = 16)+
#     scale_color_brewer(palette = "Set1")+
#     theme(legend.position = "bottom")+
#     labs(title= glue(unique(df$id), unique(df$tidalCycle), .sep="_"), 
#          colour = "residence time > 2 minute",
#          subtitle = "manual residence time")
# }) %>% map(function(x) ggplotGrob(x))
# 
# plotlist2 <- map(dataSeg, function(df){
#   ggplot(griend)+
#     geom_sf()+
#     geom_point(data = df,
#                aes(x,y, col = factor(state_ordered)),
#                size = 0.2, shape = 16)+
#     scale_color_brewer(palette = "Set1")+
#     theme(legend.position = "bottom")+
#     labs(title = glue(unique(df$id), unique(df$tidalCycle), .sep="_"),
#          subtitle="segmented on residence time", 
#          colour = "class")
# }) %>% map(function(x) ggplotGrob(x))
# 
# # plot grid
# library(gridExtra)
# pdf(file = "../figs/figRawDataSegmentation.pdf", width = 12, height = 8)
# for(i in 1:length(plotlist1)){
#   grid.arrange(plotlist1[[i]], plotlist2[[i]], ncol = 2)
# }
# dev.off()