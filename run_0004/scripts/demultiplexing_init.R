
#LOADING
library(tidyverse)
library(readxl)
setwd(here::here()) #set wd to main git repo directory
source("script_functions/functions_demultiplex.R")

#CONFIG
runname <- "run_0004"
runs <- 3
inputfile <- "Run04 MiSeq_sampleinfo_veldcodes_reads Annelis.xlsx"
inputtab <- "Sample_sheet"

#PREP ENVIRONMENT
setwd(runname)
path_wsl <- tuxify_path(getwd())
