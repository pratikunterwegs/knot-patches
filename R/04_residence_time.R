## ----install_recurse, message=FALSE, warning=FALSE----------------------------
# load recurse or install if not available
if ("recurse" %in% installed.packages() == FALSE) {
  install.packages("recurse")
}
library(recurse)

# libraries to process data
library(data.table)
library(purrr)
library(glue)
library(dplyr)
library(fasttime)
library(stringr)


## ----recurse_analysis, message=FALSE, warning=FALSE---------------------------
# read in data
data_files <- list.files(
  path = "data/data_2018/data_processed/",
  pattern = "whole_season_", full.names = TRUE
)

data_ids <- str_extract(data_files, "(whole_season_preproc_\\d+)") %>% str_sub(-3, -1)
# read in release data and get first release - 24 hrs
tag_info <- fread("data/data_2018/SelinDB.csv")
tag_info <- tag_info[!is.na(Release_Date) & !is.na(Release_Time), ]
tag_info[, Release_Date := as.POSIXct(paste(Release_Date,
  Release_Time,
  sep = " "
),
format = "%d.%m.%y %H:%M", tz = "CET"
)]

# prepare recurse data folder
if (!dir.exists("data/data_2018/data_pre_patch")) {
  dir.create("data/data_2018/data_pre_patch")
}


## ----prepare_recurse_params---------------------------------------------------
# prepare recurse in parameters
# radius (m), cutoff (mins)
radius <- 50
timeunits <- "mins"
revisit_cutoff <- 60


## ----do_recurse---------------------------------------------------------------
# walk read in, splitting, and recurse over individual level data
# remove visits where the bird left for 60 mins, and then returned
# this is regardless of whether after its return it stayed there
# the removal counts the cumulative sum of all (timeSinceLastVisit <= 60)
# thus after the first 60 minute absence, all points are assigned TRUE
# this must be grouped by the coordinate
walk(data_files, function(df) {

  # read in, fix data type, and split
  temp_data <- fread(df, integer64 = "numeric")
  temp_data[, ts := fastPOSIXct(ts, tz = "CET")]
  setDF(temp_data)
  temp_data <- split(temp_data, temp_data$tide_number)

  # map over the tidal cycle level data
  walk(temp_data, function(tempdf) {
    tryCatch(
      {
        # perform the recursion analysis
        df_recurse <- getRecursions(
          x = tempdf[, c("x", "y", "ts", "id")],
          radius = radius,
          timeunits = timeunits, verbose = TRUE
        )

        # extract revisit statistics and calculate residence time
        # and revisits with a 1 hour cutoff
        df_recurse <- setDT(df_recurse[["revisitStats"]])

        df_recurse[, timeSinceLastVisit :=
          ifelse(is.na(timeSinceLastVisit), -Inf, timeSinceLastVisit)]

        df_recurse[, longAbsenceCounter := cumsum(timeSinceLastVisit > 60),
          by = .(coordIdx)
        ]

        df_recurse <- df_recurse[longAbsenceCounter < 1, ]

        df_recurse <- df_recurse[, .(
          resTime = sum(timeInside),
          fpt = first(timeInside),
          revisits = max(visitIdx)
        ),
        by = .(coordIdx, x, y)
        ]

        # prepare and merge existing data with recursion data
        setDT(tempdf)[, coordIdx := 1:nrow(tempdf)]

        tempdf <- merge(tempdf, df_recurse, by = c("x", "y", "coordIdx"))

        setorder(tempdf, ts)

        # write each data frame to file
        fwrite(tempdf,
          file = glue('data/data_2018/data_pre_patch/{unique(tempdf$id)}_\\
                      {str_pad(unique(tempdf$tide_number), width=3, pad="0")}_\\
                      revisit.csv')
        )

        message(glue('recurse {unique(tempdf$id)}_\\
                     {str_pad(unique(tempdf$tide_number), \\
                     width=3, pad="0")} done'))

        rm(tempdf, df_recurse)
      },
      error = function(e) {
        message("some recurses failed")
      }
    )
  })
})
