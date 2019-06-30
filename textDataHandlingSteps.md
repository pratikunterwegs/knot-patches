# How to handle the 2018 red knot data

Here, I assume you begin from the raw data stored on NIOZ servers, and would like to replicate the results of our forthcoming paper. 

If you need access to these data in advance of publication, please contact **Allert Bijleveld**: allert.bijleveld@nioz.nl.

all scripts are in `knots_code/`

## downloading data and cleaning

**this file is not on the repo**

1. run `codeGetData/code_getData2018.r`
	a. filters on wild knots
	b. gets all fixes from 1st to last
	c. removes beacons
	d. writes data to rdata file with 10 ids per file
	e. reads all rdata files, combines to one df
	f. writes combined files as rdata - `../data2018/*.Rdata`

2. run `codeBehavMetrics/code_experimentData.r`
	a. reads in behavioural score and release data csv
	b. writes cleaned data with selected columns to csv: `../data2018/behavScores.csv`

**this file is not on the repo**

3. run `codeGetData/code_tidalIntervals2018.r`
	a. reads west terschelling waterlevel csv
	b. selects a measure of waterlevel
	c. reads `codeGetData/high_low_tide.R` function
	d. calcualtes tides
	e. writes high and low tide times to csv: `tidesSummer2018.csv`

## prepare data

4. run `codeMakeResults/code_prepData.r`
	a. reads in `.Rdata` files created by **step 1.f**
	b. writes each individual to csv file in folder: `../data2018/oneHertzData`
	b. reads in the tidal cycle data `data2018/tidesSummer2018.csv`
	c. assigns the tidal cycle to each position
	d. calculates the time since high tide
	g. **overwrites** data (from **4.b**) with tidal cycles to csv

5. run `codeMakeResults/code_addMoveMetrics.r`
	a. reads in release data created in **2.b**
	b. reads in each csv from **4.g** and assigns `id` column
	c. removes data before the official release time + 24 hrs
	d. removes id and tidal cycle combinations with less than 2 rows
	e. calculates the distance between successive positions for each individual in each tidal cycle
	f. write the output of **5.e** to file as csv: `../data2018/oneHertzData/recursePrep`

## make residence patches

6. run `codeMakeResults/code_doRecurse.r`
	a. reads in recurse data locs from **5.f**
	b. sets recurse radius to 50m
	c. gets recursion on each individual-tidal cycle combination
	d. assigns residence time as the time within 50m of each point, but only before any long absences (60 mins)
	e. calculates FPT and number of revisits as normal in `recurse`[^1]
	f. merges recurse output with prepared data and writes to csv: `../data2018/oneHertzData/recurseData`

7. run `codeMakeResults/code_residencePatchMetrics.r`
	a. reads in aux functionstions `codeMoveMetrics/functionEuclideanDistance.r` and `codeMakeResults/func_residencePatch.r`
	b. reads in recurse data locs from **6.f** and prepared data from **5.f**
	c. assigns a point as residence point if residence time is below 2 minutes, removes other points
	d. applies the `funcGetResPatches` function to the residence points
	e. collects residence patch data and writes to file: `../data2018/oneHertzData/data2018patches.csv`

## work with residence patches

8. run `codeMakeResults/code_patchSizeVsTestScore.r`
	a. reads in patch size data output from **7.e**
	b. reads in behaviour scores from **2.b**
	c. plots patch metrics against exploration score at 0.2 score unit bins

9. run `codeMakeResults/code_distanceMCP.r`
	a. reads in data prepared by **5.f**
	b. calculates total distance and convex hull area and writes to file: `../data2018/oneHertzData/dataMCParea.csv`
	c. plots distance and area against exploration score at 0.2 score unit bins

## aux files
10. `func_residencePatch.r`: finds residence patches
11. `functionEuclideanDistance.r`: a custom, vectorised distance function
12. `codePlotOptions/`: custom ggplot themes.

---

[^1]: [Bracis et al. (2018)](https://onlinelibrary.wiley.com/doi/abs/10.1111/ecog.03618)