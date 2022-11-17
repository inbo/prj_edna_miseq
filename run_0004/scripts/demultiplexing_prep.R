getwd()
source("scripts/demultiplexing_init.R")

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
          file = file.path("reads", "allbarcodes.btab0"), 
          col_names = FALSE)
  
bt1 <- distinct_samples %>% 
  transmute(rev, smp1 = paste0(name, "_R2.fq"), smp2 = paste0(name, "_F2.fq") )
write_tsv(bt1, 
          file = file.path("reads", "allbarcodes.btab1"), 
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


#kopieer naar wsl
cat(file = "", sep = "\n",
    "#!/bin/bash", 
    "#STEP 1: Copy necessary files",
    paste0("cd miseq/", runname),
    "mkdir input",
    "cd input",
    paste0("cp ", file.path(path_wsl, "reads/*.smp"),   " . "),
    paste0("cp ", file.path(path_wsl, "reads/*.btab?"), " . "),
    paste(paste0("gzip -dkfc ", 
                 file.path(path_wsl, "reads", reads), 
                 paste0(" > ", paste0("~/miseq/", runname, "/input/"), targets), 
          collapse = "\n"))
)


####################################################################################
