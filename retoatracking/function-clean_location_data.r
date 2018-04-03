clean<-function(d, mwindow=5, NBS_min=0, VAR_threshold=500000, Plot=FALSE){
	
	### script by Allert Bijleveld
	### version 27 March 2018

	### this functions takes a data frame retrieved with the function get_data() and cleans and filters the data 
	
	#mwindow specifies the window for the median filter
	
	## delete positions with variances above VAR_threshold
	d<-d[d$VARX<VAR_threshold & d$VARY < VAR_threshold & d$NBS>=NBS_min,]
	
	
	if(nrow(d)>1){ #only process data if there is data
	## preprocess data
	# add ID
	d$posID<-1:dim(d)[1]
	# convert timestamp 
	d$ts<-.POSIXct(d$TIME/1000, tz="UTC")
	attributes(d$ts)$tzone <- "CET" 
	## new column with raw data before median filter
	d$X_raw<-d$X
	d$Y_raw<-d$Y

	## apply median filter
	d$X<-rev(runmed(rev(runmed(d$X, mwindow)),mwindow)) #includes reversed smoothing to get rid of a possible phase shift
	d$Y<-rev(runmed(rev(runmed(d$Y, mwindow)),mwindow)) #includes reversed smoothing to get rid of a possible phase shift

	if(Plot==TRUE){
		plot(Y_raw~X_raw,data=d)		
		lines(Y_raw~X_raw, data=d,col=1)
		lines(Y~X, data=d,col=2)
		# add legend
		legend("topleft", legend=c("raw","filter"), pch=c(1,-1), col=c(1,2), bty="n", lty=c(1,1), cex=1)
		}

	## postprocess (clean) data
	d<-d[,c("TAG", "posID", "TIME", "ts", "X_raw", "Y_raw", "NBS", "VARX", "VARY", "COVXY", "X", "Y")]
	
	}else{
	
	d<-data.frame(matrix(NA, nrow = 0, ncol = 12))
	names(d)<-c("TAG", "posID", "TIME", "ts", "X_raw", "Y_raw", "NBS", "VARX", "VARY", "COVXY", "X", "Y")
	}
	
return(d)
}
		