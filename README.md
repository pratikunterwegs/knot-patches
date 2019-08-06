**NB:** Data, if any generated or accessed, belong to GELIFES-RUG and COS-NIOZ and/or relevant members. See contact details.

# Code for: Experimental behaviour scores predict free-living space-use

## Attribution

Please contact the following before cloning or in case of interest:

- Pratik Gupte (code maintainer)
  - p.r.gupte@rug.nl
  - rug.nl/staff/p.r.gupte
  - Nijenborgh 7/5172.0583 9747AG Groningen

- Allert Bijleveld (PI): allert.bijleveld@nioz.nl

- Selin Ersoy (collab): selin.ersoy@nioz.nl

Contact Allert for data.

## Downloading data and cleaning

1. run `codeGetData/code_getData2018.r` (**This file is not on the repo.**)
    1. filters on wild knots
    2. gets all fixes from 1st to last
    3. removes beacons
    4. writes data to rdata file with 10 ids per file
    5. reads all rdata files, combines to one df
    6. writes combined files as rdata - `../data2018/*.Rdata`

2. run `codeBehavMetrics/code_experimentData.r`
    1. reads in behavioural score and release data csvs. These are three separate files (one for _ranef_ scores, one for _F01_ scores, and one for morphometry)
    2. writes cleaned data with selected columns to csv: `../data2018/behavScoresRanef.csv`


3. run `codeGetData/code_tidalIntervals2018.r` (**This file is not on the repo.**)
    1. reads west terschelling waterlevel csv
    2. selects a measure of waterlevel
    3. reads `codeGetData/high_low_tide.R` function
    4. calcualtes tides
    5. writes high and low tide times to csv: `tidesSummer2018.csv`

## Prepare data

4. run `codeMakeResults/code_prepData.r`
    1. reads in `.Rdata` files created by **step 1.vi**
    2. writes each individual to csv file in folder: `../data2018/oneHertzData`
    3. reads in the tidal cycle data `data2018/tidesSummer2018.csv`
    4. assigns the tidal cycle to each position
    5. calculates the time since high tide
    6. **overwrites** data (from **4.ii**) with tidal cycles to csv

5. run `codeMakeResults/code_addMoveMetrics.r`
    1. reads in release data created in **2.ii**
    2. reads in each csv from **4.vi** and assigns `id` column
    3. removes data before the official release time + 24 hrs
    4. removes id and tidal cycle combinations with less than 2 rows
    5. calculates the distance between successive positions for each individual in each tidal cycle
    6. write the output of **5.v** to file as csv: `../data2018/oneHertzData/recursePrep`

## Make residence patches

6. run `codeMakeResults/code_doRecurse.r`
    1. reads in recurse data locs from **5.v**
    2. sets recurse radius to 50m
    3. gets recursion on each individual-tidal cycle combination
    4. assigns residence time as the time within 50m of each point, but only before any long absences (60 mins)
    5. calculates FPT and number of revisits as normal in `recurse`[^1]
    6. merges recurse output with prepared data and writes to csv: `../data2018/oneHertzData/recurseData`

7. run `codeMakeResults/code_residencePatchMetrics.r`
    1. reads in aux functions `codeMoveMetrics/functionEuclideanDistance.r` and `codeMakeResults/func_residencePatch.r`
    2. reads in recurse data locs from **6.vi** and prepared data from **5.v**
    3. assigns a point as residence point if residence time is below 2 minutes, removes other points
    4. applies the `funcGetResPatches` function to the residence points
    5. collects residence patch data and writes to file: `../data2018/oneHertzData/data2018patches.csv`

## Work with residence patches

8. run `codeMakeResults/code_distanceMCP.r`
    1. reads in data prepared by **5.vi**
    2. calculates total distance and convex hull area and writes to file: `../data2018/oneHertzData/dataMCParea.csv`
    3. writes the irregular boundary of unioned MCPs to file `../data2018/spatials/newUnionPatches/unionPatches.shp`

9. run `codeMakeResults/code_statsCoarseMetrics.r`
    1. reads in patch size data output from **8.ii**
    2. reads in behaviour scores from **2.ii** and joins to **8.ii**
    3. prepares data for models to be run automatically, and add model as a list column - running models with and without id as REff
    4. writes model output to file with and without id as REff
    5. prepares data and plots fig04: `../figs/fig04coarseMetrics.pdf`

10. run `codeMakeResults/code_statsPatchMetrics.r`
    1. reads in data from **7.v**
    2. reads in behaviour scores from **2.ii** and joins to **8.ii**
    3. prepares data for different variables related to explore score
    4. runs models as above, not including id as REff
    5. write model summaries to file
    6. prepare data and plot fig05: `../figs/fig05patchMetrics.pdf`

    ![Figure 5](../figs/fig-1.png)


## Aux files

11. `func_residencePatch.r`: finds residence patches
12. `functionEuclideanDistance.r`: a custom, vectorised distance function
13. `codePlotOptions/`: custom ggplot themes.

---

[^1]: [Bracis et al. (2018)](https://onlinelibrary.wiley.com/doi/abs/10.1111/ecog.03618)
