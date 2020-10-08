#' @title Radius between
#' @author Marina Papadopoulou, Hanno Hildenbrandt
#' @description Calculates the angle in radius between two vectors
#' @param a a 2d vector
#' @param b a 2d vector
#' @return the angle between a and b
#' @export
rad_between <- function(a, b)
{
  c <- perpDot(a,b);
  d <- pracma::dot(a,b);
  return(atan2(c,d));
}

#' @title Perpedicular dot product
#' @author Marina Papadopoulou, Hanno Hildenbrandt
#' @description Calculates the perpedicular dot product of 2 vectors
#' @param a a 2d vector
#' @param b a 2d vector
#' @return the perpedicular dot product of a and b
#' @export
perpDot <- function(a, b)
{
  return(a[1] * b[2] - a[2] * b[1]);
}