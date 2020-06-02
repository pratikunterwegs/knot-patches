#' ---
#' editor_options: 
#'   chunk_output_type: console
#' ---
#' 
#' # Residence patch construction
#' 
#' This section is about using the main `watlastools` functions to infer residence points when data is missing from a movement track, to classify points into residence or travelling, and to construct low-tide residence patches from the residence points. Summary statistics on these spatial outputs are then exported to file for further use.
#' 
#' **Workflow**
#' 
#' 1. Prepare `watlastools` and required libraries,
#' 2. Read data, infer residence, classify points, construct patches, repair patches, and write movement data and patch summary to file.
#' 
#' ## Prepare libraries
#' 
## ----prep_libs, message=FALSE, warning=FALSE-----------
# load watlastools or install if not available
if("watlastools" %in% installed.packages() == FALSE){
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
ci <- function(x){qnorm(0.975)*sd(x, na.rm = T)/sqrt((length(x)))}

#' 
#' ## Patch construction
#' 
## ----remove_old_data-----------------------------------
if(file.exists("data/data2018/data_2018_patch_summary.csv")){
  file.remove("data/data2018/data_2018_patch_summary.csv")
}

#' 
#' Process patches. Takes approx. 5 hours for 3 second data.
#' 
## ----make_patches, message=FALSE, warning=FALSE--------
# make a vector of data files to read
data_files <- list.files(path = "data/data2018/revisitData", 
                         pattern = "_revisit.csv", full.names = TRUE)

# get tag ids
data_id <- str_split(data_files, "/") %>% 
  map(function(l)l[[4]] %>% str_sub(1,3)) %>% 
  flatten_chr()

# make df of tag ids and files
data <- data_frame(tag = data_id, data_file = data_files)
data <- split(x = data, f = data$tag) %>% 
  map(function(l) l$data_file)

# map inferResidence, classifyPath, and getPatches over data
walk(data[119:134], function(df_list){
  patch_data <- map(df_list, function(l){
    
    # read the data file
    temp_data <- fread(l)
    temp_data[,ts:=fastPOSIXct(ts)]
    
    id <- unique(temp_data$id)
    tide_number <- unique(temp_data$tide_number)
    
    # wrap process in try catch
    tryCatch(
      {
        # watlastools function to infer residence
        temp_data <- wat_infer_residence(df = temp_data,
                                         infPatchTimeDiff = 30,
                                         infPatchSpatDiff = 100)
        
        # watlastools function to classify path
        temp_data <- wat_classify_points(somedata = temp_data,
                                         resTimeLimit = 2)
        
        # watlastools function to get patches
        patch_dt <- wat_make_res_patch(somedata = temp_data,
                                       bufferSize = 10,
                                       spatIndepLim = 100,
                                       tempIndepLim = 30,
                                       restIndepLim = 30,
                                       minFixes = 3)
        # print message
        message(as.character(glue('patches {id}_{tide_number} done')))
        return(patch_dt)
      },
      # null error function, with option to collect data on errors
      error= function(e)
      {
        message(glue::glue('patches {id}_{tide_number} errored'))
      }
    )
  })
  
  tryCatch(
    { # repair high tide patches across an individual's tidal cycles
      repaired_data <- wat_repair_ht_patches(patch_data_list = patch_data)
      # write patch summary data
      
      if(all(is.data.frame(repaired_data), nrow(repaired_data) > 0)){
        # watlastools function to get patch data as summary
        patch_summary <- wat_get_patch_summary(res_patch_data = repaired_data,
                                               whichData = "summary")
        fwrite(patch_summary, file = "data/data2018/data_2018_patch_summary.csv",
               append = TRUE)
        
        # we also want the spatial object
        patch_spatial <- wat_get_patch_summary(res_patch_data = repaired_data,
                                               whichData = "spatial")
        sf::`st_crs<-`(patch_spatial, 32631)
      }
      sf::st_write(patch_spatial, dsn = "data/data2018/spatials/patches_2018.gpkg",
                   append = TRUE)
    },
    error = function(e){
      message(glue::glue('patch writing errored'))
    }
  )
})


