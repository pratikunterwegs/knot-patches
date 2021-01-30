## ----prep_libs_2, message=FALSE, warning=FALSE--------------------------------
# load watlastools or install if not available
if (!"watlastools" %in% installed.packages()) {
  devtools::install_github("pratikunterwegs/watlastools")
}
library(watlastools)

# libraries to process data
library(dplyr)
library(data.table)
library(purrr)
library(stringr)
library(glue)
library(readr)
library(fasttime)

# functions for this stage alone
ci <- function(x) {
  qnorm(0.975) * sd(x, na.rm = T) / sqrt((length(x)))
}


## ----remove_old_data----------------------------------------------------------
if (file.exists("data/data_2018/data_2018_patch_summary.csv")) {
  file.remove("data/data_2018/data_2018_patch_summary.csv")
}


## ----make_patches, message=FALSE, warning=FALSE-------------------------------
# make a vector of data files to read
data_files <- list.files(
  path = "data/data_2018/data_pre_patch",
  pattern = "_revisit.csv", full.names = TRUE
)

# get tag ids
data_id <- str_split(data_files, "/") %>%
  map_chr(function(l) l[[4]] %>% str_sub(1, 3))

# make df of tag ids and files
data <- tibble(tag = data_id, data_file = data_files)
data <- split(x = data, f = data$tag) %>%
  map(function(l) l$data_file)

# map inferResidence, classifyPath, and getPatches over data
walk(data, function(df_list) {
  patch_data <- map(df_list, function(l) {

    # read the data file
    temp_data <- fread(l)
    temp_data[, ts := fastPOSIXct(ts)]

    id <- unique(temp_data$id)
    tide_number <- unique(temp_data$tide_number)

    # wrap process in try catch
    tryCatch(
      {
        # watlastools function to infer residence
        temp_data <- wat_infer_residence(
          data = temp_data,
          inf_patch_time_diff = 30,
          inf_patch_spat_diff = 100
        )

        # watlastools function to classify path
        temp_data <- wat_classify_points(
          data = temp_data,
          lim_res_time = 2,
          min_fix_warning = 3
        )

        # watlastools function to get patches
        patch_dt <- wat_make_res_patch(
          data = temp_data,
          buffer_radius = 10,
          lim_spat_indep = 100,
          lim_time_indep = 30,
          lim_rest_indep = 30,
          min_fixes = 3
        )
        # print message
        message(glue("patches {id}_{tide_number} done"))
        return(patch_dt)
      },
      # null error function, with option to collect data on errors
      error = function(e) {
        message(glue::glue("patches {id}_{tide_number} errored"))
      }
    )
  })

  tryCatch(
    {
      # repair high tide patches across an individual's tidal cycles
      repaired_data <- wat_repair_ht_patches(patch_data_list = patch_data)
      # write patch summary data

      if (all(is.data.frame(repaired_data), nrow(repaired_data) > 0)) {
        # watlastools function to get patch data as summary
        patch_summary <- wat_get_patch_summary(
          res_patch_data = repaired_data,
          which_data = "summary"
        )
        fwrite(patch_summary,
          file = "data/data_2018/data_2018_patch_summary.csv",
          append = TRUE
        )

        # we also want the spatial object
        patch_spatial <- wat_get_patch_summary(
          res_patch_data = repaired_data,
          which_data = "spatial"
        )
        sf::st_crs(patch_spatial) <- 32631
      }
      sf::st_write(patch_spatial,
        dsn = "data/data_2018/spatials/patches_2018.gpkg",
        append = TRUE
      )
    },
    error = function(e) {
      message(glue::glue("patch writing errored"))
    }
  )
})
