
data <- readLines("refdb/final_db_0.99.fasta")
data2 <- NULL
for (i in 1:length(data)){
  if (substring(data[i], 1, 1) == ">") {
    tmp <- unlist(strsplit(data[i], split = "; " ))
    tmp <- tmp[substring(tmp,1,1) == ">" | 
                 substring(tmp,1,4) == "rank"  | 
                 substring(tmp,1,5) == "TAXID" | 
                 substring(tmp, 1, 8) == "species=" | 
                 substring(tmp, 1, 6) == "genus=" |
                 substring(tmp, 1, 7) == "family=" |
                 substring(tmp, 1, 13) == "superkingdom="] 
    data2[i] <- paste0(paste(tmp, collapse = "; "))    
  } else {
    data2[i] <- data[i]
  }

}
writeLines(data2, con = 'refdb/Refdb.fasta')
