#### function to process patches

# load libs
library(data.table)
library(ctmm)
library(fasttime)
library(tibble)
library(dplyr)
library(purrr)
library(tidyr)
# devtools::install_github("pratikunterwegs/watlasUtils", ref = "devbranch")
library(watlasUtils)
library(lubridate)
library(sf)
library(glue)
library(stringr)

process_patches_2018 <- function(df){

  # global counter for success
  success = FALSE
  
  {
    temp_data <- fread(df)
    temp_data[,ts:=fastPOSIXct(ts)]
    orig_data <- wat_agg_data(temp_data, interval = 30)
        
    id <- unique(temp_data$id)
    tide_number <- unique(temp_data$tide_number)
    
    # wrap process in try catch
    tryCatch(
      {
        # watlasUtils function to infer residence
        temp_data <- wat_infer_residence(df = temp_data,
                                         infResTime = 2,
                                         infPatchTimeDiff = 30,
                                         infPatchSpatDiff = 100)
        
        # watlasUtils function to classify path
        temp_data <- wat_classify_points(somedata = temp_data,
                                         resTimeLimit = 2)
        
        # watlasUtils function to get patches
        patch_data <- wat_make_res_patch(somedata = temp_data,
                                         bufferSize = 10,
                                         spatIndepLim = 100,
                                         tempIndepLim = 10,
                                         restIndepLim = 30,
                                         minFixes = 3,
                                         tideLims = c(4,10))
        
        # watlasUtils function to get patch data as spatial
        patch_summary <- wat_get_patch_summary(resPatchData = patch_data,
                                            dataColumn = "data",
                                            whichData = "summary")

        # get patch data points
        patch_points <- wat_get_patch_summary(resPatchData = patch_data,
                                            dataColumn = "data",
                                            whichData = "points")

        # print message
        message(as.character(glue('patches {id}_{tide_number} done')))
        
        success = TRUE
      },
      # null error function, with option to collect data on errors
      error= function(e)
      {
        message(glue::glue('patches {id}_{tide_number} errored'))
      }
      
    )
  }

  # write patch summary data
  if(success == TRUE){
    fwrite(patch_summary, file = "data/watlas_2018/data_patch_summaries.csv",
      append = TRUE)
  }
}
  
  
  
# ends here

