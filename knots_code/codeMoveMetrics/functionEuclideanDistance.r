#### custom euclidean distance function ####

# very very fast, but makes assumptions!
# the coordinate system has to be close to cartesian
# DO NOT TRY THIS ON LONG/LAT COORDINATES

# the distance function takes a dataframe, converts to matrix
# assigns the colnames again as x and y

funcDistance = function(a, x, y){
  #check for basic assumptions
  assertthat::assert_that(is.data.frame(a),
                          is.character(x),
                          is.character(y),
                          nrow(a) > 1)
  # subset the dataframe, make matrix, set the new colnames
  a = as.matrix(a[c(x,y)])
  colnames(a) = c(x,y)
  
  # make a vector with trailing NA to store distances
  b = vector()
  for(i in 1:nrow(a)-1){
    b[i] = (sqrt((a[i,"x"] - a[i+1, "x"])^2 + (a[i,"y"] - a[i+1, "y"])^2))
  }
  b = c(b, NA)
  
  # return b
  return(b)
}
