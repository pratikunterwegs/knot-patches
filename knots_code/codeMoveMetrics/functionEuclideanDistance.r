#### custom euclidean distance function ####

# Code author Pratik Gupte
# PhD student
# MARM group, GELIFES-RUG, NL
# Contact p.r.gupte@rug.nl

# very very fast, but makes assumptions!
# the coordinate system has to be close to cartesian
# DO NOT TRY THIS ON LONG/LAT COORDINATES

# the distance function takes a dataframe, converts to matrix
# assigns the colnames again as x and y

# needs dplyr
library(dplyr)

funcDistance = function(df, a = "x", b = "y"){
  #check for basic assumptions
  assertthat::assert_that(is.data.frame(df),
                          is.character(a),
                          is.character(b),
                          msg = "some df assumptions are not met")
  # check for dataframe length
  assertthat::assert_that(nrow(df) > 1,
                          msg = "dataframe for distance has too few rows")
  
  dist <- dplyr::case_when(nrow(df) > 1 ~ 
                             # get x and y
                             {{x <- dplyr::pull(df, a); 
                             x1 <- x[1:length(x)-1]; 
                             x2 <- x[2:length(x)]}
                             {y <- dplyr::pull(df, b); 
                             y1 <- y[1:length(y)-1]; 
                             y2 <- y[2:length(y)]}
                             # get dist
                             c(NA, sqrt((x1 - x2)^2 + (y1 - y2)^2))},
                           nrow(df) == 1 ~ {0.0},
                           TRUE ~ {as.numeric(NA)})
  
  return(dist)
}


