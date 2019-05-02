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
	e. writes cleaned data to csv

## adding metadata

6. run `codeDataSummary/code_assignTidalCycle.r`
	a. reads in the cleaned data
	b. reads in the tidal cycle data `data2018/tidesSummer2018.csv`
	c. assigns the tidal cycle to each position
	d. calculates the time since high tide
	e. summarises expected fixes per tidal cycle per id
	f. plots realised/expected fixes proportion
	g. writes data with tidal cycles to csv

7. run `codeMoveMetrics/code_distanceTides.r`
	a. reads file of fixes with tidal cycle
	b. removes id ~ tidal cycle combos with < 2 rows
	c. calculates euclidean distance between successive points
	d. saves distances as an rdata object
	e. writes csv of positions with distances

8. run `codeMoveMetrics/code_departGriend.r`
	a. reads file with assigned tidal cycles
	b. calculates the last day of tracking for each id, the track duration, and the residence duration
	c. writes last tracking day data to file
	d. reads shapefile of griend
	e. subsets data outside 5km from griend centroid
	f. calculates the time between release and first fix outside the 5km buffer
	g. writes above data to file
	h. calculates max and min distance to griend per id per tide
	i. plots above data and saves to file

9. run `codeMoveMetrics/code_roostFinding.r`
	a. reads shapefile of island roosts
	b. reads positions with assigned tidal cycle
	c. calculates distance from each pos to each roost 3 hours before and after high tide
	d. calculates the proportion of roosting time spent on griend per tidal cycle
	e. writes roost choice data to file
	f. plots roost choice griend per id per tide and saves to file

10. run `codeMoveMetrics/code_FPT.r`
	a. reads in file with fixes and assigned tidal cycles
	b. filters data for >= .33 duration and fixes per id-tide
	c. writes filtered data to file
	d. splits data by id-tide
	e. writes split data to separate files
	f. runs recurse analysis on each file separately, reading in and writing revisit statistics
	g. reads in all recurse data, binds and writes to file

## getting social environment

11. run `codeSocialEnv/code_distMatrix.r`
	a. reads in file with tidal cycles assigned
	b. calculates pairwise distances between birds
	c. writes id wise distances to other ids to csv

12. run `codeSocialEnv/code_nndMetrics.r`
	a. reads in files of id wise distances to other ids
	b. counts neighbours within some distances
	c. identifies the 5 nearest neighbours
	d. writes the full data to file
	e. reads in written data above
	f. summarises number of neighbours per id per tidal cycle per distance class
	g. plots a heatmap of neighbours as above and saves to file

## statistics

13. run `code_moveRepeatability.r` 
	a. reads file of positions with distances
	b. summarises number of fixes, distance per tide, per id
	c. filters data to keep only id-tide combos where proportion of fixes >= .33
	d. plots a heatmap of distance per tide per id scaled by proportion of fixes
	e. runs a GLMM of distance per tide ~ duration + identity
	f. reads a custom function for repeatability
	g. calculates population level repeatability from the GLMM

## auxiliary files

14. `codePlotOptions/ggThemePub.r` provides custom ggplot theme
15. `codePlotOptions/geomFlatViolin.r` provides the half violin plot
16. `codeMoveMetrics/functionEuclideanDistance.r` calculates the euclidean distance between coordinate pairs
17. `codeMoveMetrics/functionGetRepeatability.r` calculates repeatability from linear mixed models of the class `lme4`
18. `codeMoveMetrics/code_make2018Tracks.r` makes and saves shapefiles of tracks, and plots a multipanel zoomable figure of tracks