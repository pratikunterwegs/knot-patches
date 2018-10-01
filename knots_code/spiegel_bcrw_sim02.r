
sim <- function(ts_primary, ts_secondary, n_id, perception_range, EtaCRW, step_length_mean, step_length_sd, Kappa, landscape_size){
  #'ts_primary = day length, ts_secondary = days to simulate in original code
  #'load the tidyverse
  library(tidyverse)
  #'how many time steps per id? product of 1e*2e timestep. eg. for 1 day ts_primary = 59 (mins per hour), ts_secondary = 24 (hours per day)
  time_steps <- ts_primary*ts_secondary

  #'how many rows in the output dataframe? timesteps * no. of ids
  data_length <- time_steps*n_id

  #'create an empty df for positions
  data <- data_frame(
    id = as.factor(rep(seq(1:n_id),length.out=data_length,each=time_steps)),
    step = rep(seq(1:time_steps),length.out=data_length),
    day = rep(seq(1:ts_secondary),length.out=data_length,each=ts_primary),
    StepInDay = rep(seq(1:ts_primary),length.out=data_length,each=1),
    burst = as.factor(rep(seq(1:(ts_secondary*n_id)),length.out=data_length,each=ts_primary)),
    x = NA,
    y = NA,
    pseudosex = NA)

  #'set starting parameters
  startIndx <- 1
  Phi_ind <- rep(0, n_id)
  data2 <- enframe(list_along(1:n_id))
  HRcentre <- matrix(data = NA, nrow = n_id, ncol = 3)

  #'create an empty matrix for each id in data2
  data2 <- map(data2, function(x){
    matrix(NA, ncol = 2, nrow = time_steps)
  })

  #'assign start position
  data2 <- map(data2, function(x){
    x[1]
  })


}
