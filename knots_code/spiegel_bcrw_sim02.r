
sim <- function(param_list){
  ts_primary <- param_list[[1]]; ts_secondary <- param_list[[2]]; ts_tertiary = param_list[[3]]; n_id <- param_list[[4]]; perception_range <- param_list[[5]]; EtaCRW <- param_list[[6]]; step_length_mean <- param_list[[7]]; step_length_sd <- param_list[[8]]; Kappa <- param_list[[9]]; landscape_size <- param_list[[10]]
  #'ts_primary = day length, ts_secondary = days to simulate in original code
  #'load the tidyverse
  library(tidyverse); library(CircStats); library(dplyr)
  #'how many time steps per id? product of 1e*2e timestep. eg. for 1 day ts_primary = 59 (mins per hour), ts_secondary = 24 (hours per day)
  time_steps <- ts_primary*ts_secondary*ts_tertiary

  #'how many rows in the output dataframe? timesteps * no. of ids
  data_length <- time_steps*n_id

  #'create an empty df for positions
  data <- data_frame(id = as.factor(1:n_id), step = list(1:(ts_primary*ts_secondary*ts_tertiary))) %>% unnest() %>% group_by(id) %>% mutate(hour = cumsum(step %% ts_primary == 0)+1, tide = cumsum(step %% (ts_secondary*ts_primary) == 0)+1, x = NA, y = NA)

  #'set starting parameters
  startIndx <- 1
  Phi_ind <- rep(0, n_id)
  data2 <- list_along(1:n_id)
  HRcentre <- matrix(data = NA, nrow = n_id, ncol = 3)

  #'create an empty matrix for each id in data2
  data2 <- map(data2, function(x){
    matrix(NA, ncol = 2, nrow = time_steps)
  })

  #'get landscape centre and buffer. the centre is the island, and the buffer is the approx water's edge where knots can stand
  library(sf)
  landscape_centre <- st_point(c(0,0))
  #'set one limit of start buffer
  start_buffer_01 <- st_buffer(landscape_centre, dist = landscape_size)
  #'internal limit of start buffer to be either a bit larger or smaller than the external buffer, with sd of 5.0%
  start_buffer_02 <- st_buffer(landscape_centre, dist = landscape_size - landscape_size*0.05)

  #'get the difference between the buffers, this is the "water's edge"
  start_buffer <- st_difference(start_buffer_01, start_buffer_02)

  #'draw random positions within this buffer as start points for the knots. the oversampling is required because st_sample samples in the extent (bounding box) of a polygon, and returns intersecting points.
  start_positions <- st_sample(start_buffer, size = n_id*2)

  #'convert to matrix to use
  start_positions <- st_coordinates(start_positions) %>% as.matrix()

  rm(start_buffer)

  #'assign start position in a loop. these are the formerly defined "homerange centres", but they are now configured to be placed at edges (think of this as the water's edge, where knots feed)
  for(i in 1:n_id){
    data2[[i]][1, ] <- start_positions[i,]

    HRcentre[i, 1:2] <- data2[[i]][1,]
  }

  #'landscape_size during incoming tide
  incoming_tide <- seq(landscape_size, 0, by = -6)[1:(ts_primary*ts_secondary/2)]

  outgoing_tide <- rev(incoming_tide)

  distance_seq <- rep(c(incoming_tide, outgoing_tide), ts_tertiary)[1:time_steps-1]

  water_edge <- map(distance_seq, function(x){st_buffer(landscape_centre, dist = x)}) %>%
    map(function(x){x %>% st_cast("MULTIPOINT") %>% st_coordinates() %>% as.data.frame() %>% st_as_sf(coords = c("X","Y"))})

  #'loop for the simulation
  for (t in 1:(time_steps-1)){
    #'here, set the bias point to be the nearest point on a buffer line at time t.
    #'all possible bias points, where points are on the circle of radius distance_seq[t] m drawn from landscape_centre

    #' loop through individuals
    for (j in 1:n_id){

    #'get distance matrix
    dist <- rep(NA, n_id);
    for (k in 1:n_id) {
      dist[j] <- dist(rbind(data2[[j]][t, ], c(data2[[k]][t, ])))
    }

    #'set self distance to 0
    dist[dist==0] <- NA;#getting rid of the distance to self

    #'generate location at t+1

    #'select a direction
    #'calculating the direction to the water edge (bias point)

    BiasPoint <- as.matrix(st_coordinates(water_edge[[t]][which.min(st_distance(st_point(data2[[j]][t, ]), water_edge[[t]])),]))

    #'individuals prefer agents over HR centre'
    if (min(dist, na.rm=T) <= perception_range) {
      BiasPoint=data2[[which.min(dist)]][t, ]
    }

    #'cheking direction to the Bias point of this individual, change the second ccomp to have another bias
    coo <- BiasPoint - data2[[j]][t, ]
    mu <- Arg(coo[1] + (0+1i) * coo[2])

    #'handle negative directions'
    if (mu < 0)  {mu <- mu + 2 * pi}

    #'bias to initial location + CRW to find the von mises center for next step
    mu.av <- Arg(EtaCRW * exp(Phi_ind[j] * (0+1i)) + (1 - EtaCRW) * exp(mu * (0+1i)))

    #'#choosing curr step direction from vonMises centered around the direction selected above'
    Phi_ind[j] <- rvm(n=1, mean = mu.av, k = Kappa)

    #'perform step'
    #'selection of step size for this id in this state from the specific gamma
    step.length <- rgamma(1, shape = step_length_mean^2/step_length_sd^2,scale = step_length_sd^2/step_length_mean)

    step <- step.length * c(Re(exp((0+1i) * Phi_ind[j])), Im(exp((0+1i) * Phi_ind[j])))
    data2[[j]][t + 1, ] <- data2[[j]][t, ] + step
    }
  }


#'how many times out of the box? think of this as the tracking area
startIndx=1;
for (k in 1:n_id) {
  endIndx=startIndx+time_steps-1;
  data[c(startIndx:endIndx),c("x","y")]=data2[[k]]

  #'storing the sex of this agent sbased on the HR center it got was it a male1 or a female2 there? #'currently meaningless'
  data[c(startIndx:endIndx),c("pseudoSex")]=  HRcentre[k,3]
  startIndx=endIndx+1;
}

rm("Curr_indv","Curr_tmStp","k","Color_indv","PointsStrc","CurDrift","BiasPoint")
rm("Phi_ind","step","step.len","mu","mu.av","coo","StepAsLine","Dist", "endIndx","startIndx","ToPlot")

#'return the dataframe

data[,c("x","y")] = data2 %>% map(as.data.frame) %>% bind_rows()

rm(water_edge)

return(data)

}
