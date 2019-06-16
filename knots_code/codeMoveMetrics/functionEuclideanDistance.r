#### custom euclidean distance function ####

# very very fast, but makes assumptions!
# the coordinate system has to be close to cartesian
# DO NOT TRY THIS ON LONG/LAT COORDINATES

# the distance function takes a dataframe, converts to matrix
# assigns the colnames again as x and y

# needs dplyr

funcDistance = function(df, a, b){
  #check for basic assumptions
  assertthat::assert_that(is.data.frame(df),
                          is.character(a),
                          is.character(b),
                          nrow(df) > 1,
                          msg = "some df assumptions are not met")
  # get x and y
  x <- dplyr::pull(df, a); x1 <- x[1:length(x)-1]; x2 <- x[2:length(x)]
  y <- dplyr::pull(df, b); y1 <- y[1:length(y)-1]; y2 <- y[2:length(y)]
  
  # get dist
  dist <- c(NA, sqrt((x1 - x2)^2 + (y1 - y2)^2))
  return(dist)
}
