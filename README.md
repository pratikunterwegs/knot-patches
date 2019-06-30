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
    a. filters on wild knots
    b. gets all fixes from 1st to last
    c. removes beacons
    4. writes data to rdata file with 10 ids per file
    5. reads all rdata files, combines to one df
    6. writes combined files as rdata - `../data2018/*.Rdata`
2. run `codeBehavMetrics/code_experimentData.r`
    1. reads in behavioural score and release data csv
    2. writes cleaned data with selected columns to csv: `../data2018/behavScores.csv`

**This file is not on the repo.**

3. run `codeGetData/code_tidalIntervals2018.r`
    1. reads west terschelling waterlevel csv
    1. selects a measure of waterlevel
    1. reads `codeGetData/high_low_tide.R` function
    1. calcualtes tides
    1. writes high and low tide times to csv: `tidesSummer2018.csv`

## Prepare data

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

## Make residence patches

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

## Work with residence patches

8. run `codeMakeResults/code_patchSizeVsTestScore.r`
    a. reads in patch size data output from **7.e**
    b. reads in behaviour scores from **2.b**
    c. plots patch metrics against exploration score at 0.2 score unit bins

9. run `codeMakeResults/code_distanceMCP.r`
    a. reads in data prepared by **5.f**
    b. calculates total distance and convex hull area and writes to file: `../data2018/oneHertzData/dataMCParea.csv`
    c. plots distance and area against exploration score at 0.2 score unit bins

## Aux files

10. `func_residencePatch.r`: finds residence patches
11. `functionEuclideanDistance.r`: a custom, vectorised distance function
12. `codePlotOptions/`: custom ggplot themes.

---

[^1]: [Bracis et al. (2018)](https://onlinelibrary.wiley.com/doi/abs/10.1111/ecog.03618)