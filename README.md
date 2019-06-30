**NB:** Data, if any generated or accessed, belong to GELIFES-RUG and COS-NIOZ and/or relevant members. See contact details.

# Publication branch of Wadden Sea ATLAS project

## What?

Publication branch of the repository containing code from ATLAS tracking in the Wadden Sea. *This is probably the branch you're looking for.*

Unlike the other branches, this branch contains only code relevant to the upcoming paper.

## Who?

Please contact before cloning or in case of interest:

Contact:
- Pratik Gupte: p.r.gupte@rug.nl, pratik.gupte@nioz.nl
  Nijenborgh 7/5172.0583 9747AG Groningen

- Allert Bijleveld: allert.bijleveld@nioz.nl

- Selin Ersoy: selin.ersoy@nioz.nl

# How to handle the 2018 red knot data

Here, I assume you begin from the raw data stored on NIOZ servers, and would like to replicate the results of our forthcoming paper. 

If you need access to these data in advance of publication, please contact **Allert Bijleveld**: allert.bijleveld@nioz.nl.

all scripts are in `knots_code/`

## Downloading data and cleaning

**This file is not on the repo.**

1. run `codeGetData/code_getData2018.r`
    1. filters on wild knots
    2. gets all fixes from 1st to last
    3. removes beacons
    4. writes data to rdata file with 10 ids per file
    5. reads all rdata files, combines to one df
    6. writes combined files as rdata - `../data2018/*.Rdata`
2. run `codeBehavMetrics/code_experimentData.r`
    1. reads in behavioural score and release data csv
    2. writes cleaned data with selected columns to csv: `../data2018/behavScores.csv`

**This file is not on the repo.**

3. run `codeGetData/code_tidalIntervals2018.r`
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
    1. reads in aux functionstions `codeMoveMetrics/functionEuclideanDistance.r` and `codeMakeResults/func_residencePatch.r`
    2. reads in recurse data locs from **6.vi** and prepared data from **5.v**
    3. assigns a point as residence point if residence time is below 2 minutes, removes other points
    4. applies the `funcGetResPatches` function to the residence points
    5. collects residence patch data and writes to file: `../data2018/oneHertzData/data2018patches.csv`

## Work with residence patches

8. run `codeMakeResults/code_patchSizeVsTestScore.r`
    1. reads in patch size data output from **7.v**
    2. reads in behaviour scores from **2.ii**
    3. plots patch metrics against exploration score at 0.2 score unit bins

9. run `codeMakeResults/code_distanceMCP.r`
    1. reads in data prepared by **5.vi**
    2. calculates total distance and convex hull area and writes to file: `../data2018/oneHertzData/dataMCParea.csv`
    3. plots distance and area against exploration score at 0.2 score unit bins

## Aux files

10. `func_residencePatch.r`: finds residence patches
11. `functionEuclideanDistance.r`: a custom, vectorised distance function
12. `codePlotOptions/`: custom ggplot themes.

---

[^1]: [Bracis et al. (2018)](https://onlinelibrary.wiley.com/doi/abs/10.1111/ecog.03618)