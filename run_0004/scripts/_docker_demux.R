#Dit proces gebeurt voor iedere ligatie apart
#De docker wordt iedere ligatie apart geïnitieerd

#INIT RENV
#------------
library(tidyverse)
library(readxl)
setwd(here::here()) #set wd to main git repo directory
dockerpath <- "_docker_miseq"
image_name <- "miseq"
container_name <- "miseq_run"
source("script_functions/functions_demultiplex.R")
source("script_functions/functions_reads.R")

#VARS
#--------

runname <- "run_0004"
samplesheetfile <- file.path(runname, "Run04_MiSeq_sampleinfo_veldcodes_reads Annelis.xlsx")
FReads1 <- file.path(runname, "reads/Riaz1_S1_L001_R1_001.fastq.gz")
RReads1 <- file.path(runname, "reads/Riaz1_S1_L001_R2_001.fastq.gz")
# FReads2 <- file.path(runname, "reads/Riaz2_S2_L001_R1_001.fastq.gz")
# RReads2 <- file.path(runname, "reads/Riaz2_S2_L001_R2_001.fastq.gz")
# FReads3 <- file.path(runname, "reads/Riaz3_S3_L001_R1_001.fastq.gz")
# RReads3 <- file.path(runname, "reads/Riaz3_S3_L001_R2_001.fastq.gz")

#kopieer de reads
file.copy(FReads1, file.path(dockerpath, "R1.fastq.gz"))
file.copy(RReads1, file.path(dockerpath, "R2.fastq.gz"))

#create sample sheet
sample_sheet <- read_sample_sheet(file.path(runname, inputfile) , "Sample_sheet", runs, divider = "Riaz")
write_tsv(sample_sheet %>% select(name, fwd, rev) %>% filter(!duplicated(name)), col_names = FALSE,
          file = file.path(dockerpath, "R_samplesheet.smp"))

#build docker image, remove existing container, run new container
system2("powershell", 
        args = paste("docker", "build", "-t", image_name, paste0("./", dockerpath, "/")))
system2("powershell",
        args = paste("docker", "rm", container_name))
system2("powershell", 
        args = paste("docker run --rm -i -d --name", container_name, image_name))
        
#kopieer resultaten naar outputdirectory

############################################################################################










