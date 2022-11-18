
getwd()
source("scripts/_init.R")

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
    "#Eerste demultiplex ronde\n#----------------------------\n",
    paste0("sabre pe", 
           " -f ", Freads, 
           " -r ", Rreads, 
           " -b ", Btab0, 
           " -u ", "unknown-round1-1.fq",
           " -w ", "unknown_round1-2.fq",
           " >> ", logfile),
    "",
    paste0("sabre pe", 
           " -f ", Freads, 
           " -r ", Rreads, 
           " -b ", Btab1, 
           " -u ", "unknown-round1bis-1.fq",
           " -w ", "unknown_round1bis-2.fq",
           " >> ", logfile),
    "",
    "#voeg de bestanden terug samen",
    paste(collapse = "\n", 
          paste0("cat ", 
                 samples, "_F1.fq", " ",
                 samples, "_F2.fq", 
                 " > ", samples, "_round1_F.fq",
                 "\nrm ", samples, "_F1.fq", " ",samples, "_F2.fq", "\n")),
    paste(collapse = "\n", 
          paste0("cat ", 
                 samples, "_R1.fq", " ",
                 samples, "_R2.fq", 
                 " > ", samples, "_round1_R.fq",
                 "\nrm ", samples, "_R1.fq", " ", samples, "_R2.fq", "\n")),
    paste0("rm ",
           "unknown-round1-1.fq", " ", "unknown-round1bis-1.fq", " ",
           "unknown_round1-2.fq", " ", "unknown_round1bis-2.fq"),
    paste0("echo '\n#After first round of demultiplexing:\n'", " >> ", logfile),
    paste0("\n", "ls -l *.fq", " | ", "awk '{print $9, $5}'", " >> ", logfile),
    "",
    "#tweede ronde van demultiplex\n#---------------------------------\n",
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
                 "\nrm ", 
                 samples, "_round1_F.fq", " ", 
                 samples, "_round1_R.fq", " ", "\n")),
    paste0("rm *unknown_round2*"),
    "\n#voeg bestanden opnieuw samen",
    "\n#Forward reads:\n",
    paste(collapse = "\n", 
          paste0("cat ", 
                 samples, "_F1.fq", " ",
                 samples, "_F2.fq", 
                 " > ", samples, "_F.fq",
                 "\nrm ", samples, "_F1.fq", " ",samples, "_F2.fq", "\n")),
    "\n#Reverse reads:\n",
    paste(collapse = "\n", 
          paste0("cat ", 
                 samples, "_R1.fq", " ",
                 samples, "_R2.fq", 
                 " > ", samples, "_R.fq",
                 "\nrm ", samples, "_R1.fq", " ", samples, "_R2.fq", "\n")),
    paste0("\n#After 2nd round of demultiplexing:", " >> ", logfile),
    paste0("\n", "ls -l *.fq", " | ", "awk '{print $9, $5}'", " >> ", logfile),
    paste0('for f in *F\\.fq;',
           ' do mv -i -- "$f" ',  
           '"${f//F\\.fq/rep_',replicate,'_F\\.fq}"; done'),
    paste0('for f in *R\\.fq;',
           ' do mv -i -- "$f" ',  
           '"${f//R\\.fq/rep_',replicate,'_R\\.fq}"; done'),
    paste0("mkdir demux"),
    paste0("mv ", "*.fq ", "demux/")
    
    #TIP: Hernoemen van bestanden met een bepaald patroon door een ander patroon
    #for f in *te_vinden_deel*; do mv -i -- "$f" "${f//te_vinden_deel/vervanging}"; done
)

