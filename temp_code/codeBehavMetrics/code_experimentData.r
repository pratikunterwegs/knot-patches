#### read experiment data and output clean behav scores ####

# Code author Pratik Gupte
# PhD student
# MARM group, GELIFES-RUG, NL
# Contact p.r.gupte@rug.nl

library(tidyverse)

# read data
# conditional rand effects
dataRanef = read_csv("../data2018/Selindb-ranef.csv") %>% 
  select(-grpvar, -term, FB = grp, ranefScore = condval, ranefSd = condsd)

# transformed explore
dataTexpl = read_delim("../data2018/Selindb-updated_2019-07-17.csv", delim = ";") %>% 
  filter(trial == "F01") %>% 
  rename("tExplScore" = "texpl") %>% 
  mutate(tExplScore = as.numeric(tExplScore))

# morphometric measures
dataMorph = read_csv("../data2018/SelinDB.csv") %>% 
  select(-contains("0"), FB = RINGNR, -X1, status = info, id = Toa_Tag)

# join data
dataExp = inner_join(dataMorph, dataTag) %>% 
  inner_join(dataRanef) %>% inner_join(dataTexpl)

# get individual release times as posixct
dataExp = dataExp %>% 
  mutate(Release_Date = as.POSIXct(paste(Release_Date,
                                         Release_Time,
                                          sep = " "),
                                    format = "%d.%m.%y %H:%M:%S", tz = "Europe/Berlin"))

# export for use
write_csv(dataExp, path = "../data2018/behavScoresRanef.csv")
