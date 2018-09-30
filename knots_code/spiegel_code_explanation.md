
# setting model params

`ToPlot` : plot or not, plotting slows down the process

`Color_indv` : colour to plot each invidual

`DayLength` : primary unit of time steps, comprises secondary unit eg. minutes

`DaysToSimulate` : secondary unit of time steps eg. hours

`N_indv` : how many individuals

`Social_Pecrt_rng` : social perception range

`DriftHRCenters` : should the centre of the home range drift or not, supply either 0 (no drift) or 1 (drift)

`DriftStrength` : drift of the HR centre in m/secondary time step unit, eg. m/hour

`DriftasOnce` : when should drift occur (0 = daily drift, 1 = drift in the middle of the run, i.e., when half primary units of each secondary unit have passed, or 2 = drifts at the beginning of a run)

`PropDriftIndiv` : proportion of drifting individuals
