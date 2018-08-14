#### PSKF for ToA t_dat ####

#helper/wrapper function for easy integration of PSKF for ATLAS t_dat
# INPUT:
# ATLAS data with covariance matices as retrieved from the online t_datbase or an offline sqlite file

# question: does the toa data come with covariance matrices?

#source useful packages: most important are plyr, dplyr (in that order), and lubridate
source(file="libs.R")

# OUTPUT:
# kalman filtered xy coordinates with standard deviation
PSKFForATLAS = function (t_dat) {
  # order the t_dat by TIMEstamp, modified to use dplyr
  t_dat = t_dat %>% arrange(TIME)

  # get first TIMEstamp. min(t_dat$TIME) would be my preferred way of doing it
  t0 = t_dat$TIME[1]

  # estimate sampling rate from t_dat
  #'the toa system has a known sampling frequency of 1Hz, making lags 1s
  dt = round(min(diff(t_dat$TIME))/1e3)*1e3

  # kalman filter base settings
  #'what do these matrices help with? currently unknown. why are they this way? unknown
  S = matrix(c( 1,0,1,0,0,1,0,1,0,0,1,0,0,0,0,1),nrow=4,ncol=4,byrow=T) # state transition matrix
  O = matrix(c( 1,0,0,0,0,1,0,0),nrow=2,ncol=4,byrow=T)                 # observation matrix
  SDIM = 4                                                              # state dimensions (x,y,.x,and.y)
  ODIM = 2                                                              # observation dimensions (x and y)

  #build dataset
  # get n, the number of observations in terms of the minimum observation interval: round_up((max_obs_TIME - min_obs_TIME)/observation_interval)+1

  n = ceiling((t_dat$TIME[nrow(t_dat)] - t0)/dt)+1

  #'create a numeric of the length of n (see above)

  #'bug: vector cannot be of size infinity. likely occuring because dt is calculated to be 0.
  type = numeric(n)
  #'assign i and j, what are they for? unknown
  j = 1
  i = 1

  #'get t, the first TIMEstamp minus the sampling frequency, ie, one sampling interval before the first osbervation
  t = t0 - dt

  #'create matrices of NA of varying dimensions
  tmp_cov = matrix(NA,2,2) # 2x2 matrix
  tmp_y = matrix(NA,2,1) # 2x1 matrix
  tmp_t = matrix(NA,1,1) # 1x1 matrix


  #'create a list of length n, each element a list consisting of TIME, y, and cov as defined above
  observations = rep(list(list(TIME=tmp_t,y=tmp_y,cov=tmp_cov)),n)
  #'j has a value of 1; manually assigned (see above)'
  while (j<=n)
  {
    t = t + dt #'set t to be the first observation in the first run, and then increase by one sampling interval per run (in our case, 1 second)'

    observations[[j]]$TIME = t #'to each element of the list of observations assign the sub-element "TIME" to be of value t'

    if (is.na(abs(t - t_dat$TIME[i]))) { next } else {

    if (abs(t - t_dat$TIME[i])< 500) #'check if TIME difference between the i-th position (t_dat$TIME[i]) and the expected i-th position (t) is less than 500 seconds'
    {
      t = t_dat$TIME[i] #'assign the observed i-th position to the expected i-th position'
      type[j] = 1 #'assign a value of 1 to the j-th element of the numeric created above; i and j have the same value'
      observations[[j]]$y   = matrix(c(t_dat$X[i],t_dat$Y[i]),nrow=1,ncol=2,byrow=T) #'assign position at the j-th location'
      observations[[j]]$cov = matrix(c(t_dat$VARX[i],t_dat$COVXY[i],t_dat$COVXY[i],t_dat$VARY[i]),nrow=2,ncol=2,byrow=T) #'assign var x, cov xy and var y as a matrix'
      i=i+1 #'move to the next TIMEstamp'
    }
  }
    j=j+1 #'move to the next observation'
  }

  # apply Kalman filter
  s_cov = diag(SDIM)

  #'source PSKF and InvChol from file
  source(file="InvChol.R")
  source(file="PSKF.R")

  estimates = PSKF(S, s_cov, O, observations) #'the PSKF function must be called from source file'
  # store results to t_dat frame
  kx = matrix(NA,n,1)
  ky = matrix(NA,n,1)
  kstd = matrix(NA,n,1)
  for (i in 1:n)
  {
    kx[i] = estimates[[i]]$estimate[1];
    ky[i] = estimates[[i]]$estimate[2];
    kstd[i] = sqrt(norm(estimates[[i]]$estimateCov[1:2,1:2]))
  }
  kf_dat=data.frame(X=kx,Y=ky,Std=kstd,time_calc=t0+cumsum(rep(dt, n)))
  return(kf_dat)
}
