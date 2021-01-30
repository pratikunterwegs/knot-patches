## ----install_vulntoolkit_2, message=FALSE, warning=FALSE----------------------
# load VulnToolkit or install if not available
if ("VulnToolkit" %in% installed.packages() == FALSE) {
  devtools::install_github("troyhill/VulnToolkit")
}
library(VulnToolkit)

# libraries to process data
library(data.table)
library(purrr)
library(glue)
library(dplyr)
library(stringr)
library(fasttime)
library(lubridate)

library(watlastools)


## ----read_waterlevel_data, message=FALSE, warning=FALSE-----------------------
# read in waterlevel data
waterlevel <- fread("data/data_2018/waterlevelWestTerschelling.csv", sep = ";")

# select useful columns and rename
waterlevel <- waterlevel[, .(WAARNEMINGDATUM, WAARNEMINGTIJD, NUMERIEKEWAARDE)]

setnames(waterlevel, c("date", "time", "level"))

# make a single POSIXct column of datetime
waterlevel[, dateTime := as.POSIXct(paste(date, time, sep = " "),
  format = "%d-%m-%Y %H:%M:%S", tz = "CET"
)]

waterlevel <- setDT(distinct(setDF(waterlevel), dateTime, .keep_all = TRUE))


## ----get_high_tide, message=FALSE, warning=FALSE------------------------------
# use the HL function from vulnToolkit to get high tides
tides <- VulnToolkit::HL(waterlevel$level,
  waterlevel$dateTime,
  period = 12.41,
  tides = "H", semidiurnal = TRUE
)

# read in release data and get first release - 24 hrs
tag_info <- fread("data/data_2018/SelinDB.csv")
tag_info <- tag_info[!is.na(Release_Date) & !is.na(Release_Time), ]
tag_info[, Release_Date := as.POSIXct(paste(Release_Date,
  Release_Time,
  sep = " "
),
format = "%d.%m.%y %H:%M", tz = "CET"
)]

# remove NAs
tag_info <- na.omit(tag_info, cols = "Release_Date")

first_release <- min(tag_info$Release_Date, na.rm = TRUE) - (3600 * 24)

# remove tides before first release
tides <- setDT(tides)[time > first_release, ][, tide2 := NULL]
tides[, tide_number := seq(nrow(tides))]


## ----write_tide_data, message=FALSE, warning=FALSE----------------------------
# write to local file
fwrite(tides,
  file = "data/data_2018/tides_2018.csv",
  dateTimeAs = "ISO"
)


## ----time_to_high_tide, message=FALSE, warning=FALSE--------------------------
# read in data and add time since high tide
data_files <- list.files(
  path = "data/data_2018/data_processed/",
  pattern = "whole_season_", full.names = TRUE
)
data_ids <- str_extract(data_files, "(whole_season_preproc_\\d+)") %>% str_sub(-3, -1)

# map read in and tidal time calculation over data
# merge data to insert high tides within movement data
# arrange by time to position high tides correctly
invisible(
  lapply(data_files, function(df) {

    # read and fix data types
    temp_data <- fread(df, integer64 = "numeric")
    temp_data[, ts := fastPOSIXct(ts, tz = "CET")]

    # merge with tides and order on time
    temp_data <- wat_add_tide(
      data = temp_data,
      tide_data = "data/data_2018/tides_2018.csv"
    )

    # add waterlevel
    temp_data[, temp_time := lubridate::round_date(ts, unit = "10 minute")]
    temp_data <- merge(temp_data, waterlevel[, .(dateTime, level)],
      by.x = "temp_time", by.y = "dateTime"
    )
    setnames(temp_data, old = "level", new = "waterlevel")

    # export data, print msg, remove data
    fwrite(temp_data, file = df, dateTimeAs = "ISO")
    message(glue("tag {unique(temp_data$id)} added time since high tide"))
    rm(temp_data)
  })
)
