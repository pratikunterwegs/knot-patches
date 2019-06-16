#### custom euclidean distance function ####

# very very fast, but makes assumptions!
# the coordinate system has to be close to cartesian
# DO NOT TRY THIS ON LONG/LAT COORDINATES

# the distance function takes a dataframe, converts to matrix
# assigns the colnames again as x and y

funcDistance = function(df, x, y){
  #check for basic assumptions
  assertthat::assert_that(is.data.frame(df),
                          is.character(x),
                          is.character(y),
                          nrow(df) > 1,
                          msg = "some df assumptions are not met")
  dist <- sqrt((df$x[2:length(df$x)] - df$x[1:length(df$x)-1])^2 + 
                 (df$y[2:length(df$y)] - df$y[1:length(df$y)-1])^2)
  return(c(NA,dist))
}
