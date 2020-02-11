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
  
  
  # prepare for telemetry
  {
    data_for_ctmm <- setDT(patch_points)[,.(id, tide_number, x, y, patch, time, VARX, VARY)]
    
    # aggregate within a patch to 10 seconds
    data_for_ctmm <- split(data_for_ctmm, f = data_for_ctmm$patch) %>% 
      map(wat_agg_data, interval = 60) %>% 
      bind_rows()
    
    # make each patch an indiv
    setDT(data_for_ctmm)
    data_for_ctmm[,individual.local.identifier:= paste(id, tide_number, patch,
                                                       sep = "_")]
    # get horizontal error
    data_for_ctmm[,HDOP := sqrt(VARX+VARY)/10]
    # subset columns
    data_for_ctmm <- data_for_ctmm[,.(individual.local.identifier, time, x, y, HDOP)]

    # get new names
    setnames(data_for_ctmm, old = c("x", "y", "time"), 
      new = c("UTM.x","UTM.y", "timestamp"))
    
    # convert time to posixct
    data_for_ctmm[,timestamp:=as.POSIXct(timestamp, origin = "1970-01-01")]
    # add UTM zone
    data_for_ctmm[,zone:="31 +north"]
    
  }
  
  # make telemetry
  {
    tel <- as.telemetry(data_for_ctmm)
  }
  
  # ctmm section
  {
    # get the outliers but do not plot
    outliers <- map(tel, outlie, plot=FALSE)
    # get a list of 99 th percentile outliers
    q90 <- map(outliers, function(this_outlier_set){
      quantile(this_outlier_set[[1]], probs = c(0.99))
    })
    # remove outliers from telemetry data
    tel <- pmap(list(tel, outliers, q90), 
                function(this_tel_obj, this_outlier_set, outlier_quantile) 
                  {this_tel_obj[-(which(this_outlier_set[[1]] >= outlier_quantile)),]})
    
    # some patches have no data remaining, filter them out
    tel <- keep(tel, function(this_tel){nrow(this_tel) > 0})
    
    # guess ctmm params
    guess_list <- lapply(tel, ctmm.guess, interactive = F)
    
    # run ctmm fit
    mod <- map2(tel, guess_list, function(obj_tel, obj_guess){
      ctmm.fit(obj_tel, CTMM = obj_guess)
    })
  }
  
  message("model fit!")
  
  summary(mod)
  
  # check output
  {
    png(filename = as.character(glue('vg_ctmm_{id_data}.png')))
    plot(vg, CTMM=mod)
    dev.off()
  }
  
  # print model
  {
    if(dir.exists("mod_output") == F)
    {
      dir.create("mod_output")
    }
    writeLines(R.utils::captureOutput(summary(mod)), 
            con = as.character(glue('mod_output/ctmm_{id_data}.txt')))
  }
  
}
# ends here

