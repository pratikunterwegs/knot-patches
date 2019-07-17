#### read experiment data and output clean behav scores ####

library(readr)

# read data
dataExp = read_csv("../data2018/Selindb-ranef.csv")

# select col and save
behavScores = select(dataExp, grp, condval)

# export for use
write_csv(behavScores, path = "../data2018/behavScoresRanef.csv")
