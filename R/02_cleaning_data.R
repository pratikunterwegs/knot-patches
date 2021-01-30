## ----install_watlastools_2, message=FALSE, warning=FALSE----------------------
# watlastools assumed installed from the previous step
# if not, install from the github repo as shown below

devtools::install_github("pratikunterwegs/watlastools")


## -----------------------------------------------------------------------------
# libraries to process data
library(data.table)
library(glue)
library(fasttime)
library(stringr)
library(watlastools)


## ----read_attractors, message=FALSE, warning=FALSE----------------------------
# read in identified attractor points
atp <- fread("data/attractor_points.txt")


## ----read_in_raw_data, message=FALSE, warning=FALSE---------------------------
# make a list of data files to read
data_files <- list.files(
  path = "data/data_2018/data_tracks/",
  pattern = "whole_season*", full.names = TRUE
)

data_ids <- str_extract(data_files, "(tx_\\d+)") %>% str_sub(-3, -1)

# read deployment data from local file in data folder
tag_info <- fread("data/data_2018/SelinDB.csv")

# filter out NAs in release date and time
tag_info <- tag_info[!is.na(Release_Date) & !is.na(Release_Time), ]

# make release date column as POSIXct
tag_info[, Release_Date := as.POSIXct(paste(Release_Date,
  Release_Time,
  sep = " "
),
format = "%d.%m.%y %H:%M", tz = "CET"
)]

# sub for knots in data
data_files <- data_files[as.integer(data_ids) %in% tag_info$Toa_Tag]

# map read in, cleaning, and write out function over vector of filenames
invisible(
  lapply(data_files, function(df) {

    # read in the data
    temp_data <- fread(df, integer64 = "numeric")

    # filter for release date + 24 hrs
    temp_id <- str_sub(temp_data[1, TAG], -3, -1)

    rel_date <- tag_info[Toa_Tag == temp_id, Release_Date]

    temp_data <- temp_data[TIME / 1e3 > as.numeric(rel_date + (24 * 3600)), ]
    # do a try catch so as not to break the process
    tryCatch(
      {
        temp_data <- wat_rm_attractor(
          df = temp_data,
          atp_xmin = atp$xmin,
          atp_xmax = atp$xmax,
          atp_ymin = atp$ymin,
          atp_ymax = atp$ymax
        )

        clean_data <- wat_clean_data(
          data = temp_data,
          moving_window = 3,
          nbs_min = 3,
          sd_threshold = 100,
          filter_speed = TRUE,
          speed_cutoff = 150
        )

        agg_data <- wat_agg_data(
          data = clean_data,
          interval = 30
        )

        message(glue("tag {unique(agg_data$id)} \\
                     cleaned with {nrow(agg_data)} fixes"))

        fwrite(
          x = agg_data,
          file = glue("data/data_2018/data_processed/whole_season_preproc_{temp_id}.csv"),
          dateTimeAs = "ISO"
        )
        rm(temp_data, clean_data, agg_data)
      },
      error = function(e) {
        message(glue("tag {unique(temp_id)} failed"))
      }
    )
  })
)


## -----------------------------------------------------------------------------
data_files <- list.files("data/data_2018/data_processed",
  full.names = TRUE
)

total_tracking <- lapply(data_files, function(x) {
  a <- fread(x)
  a <- a[c(1, nrow(a)), list(id, time)]
  a[, event := c("time_start", "time_end")]
})

# bind data tables
total_tracking <- rbindlist(total_tracking)

# get tracking interval for each
total_tracking <- dcast(total_tracking,
  id ~ event,
  value.var = "time"
)

# write to file
fwrite(total_tracking, file = "data/data_2018/data_2018_id_tracking_interval.csv")
