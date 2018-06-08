source("libs.R")
library(readr)
#'list files
files = list.files("knots_data/recurse_data/", pattern = "k1_revisit", full.names = T)

#'read in files
data = files %>% map(read_csv)

#bind rows
data = data %>% bind_rows()

#'remove cols
data = data %>% select(residence, fpt, time, x, y, id, ht)

#'split by id and ht
data = data %>% dlply(c("id","ht"))

#'remove id and ht
data = data %>%
  map(function(x){
    x %>% select(-id, -ht) %>% mutate(row.id = seq(1:length(x)))
  })

#'rearrange
data = data %>%
  map(function(x){
    x %>% select(residence, row.id, x, y, time, fpt)
  })

#write to file
for(i in 1:length(data)){
  write_csv(data[[i]], path = paste("knots_data/recurse_data/", names(data)[i], "residence_data.csv"), col_names = F)
}
