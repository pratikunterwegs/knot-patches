#### calculate distmatrix metrics ####

#'load libs
library(readr); library(dplyr)

#### investigate file sizes of dist matrices ####
#'list files
distMatrixFiles = list.files(path = "../data2018/distMatrix/", full.names = T)
#'get sizes
print(paste("files are", sum(sapply(distMatrixFiles, file.size))/1e6, "mb"))


#### process files ####
#'for each individual at each time,
#'get the number of birds within 100, 500, 1km
#'get the id of the nearest neighbour

#'write a process function
#'the function is specific to the data structure outputed
#'it requires columns called: focal, nonfocal, timeNum, distance
nnMetrics = function(x){
  #'check x is a data frame
  assertthat::assert_that(is.data.frame(x))
  
  #'check focal, nonfocal, time and distance
  
  #'require dplyr functions
  require(dplyr)
  
  as_tibble(x) %>% 
    group_by(focal, timeNum) %>% 
    summarise(nBirds100 = sum(distance <= 100),
              nBirds500 = sum(distance <= 500),
              nBirds1e3 = sum(distance <= 1000),
              nnId = list(head(nonfocal[order(distance)], 5))) %>% 
    unnest(nnId) %>%
    group_by(timeNum) %>% 
    mutate(col= paste("nnId", seq_along(timeNum), sep="")) %>%
    spread(key = col, value = nnId)
    
  }


#### write loop ####
distanceMetrics = tibble()
for(i in 1:length(distMatrixFiles)){
  
  #'read in data
  data = read_csv(distMatrixFiles[i])
  
  #'get metrics
  data = nnMetrics(data)
  
  #'add to tibble
  distanceMetrics = bind_rows(distanceMetrics, data)
}

#'write to csv as usual
write_csv(distanceMetrics, path = "../data2018/nnData2018.csv")

#'remove all files
rm(list = ls())

#### read in data and plot ####
#'read data
dataNND = read_csv("../data2018/nnData2018.csv")
data = read_csv("../data2018/data2018posWithTides.csv")
rm(dataNND); gc()

#'join data
data = left_join(data, dataNND, by = c("id" = "focal", "timeNum"))

dataSummary = group_by(data, id, tidalCycle) %>% 
  summarise(nN100 = mean(nBirds100, na.rm = T),
            nN500 = mean(nBirds500, na.rm = T),
            nNK01 = mean(nBirds1e3, na.rm = T)) %>% 
  gather(distance, nBirds, -id, -tidalCycle)


#'plot data
source("codePlotOptions/ggThemePub.r")
ggplot(dataSummary)+
  geom_tile(aes(tidalCycle, factor(id), fill = nBirds))+
  scale_fill_viridis_c(option = "magma")+
  facet_wrap(~distance)+
  themePubLeg()+
  ylab("id")+
  ggtitle("Nearest neighbours per tide")+
  theme(axis.text.y = element_text(size = 4))

#'save to file
ggsave(filename = "../figs/figureNeighbours.pdf", device = pdf(), width = 210, height = 297, units = "mm", dpi = 300); dev.off()
