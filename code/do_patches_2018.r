#### code to do ctmm on file in cli args
#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)
source("code/func_patches_2018.r")
process_patches_2018(args)

message(paste("patches processed for ", args))

# ends here
