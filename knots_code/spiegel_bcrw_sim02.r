
sim <- function(ts_primary, ts_secondary, n_id, perception_range, EtaCRW, step_length_mean, step_length_sd, Kappa, landscape_size){
  #'ts_primary = day length, ts_secondary = days to simulate in original code
  #'load the tidyverse
  library(tidyverse); library(CircStats); library(dplyr)
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
  data2 <- list_along(1:n_id)
  HRcentre <- matrix(data = NA, nrow = n_id, ncol = 3)

  #'create an empty matrix for each id in data2
  data2 <- map(data2, function(x){
    matrix(NA, ncol = 2, nrow = time_steps)
  })

  #'assign start position in a loop and get the homerange centres
  for(i in 1:n_id){
    data2[[i]][1, ] <-  c(runif(1,min=-landscape_size/3,max=landscape_size/3), runif(1,min=-landscape_size/3,max=landscape_size/3))

    HRcentre[i, 1:2] <- data2[[i]][1,]
  }


  #'loop for the simulation
  for (t in 1:(time_steps-1)){
    #' loop through individuals
    for (j in 1:n_id){

    #'get distance matrix
    dist <- rep(NA, n_id);
    for (k in 1:n_id) {
      dist[j] <- dist(rbind(data2[[j]][t, ], c(data2[[k]][t, ])))}

    #'set self distance to 0
    dist[dist==0] <- NA;#getting rid of the distance to self

    #'generate location at t+1

    #'select a direction
    #'calculating the direction to the initial location (bias point)
    BiasPoint=(data2[[j]][1, ])

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

OutOfTheBox <- data %>% filter(!x %between% c(-landscape_size/2, landscape_size/2), !y %between% c(-landscape_size/2, landscape_size/2)) %>% nrow(.)

print(paste("out of the box rate",round(OutOfTheBox,digit=5)))
rm("Curr_indv","Curr_tmStp","k","Color_indv","PointsStrc","CurDrift","BiasPoint")
rm("Phi_ind","step","step.len","mu","mu.av","coo","StepAsLine","Dist", "endIndx","startIndx","ToPlot")

#'return the dataframe

data[,c("x","y")] = data2 %>% map(as.data.frame) %>% bind_rows()

return(data)

}
