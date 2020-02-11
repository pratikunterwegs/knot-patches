#### function to do ctmm

{
  temp_data <- fread(df)
  temp_data[,ts:=fastPOSIXct(ts)]
      
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
                                       tempIndepLim = 30,
                                       restIndepLim = 30,
                                       minFixes = 3,
                                       tideLims = c(4,10))
      
      # watlasUtils function to get patch data as spatial
      patch_data <- wat_get_patch_summary(resPatchData = patch_data,
                                          dataColumn = "data",
                                          whichData = "summary")
      
      # print message
      message(as.character(glue('patches {id}_{tide_number} done')))
      
      return(patch_data)
    },
    # null error function, with option to collect data on errors
    error= function(e)
    {
      message(glue::glue('patches {id}_{tide_number} errored'))
    }
    
  )
}

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
  
  {
    temp_data <- fread(df)
    temp_data[,ts:=fastPOSIXct(ts)]
        
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
                                         tempIndepLim = 30,
                                         restIndepLim = 30,
                                         minFixes = 3,
                                         tideLims = c(4,10))
        
        # watlasUtils function to get patch data as spatial
        patch_summary <- wat_get_patch_summary(resPatchData = patch_data,
                                            dataColumn = "data",
                                            whichData = "summary")

        # get patch data points
        
        # print message
        message(as.character(glue('patches {id}_{tide_number} done')))
        
        return(patch_data)
      },
      # null error function, with option to collect data on errors
      error= function(e)
      {
        ### MUST RETURN NA VALUE
        message(glue::glue('patches {id}_{tide_number} errored'))
      }
      
    )
  }
  
  
  # prepare for telemetry
  {
    test <- data
    # convert to lat-long
    coords <- test %>% 
      st_as_sf(coords = c("x", "y")) %>% 
      `st_crs<-`(32631) %>% 
      st_transform(4326) %>% 
      st_coordinates()
    
    names(coords) <- c("location.long","location.lat")
    
    test[,HDOP:=sqrt(VARX+VARY)]
    test <- test[,.(id, ts, HDOP)]
    test[,ts:=fastPOSIXct(ts)]
    setnames(test, c("individual.local.identifier", "timestamp", "HDOP"))
    test[,`:=`(location.long = coords[,1], location.lat = coords[,2])]
  }
  
  # make telemetry
  {
    tel <- as.telemetry(test)
  }
  
  # ctmm
  {
    outliers <- outlie(tel)
    q90 <- quantile(outliers[[1]], probs = c(0.99))
    
    tel <- tel[-(which(outliers[[1]] >= q90)),]
    
    # make variogram
    vg <- variogram(tel)
    
    mod <- ctmm.fit(tel)
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

