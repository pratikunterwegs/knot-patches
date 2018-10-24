get_data<-function(tag, from, to, tag_prefix="31001000"){

### script by Allert Bijleveld
### version 27 March 2018

#### this functions connects to the database and get's the raw data

## parameter info
	# tag = tag number (three digits)
	# from and to are POSIXct, format: "2017-08-27 10:27:46.098" in Central European Time
	# tag_prefix="31001000" that secifies tag range

# example parameters
	# tag = 250
	# from<-"2017-08-27 09:30:00"	# timezone = CET
	# to<-"2017-08-27 11:30:00"	# timezone = CET
	# tag_prefix="31001000"

require(RMySQL)

### Connect to ATLAS
mydb = dbConnect(MySQL(), user="atlaskama", password="wingdata78", dbname="atlas", host="abtdb.nioz.nl")

## process parameters
tag<- paste(tag_prefix,tag,sep="")
## convert to datetime format
	from <- as.POSIXct(from, tz="CET")
	to <- as.POSIXct(to, tz="CET")
	## convert to UTC (which is the database format)
	attributes(from)$tzone <- "UTC"
	attributes(to)$tzone <- "UTC"
	## Convert to numeric and ms (database format)
	from<-as.numeric(from) * 1000
	to<-as.numeric(to) * 1000

## SQL code to retrive data
	sql<-paste("select * from LOCALIZATIONS where TAG = ", tag, " AND ","TIME > '",from,"' AND ","TIME < '",to,"' ","ORDER BY TIME ASC",sep="")

# getdata
d<-dbGetQuery(mydb, sql)

## close connection
dbDisconnect(mydb)

## or close all connections
#lapply( dbListConnections(MySQL()), function(x) dbDisconnect(x)

return(d)
}
