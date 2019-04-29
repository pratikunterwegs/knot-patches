# data handling procedure on 2018 data

all scripts are in `knots_code/`

## downloading data and cleaning

1. run `codeGetData/code_getData2018.r`
	a. filters on wild knots
	b. gets all fixes from 1st to last
	c. removes beacons
	d. writes data to rdata file with 10 ids per file
	e. reads all rdata files, combines to one df
	f. writes combined files as rdata and csv - `data2018.csv`
2. run `codeBehavMetrics/code_experimentData.r`
	a. reads in experiment data csv
	b. writes cleaned data with selected columns to csv
3. run `codeGetData/code_tidalIntervals2018.r`
	a. reads west terschelling waterlevel csv
	b. selects a measure of waterlevel
	c. reads `codeGetData/high_low_tide.R` function
	d. calcualtes tides
	e. writes high and low tide times to csv
4. run `codeDataSummary/code_reduce2018data.r`
	a. reads in each rdata object of 10 ids
	b. groups each id by 10 second intervals
	c. summarises x, y coords as means over 10 second interval
	d. writes rdata to csv file
5. run `codeDataSummary/code_cleanByReleaseDate.r`
	a. reads in each csv file of 10 ids
	b. reads in behav scores with release date
	c. plots figure showing histogram of first fix time - release time
	d. cleans data to remove fixes before release
	
