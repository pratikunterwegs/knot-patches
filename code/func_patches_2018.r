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
  
  success = FALSE
  {
    temp_data <- fread(df)
    temp_data[,ts:=fastPOSIXct(ts)]
    
    id <- unique(temp_data$id)
    tide_number <- unique(temp_data$tide_number)
    
    # get data summary
    {
      data_summary <- temp_data[,.(duration = (max(time) - min(time))/60,
                                   n_fixes = length(x),
                                   prop_fixes = length(x) / ((max(time) - min(time))/3)),
                                by = .(id, tide_number)]
      
      sld <- watlasUtils::wat_simple_dist(temp_data, "x", "y")
      timelag <- c(NA, as.numeric(diff(tempd_data$time)))
      speed <- sld/timelag
      
      data_summary <- temp_data[,mean_speed:=mean(speed, na.rm=TRUE)]
      
      # write data
      fwrite(data_summary, file = "output/tidal_mean_speed_2018.csv", append = TRUE)
    }
    
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
                                         tempIndepLim = 30,
                                         restIndepLim = 30,
                                         minFixes = 3,
                                         tideLims = c(3,10))
        
        # watlasUtils function to get patch data as spatial
        patch_summary <- wat_get_patch_summary(resPatchData = patch_data,
                                               dataColumn = "data",
                                               whichData = "summary")
        
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
