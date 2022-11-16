

library(tidyverse)
library(readxl)
source("scripts/_functions_demultiplex.R")

setwd("run_0020")
inputfile <- "Run04 MiSeq_sampleinfo_veldcodes_reads Annelis.xlsx"
inputtab <- "Sample_sheet"
runname <- "run_0020"
runs <- 3

tuxify_path <- function(path) {
  sub(".:", paste0("/mnt/", tolower(substring(path,1,1))), path)
}
path_wsl <- tuxify_path(getwd())

#Maak de sample tabel en exporteer de ligatiefiles
sample_sheet <- read_sample_sheet(inputfile, inputtab, runs, divider = "Riaz")
export_sample_sheet(sample_sheet, path = "reads", scheme = "run%")

#lijst van unieke stalen met hun adaptoren
distinct_samples <- sample_sheet %>% distinct(name, fwd, rev)

reads <- list.files("reads", pattern = "*.fastq.gz")
targets <- sub("Riaz", "run", 
               sub("_S._L001", "", 
                   sub("_001.fastq.gz", ".fastq", reads)))
ligations <- list.files("reads", pattern = "*.smp")


#maak de barcodetabellen voor sabre
#let op, we wisselen fwd en rev om, 
#zodat de data klaarstaat om daarna de tweede tag te lezen
bt0 <- distinct_samples %>% 
  transmute(fwd, smp1 = paste0(name, "_R1.fq"), smp2 = paste0(name, "_F1.fq") )
write_tsv(bt0, 
          file = file.path("reads", sub(".smp", ".btab0", fnam)), 
          col_names = FALSE)
  
bt1 <- distinct_samples %>% 
  transmute(rev, smp1 = paste0(name, "_R2.fq"), smp2 = paste0(name, "_F2.fq") )
write_tsv(bt1, 
          file = file.path("reads", sub(".smp", ".btab1", fnam)), 
          col_names = FALSE)

for (i in 1:nrow(distinct_samples)) {
  bts1 <- distinct_samples %>% slice(i) %>% 
    transmute(code = fwd, 
              smp1 = paste0(name, "_F1.fq"), 
              smp2 = paste0(name, "_R1.fq"))
  bts2 <- distinct_samples %>% slice(i) %>% 
    transmute(code = rev, 
              smp1 = paste0(name, "_R2.fq"), 
              smp2 = paste0(name, "_F2.fq"))
  write_tsv(bind_rows(bts1, bts2), 
            file = file.path("reads", 
                             paste0(distinct_samples$name[i], ".btab2")),
            col_names = FALSE)
}

  
sample_sheet %>% distinct(name, fwd, rev)

for (fnam in ligations) {
  lig <- read_tsv(file.path("reads", fnam), col_names = FALSE)
  bt0 <- lig  %>% 
    transmute(K1 = X2, K2 = paste0(X1, "_R1.fq"), K3 = paste0(X1, "_F1.fq"))
  bt1 <- lig  %>% 
    transmute(K1 = X3, K2 = paste0(X1, "_R2.fq"), K3 = paste0(X1, "_F2.fq"))
  write_tsv(bt0, file = file.path("reads", sub(".smp", ".btab0", fnam)), 
            col_names = FALSE)
  write_tsv(bt1, file = file.path("reads", sub(".smp", ".btab1", fnam)), 
            col_names = FALSE)
}

#kopieer naar wsl
cat(file = "", sep = "\n",
    "#!/bin/bash", 
    "#STEP 1: Copy necessary files",
    paste0("cd miseq/", runname),
    "mkdir input",
    "cd input",
    paste(paste0("cp ", file.path(path_wsl, "reads", ligations), " . "), 
                 collapse = "\n"),
    paste(paste0("cp ", file.path(path_wsl, "reads/*.btab?"), " . "), 
          collapse = "\n"),
    paste(paste0("gzip -dkf ", 
                 file.path(path_wsl, "reads", reads), 
                 paste0(" > ./", targets), 
          collapse = "\n"))
)

