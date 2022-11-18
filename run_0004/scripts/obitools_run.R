getwd()
source("scripts/_init.R")

#python3 -m venv obi3-env (optioneel)
#source obi3-env/bin/activate (optioneel)
#pip3 install --upgrade pip setuptools wheel Cython
#pip3 install OBITools3

refdb_ref <- paste0(refdb_path, "refdb/", runname)


cat(file = "", sep = "\n", 
    paste0("cd " , "~/miseq/", runname),
    paste0("mkdir ./5_dereplication"),
    paste0("mkdir ./6_filtering"),
    paste0("mkdir ./7_tax_assign"),
    "\n\n",
    "#IMPORT\n--------------------\n",
    paste0("obi import",
    " ./4_obi_input/allsamples.fa", 
    " ", refdb_ref, "_reads"),
    "\n\n",
    "#DEREPLICATION\n--------------------\n",    
    paste0("obi uniq ", 
           " -m ","sample",
           " ", refdb_ref, "_reads",
           " ", refdb_ref, "_dereplicated"),
    "\n\n",
    "#CLEAN METADATA\n--------------------\n",
    paste0("obi annotate", 
           " -k ", "COUNT", 
           " -k ", "MERGED_sample", 
           " ", refdb_ref, "_dereplicated",
           " ", refdb_ref, "_cleaned_metadata"),
    "\n\n",
    "#FILTERING\n--------------------\n",   
    paste0("obi grep", 
           " -p ", "\"len(sequence)>=", obi_filter_minlength, 
           " and sequence['COUNT']>=", obi_filter_mincount, "\"",
           " ", refdb_ref, "_cleaned_metadata", 
           " ", refdb_ref, "_denoised"
           ),
    "\n\n",
    "#CLEAN SEQUENCE VARIANTS\n--------------------\n",  
    paste0("obi clean ", 
           " -s ", "MERGED_sample",
           " -r ", obi_cleaning_rate,
           " -H ", " ", refdb_ref, "_denoised", 
           " ", refdb_ref, "_cleaned"),
    "\n\n",
    "#ECOTAG\n--------------------\n",    
    paste0("obi ecotag", 
           " -m ", obi_ecotag_limit, 
           " --taxonomy ", " ", refdb_path,  "refdb/taxonomy/dump", 
           " -R ", refdb_path, "refdb/ecopcr_final_", obi_ecotag_limit, 
           " ", refdb_ref, "_cleaned", 
           " ", refdb_ref, "_assigned"),
    "\n\n",
    "#CHECK RESULTS\n--------------------\n",   
    paste0("obi stats",
           " -c ", "SCIENTIFIC_NAME",
           " ", refdb_ref, "_assigned"),
    "\n\n",
    "#ALIGN\n--------------------\n",  
    paste0("obi align",
           " -t ", obi_align_threshold, 
           " ", refdb_ref, "_assigned",
           " ", refdb_ref, "_aligned"), 
    "\n\n",
    "#EXPORTS\n--------------------\n",  
    paste0("obi export",
           " --fasta-output", 
           " ", refdb_ref, "_aligned" ,
           " > ", "samples_aligned.fasta"),
    paste0("obi export",
           " --fasta-output", 
           " ", refdb_ref, "_assigned" ,
           " > ", "samples_assigned.fasta"),
    paste0("obi export",
           " --tab-output ", " ", refdb_ref, "_aligned",
           " > ", "results_aligned.csv"),
    paste0("obi export",
           " --tab-output ", " ", refdb_ref, "_assigned",
           " > ", "results_assigned.csv"),
    paste0("obi history ",
           " ", refdb_path, "refdb"),
    paste0("obi history", 
           " -d ", refdb_path, "refdb",
           " > ", runname, ".dot"),
    paste0("dot -Tx11 ", runname, ".dot"),
    paste0("dot -Tpng ", runname, ".dot",
           " -o ", runname, ".png"),
    paste0("cp ", "samples_assigned.fasta ", path_wsl, "/output/"),
    paste0("cp ", "results_assigned.csv ", path_wsl, "/output/"),
    paste0("cp ", "results_aligned.csv ", path_wsl, "/output/"),
    paste0("cp ", runname, ".dot ", path_wsl, "/output/")
)


pieter <- read_tsv("output/results_assigned.csv")
annelies <- read_tsv("verwerking_annelies/resultaat_annelies_all_derep_mincount80_cleaned_tagged_ann_sort_final_table.txt")

#HET GROTE VERSCHIL ZIT NOG IN DE MERGED_TAXID,
#IN MIJN VERSIE ZITTEN ENKEL DIE GEVONDEN ZIJN OP SOORTNIVEAU
#BIJ ANNELIES ZITTEN ER OOK OP GENUS OF FAMILIE NIVEAU

annelies1 <- annelies %>% 
  select(id, 
         best_identity = `best_identity:amplified_clean_uniq` ,
         best_match = `best_match:amplified_clean_uniq`,
         count, 
         taxid, rank, scientific_name,
         species_list = `species_list:amplified_clean_uniq`,
         starts_with("sample:"),
         sequence, species, genus, family,
         -contains(c("Riaz_2", "Riaz_3")), -definition)
colnames(annelies1) <- gsub("sample:", "", colnames(annelies1))
colnames(annelies1) <- gsub("Riaz_1", "AH", colnames(annelies1))

pieter1 <- pieter %>% 
  mutate(rank = NA, species = NA, genus = NA, family = NA) %>% 
  select(id = ID, 
         best_identity = BEST_IDENTITY, 
         best_match = BEST_MATCH_IDS,
         count = COUNT, 
         taxid = TAXID, rank, scientific_name = SCIENTIFIC_NAME,
         species_list = BEST_MATCH_TAXIDS, 
         starts_with("MERGED_sample:"), 
         sequence = NUC_SEQ, species, genus, family)
colnames(pieter1) <- gsub("MERGED_sample:", "", colnames(pieter1))
colnames(pieter1) <- gsub("rep_1", "PV", colnames(pieter1))

comparison <- annelies1 %>% 
  full_join(pieter1, 
            by = "sequence", suffix = c(".AH", ".PV"))
comparison <- comparison[,sort(colnames(comparison))]
view(comparison)

write_excel_csv2(comparison, file = "output/count_tables_AH_PV.csv")


###


pieter_check <- pieter %>% select(SCIENTIFIC_NAME, E2022STF292 = `MERGED_sample:E2022STF292_rep_1`, TAXID) %>% 
  filter(TAXID != "None") %>% 
  mutate(TAXID = as.numeric(TAXID)) %>% 
  group_by(SCIENTIFIC_NAME, TAXID) %>% 
  summarise(E2022STF292 = sum(E2022STF292))
  arrange(desc(E2022STF292))

annelies_check <- annelies %>% 
  select(SCIENTIFIC_NAME = species_name, 
         E2022STF292 = `sample:E2022STF292_Riaz_1`, 
         TAXID = taxid) %>% 
  filter(!is.na(SCIENTIFIC_NAME)) %>% 
  group_by(SCIENTIFIC_NAME, TAXID) %>% 
  summarise(E2022STF292 = sum(E2022STF292)) %>% 
  arrange(desc(E2022STF292)) 

comparison <- annelies_check %>% 
  full_join(pieter_check, by = "TAXID") %>% 
  select(SCIENTIFIC_NAME.x, SCIENTIFIC_NAME.y, TAXID, 
         E2022STF292.x, E2022STF292.y)
comparison %>% view()
  
