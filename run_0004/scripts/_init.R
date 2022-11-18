
#LOADING
library(tidyverse)
library(readxl)
setwd(here::here()) #set wd to main git repo directory
source("script_functions/functions_demultiplex.R")
source("script_functions/functions_reads.R")

#CONFIG
runname <- "run_0004"
refdb_name <- "refdb_2022-11-11"
refdb_path <- "~/refdb/refdb_2022-11-11/"
runs <- 3
inputfile <- "Run04 MiSeq_sampleinfo_veldcodes_reads Annelis.xlsx"
inputtab <- "Sample_sheet"
cutadapt_min_length <- 60
allowed_primer_error_ratio <- 0.12 #2 op 18
align_min_overlap <- 20
align_max_length <- 195 #Riaz specifiek?
primer_removal_error_rate <- 0.15
quality_filtering_error <- 0.5
obi_filter_minlength <- 80
obi_filter_mincount <- 80
obi_cleaning_rate <- 0.05
obi_ecotag_limit <- 0.97
obi_align_threshold <- 0.95


#PREP ENVIRONMENT
setwd(runname)
path_wsl <- tuxify_path(getwd())
