#### code to test custom functions ####

# load libs
library(usethis)
library(assertthat)

#### test euclidean distance function ####
# source distance function
source("codeMoveMetrics/functionEuclideanDistance.r")

# make dummy data
library(tibble)
dummyDf <- tibble(x = 0, y = 1:1e2)

# get distances from function
distance_from_func <- funcDistance(dummyDf)

# get distances from diff
distance_from_diff <- diff(dummyDf$y)

# compare lengths
assert_that(length(distance_from_func) == length(distance_from_diff) + 1,
            msg = "distance function returns one less value than expected")

# compare values
assert_that(sum(distance_from_diff == 
                  distance_from_func[2:length(distance_from_func)]) == length(distance_from_diff))
