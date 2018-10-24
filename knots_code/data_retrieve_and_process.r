
### script by Allert Bijleveld
### version 27 March 2018

### this functions rerieves, cleans and plots the tracking data

## load libraries
#library(OpenStreetMap)
library(stringr)
library(sp)
require("raster")


## load functions
source("data_functions/function-retrieve_location_data.r")
source("data_functions/function-clean_location_data.r")

# set functions
make_spatial<-function(d, crs){
		require(sp)
		coordinates(d) <- ~ X+Y
		utm<-"+proj=utm +zone=31 +datum=WGS84"
		proj4string(d) <- CRS(utm)
		d
		}

#'function to create a bounding box
BBOX<-function(d, buffer){
		# buffer is in meters x en dan y
		bbox<-as.data.frame(t(bbox(d)+matrix(c(-buffer,buffer,-buffer,buffer),nrow=2,byrow=TRUE)))
		names(bbox)<-c("X","Y")
		### make spatial bbox
		coordinates(bbox) <- ~ X+Y
		proj4string(bbox) <- osm()
		## transform to LL
		LL<- "+init=epsg:4326" #LL
		bbox<-spTransform(bbox,LL)
		bbox<-bbox@bbox
		}

## plot tracks from lists
plot_fun = function(d, Pch=19, Cex=0.25, Lwd=1, col, Type="b") {
	points(d, col=col, pch=Pch, cex=Cex, lwd=Lwd, type=Type)
}

# load tower coordinates
#	towers<-read.csv("DATA\\2017\\2017towers.csv", header=FALSE)
#	names(towers)<-c("ID", "X", "Y", "Z")
#	coordinates(towers) <- ~ X+Y
#	utm<-"+proj=utm +zone=31 +datum=WGS84"
#	proj4string(towers) <- CRS(utm)
#	towers<-spTransform(towers,osm())


## set layout
options(scipen=999)


##specify data retrieval parameters
	### for rd knots
		 tx<-c(150:255)#knots part 1
		# tx<-c(255:375)#knots part 2

		# whole season
		 from="2017-08-23 13:52:00"; to="2017-10-31 14:52:00"


	### for sanderling
	#	tags<-1:150
	#	from="2017-07-20 18:00:00";to="2017-10-01 23:00:00"


## remove beacons form tags
tags<-tx[!tx%in%c(21,120, 253, 254, 255)]


## convert tags to three characters
tags<-str_pad(as.character(tags), 3, pad = "0")


#############
# get, clean and process data
#####################

	## get data from server #'get only first 10
	ldf_raw <- lapply(tags[1:10], get_data, from=from, to=to, tag_prefix="31001000")

	## clean data with a simple median filter
	ldf <- lapply(ldf_raw, clean, mwindow=5, NBS_min=3, VAR_threshold=10000)	#10000
	# remove empty tracks
	prop_limit<-0.0	#proportion of tracks
	ldf_n <- lapply(ldf, nrow)
	n<-unlist(ldf_n)
	## fraction of max no. of positions
		Hz<-1	#knots
		# Hz<-1/4	#3tenen
	n<-n/(as.numeric(difftime(to,from,units="sec"))*Hz)
	select<- n>prop_limit	# meer dan fractie x van de mogelijke posities moeten getracked zijn
	ldf<-ldf[select]
	tags<-tags[select]

	# make spatial data frames
	ldf_utm <- lapply(ldf, make_spatial)
	ldf_osm <- lapply(ldf_utm, spTransform, osm())

	## get time ranmge of data
		# whichTimes<-function(x,colName){
			# range(x[,c(colName)])
			# }
		# lapply(ldf, whichTimes, colName="ts")


### load map and get bounding box
	## get bounding box from data
	Bbox<-lapply(ldf_osm,BBOX,buffer=2000)
	xrange<-range(unlist(lapply(Bbox, `[`,1,)))
	yrange<-range(unlist(lapply(Bbox, `[`,2,)))
	Bbox<-cbind(rev(yrange), xrange)
	## specify custom bbox
	# Bbox<-rbind(c(53.305, 5.11), c(53.228, 5.33))#R+G


	## load map with bbox
	map <- openmap(Bbox[1,],Bbox[2,],type='bing')


#############
## plot data
############

	## get colours for different individuals
	COL=rainbow(length(ldf_osm))
	## get size of plot
	px_width  <- map$tiles[[1]]$yres[1]
	px_height <- map$tiles[[1]]$xres[1]

	## initiate plotting window
	ppi=96
	x11(width=px_width/ppi, height=px_height/ppi) #'replac with x11 for linux
	par(bg="black")
	par(xpd=TRUE)

	## make plot
	plot(map)

	# add towers #'tower locs not available
	#points(towers$X,towers$Y,pch=23, cex=2,col=2,bg=1)

	mapply(plot_fun, d = ldf_osm, Pch=19, Cex=0.3, Lwd=1, col = COL, Type="l") # type = "o" for lines thorugh points

	## add legend
	legend("topleft", c("receiver stations",tags) , col=c("red",COL), pt.bg=c("black",COL),pch=c(23,rep(21,length(COL))),text.col="white", cex=1,pt.cex=2,bty = "n")

	## add scalear
	fr=0.02
	ydiff<-diff(par('usr')[3:4])
	xdiff<-diff(par('usr')[1:2])
	xy_scale<-c(par('usr')[1]+xdiff*fr, par('usr')[3] + ydiff*fr)
	scalebar(1000, xy_scale,type='line', divs=4, lwd=3, col="white", label="1 km")
