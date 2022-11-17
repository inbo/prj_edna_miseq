
getwd()
source("scripts/demultiplexing_init.R")

#DEMUX First replicate (wsl -- files copied in demultiplexing_prep.R)

Freads <- "input/run1_R1.fastq"
Rreads <- "input/run1_R2.fastq"
Btab0 <- "input/allbarcodes.btab0"
Btab1 <- "input/allbarcodes.btab1"
replicate <- 1 #first of 3 replicate runs
logfile <- paste0("demultiplex_", replicate, ".log")

distinct_samples <- 
    read_sample_sheet(inputfile, inputtab, runs, divider = "Riaz") %>% 
    distinct(name, fwd, rev)
samples <- distinct_samples %>% pull(name)


cat('', sep = "\n", 
    "#!/bin/bash",
    paste0("cd ~/miseq/", runname),
    paste0("echo 'original files:'",  " > ", logfile), 
    paste0("wc -l ", Freads, " >> ", logfile),
    paste0("wc -l ", Rreads, " >> ", logfile),
    "",
    "#First round of demultiplexing",
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
    "",
    "#voeg de bestanden terug samen",
    paste(collapse = "\n", 
          paste0("cat ", 
                 samples, "_F1.fq", " ",
                 samples, "_F2.fq", 
                 " > ", samples, "_round1_F.fq",
                 "\n rm ", samples, "_F1.fq", " ",samples, "_F2.fq")),
    paste(collapse = "\n", 
          paste0("cat ", 
                 samples, "_R1.fq", " ",
                 samples, "_R2.fq", 
                 " > ", samples, "_round1_R.fq",
                 "\n rm ", samples, "_R1.fq", " ", samples, "_R2.fq")),
    paste0("rm ",
           "unknown-round1-1.fq", " ", "unknown-round1bis-1.fq", " ",
           "unknown_round1-2.fq", " ", "unknown_round1bis-2.fq"),
    paste0("echo '\n#After first round of demultiplexing:\n'", " >> ", logfile),
    paste0("ls -l *.fq", " | ", "awk '{print $9, $5}'", " >> ", logfile),
    "",
    "#tweede ronde van demultiplex",
    #OPGELET: ik gebruik dezelfde namen als in ronde 1, 
    #dus bestanden uit ronde 1 moeten opgekuist zijn
    #Annelies hernoemt de stalen naar $SAMPLE_round2, ik doe dit niet
    paste(collapse = "\n", 
          paste0("sabre pe", 
                 " -f ", samples, "_round1_F.fq", 
                 " -r ", samples, "_round1_R.fq", 
                 " -b ", "input/", samples, ".btab2",
                 " -u ", samples, "_unknown_round2_1.fq", 
                 " -w ", samples, "_unknown_round2_2.fq", 
                 "\n rm ", 
                 samples, "_round1_F.fq", " ", 
                 samples, "_round1_R.fq", " ")),
    paste0("rm *unknown_round2*"),
    "#voeg bestanden opnieuw samen",
    paste(collapse = "\n", 
          paste0("cat ", 
                 samples, "_F1.fq", " ",
                 samples, "_F2.fq", 
                 " > ", samples, "_F.fq",
                 "\n rm ", samples, "_F1.fq", " ",samples, "_F2.fq")),
    paste(collapse = "\n", 
          paste0("cat ", 
                 samples, "_R1.fq", " ",
                 samples, "_R2.fq", 
                 " > ", samples, "_R.fq",
                 "\n rm ", samples, "_R1.fq", " ", samples, "_R2.fq")),
    paste0("echo '\n#After 2nd round of demultiplexing:\n'", " >> ", logfile),
    paste0("ls -l *.fq", " | ", "awk '{print $9, $5}'", " >> ", logfile),
    paste0("mkdir demux"),
    paste0("mv ", "*.fq ", "demux/")
    
    #TIP: Hernoemen van bestanden met een bepaald patroon door een ander patroon
    #for f in *te_vinden_deel*; do mv -i -- "$f" "${f//te_vinden_deel/vervanging}"; done
)

