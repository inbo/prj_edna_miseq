library(tidyverse)
library(readxl)
source("scripts/_functions_demultiplex.R")

runname <- "run_0020"

#DEMUX Round 1 (wsl -- files copied in demultiplexing_prep.R)

#
Freads <- "input/run1_R1.fastq"
Rreads <- "input/run1_R2.fastq"
Btab0 <- "input/allbarcodes.btab0"
Btab1 <- "input/allbarcodes.btab1"

cat('', sep = "\n", 
    "#!/bin/bash",
    paste0("cd ~/miseq/", runname),
    "mkdir demux ",
    paste0("sabre pe", 
           " -f ", Freads, 
           " -r ", Rreads, 
           " -b ", Btab0, 
           " -u ", "unknown-round1-1.fq",
           " -w ", "unknown_round1-2.fq"),
    paste0("sabre pe", 
           " -f ", Freads, 
           " -r ", Rreads, 
           " -b ", Btab1, 
           " -u ", "unknown-round1bis-1.fq",
           " -w ", "unknown_round1bis-2.fq"),
    
    #voeg de bestanden terug samen
    
    #tweede ronde van demultiplex
    
    #voeg bestanden opnieuw samen
    
    #cleanup van overbodige bestanden (alle inputs), niet de btabs want herbruikbaar
)

