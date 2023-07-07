
MF = c("AGAAGAGTCC", "TTCGATCTTC", "AGAATGACTC")
MR = c("GGTAGGC", "CCAGCCT", "TGGCGTA")
PFR = "ACTGGGATTAGATACCCC"
PRR = "TAGAACAGGCTCCTCTAG"
PFT = "ACACCGCCCGTCACTCT"
PRT = "CTTCCGGTACACTTACCATG"

random_dna <- function(n, probs = c(A=0.25, C=0.25, G=0.25, T=0.25)) {
  dna <- sample(c("A", "C", "G", "T"), size = n,  prob = probs, replace = TRUE)
  paste(dna, collapse = "" )
}

rc <- function(x) {
  x <- toupper(x)
  splits <- strsplit(x, "")[[1]]
  rev <- rev(splits)
  revc <- ifelse(rev == "A", 
                 "T",
                 ifelse(rev == "T", 
                        "A", 
                        ifelse(rev == "C", 
                               "G",
                               ifelse(rev == "G", 
                                      "C",
                                      "0"))))
  paste(revc, collapse = "")
}

make_dna_reads <- function(x, p = NULL , m = NULL, cutoff = NULL) {
  fwdr <- x 
  revr <- rc(x)
  if (length(p == 2)) {
    fwdr = paste0(p[1], fwdr, p[2])
    revr = paste0(rc(p[2]), revr, rc(p[1]))
  }
  if (length(m) == 2) {
    fwdr = paste0(m[1], fwdr, m[2])
    revr = paste0(rc(m[2]), revr, rc(m[1]))    
  }
  if (length(cutoff) == 2) {
    fwdr <- substring(fwdr, cutoff[1])
    revr <- substring(fwdr, cutoff[2])
  }
  c(fwdr, revr)
}

fastq_write <- function(x, con_fwd, con_rev) {
 r1 <- paste0("@", "sample:", x$sample, "\n") 
 cat(r1, file = con_fwd, append = TRUE)
 cat(r1, file = con_rev, append = TRUE)
 cat(paste0(x$fwd, "\n"), file = con_fwd, append = TRUE)
 cat(paste0(x$rev, "\n"), file = con_rev, append = TRUE)
 cat("+\n", file = con_fwd, append = TRUE)
 cat("+\n", file = con_rev, append = TRUE)
 cat(paste0(paste(rep("C", nchar(x$fwd)), collapse = ""), "\n"), file = con_fwd, append = TRUE)
 cat(paste0(paste(rep("C", nchar(x$rev)), collapse = ""), "\n"), file = con_rev, append = TRUE)
}

##############################################################################
set.seed(20230531)
dna <- list()
for (i in 1:3) dna[[i]] <- list(sample = 1, dna = random_dna(60))
for (i in 4:6) dna[[i]] <- list(sample = 2, dna = random_dna(60))
for (i in 7:9) dna[[i]] <- list(sample = 3, dna = random_dna(60))
dna[[10]] <- dna[[1]]
dna[[11]] <- dna[[4]]
dna[[12]] <- dna[[7]]

for (i in 1:12) {
  v <- make_dna_reads(dna[[i]]$dna, 
                      p = c(PFR, PRR),
                      m = c(MF[dna[[i]]$sample],
                            MR[dna[[i]]$sample]))
  if (i %in% 10:12){
    dna[[i]]$fwd = v[2]
    dna[[i]]$rev = v[1]    
  } else {
    dna[[i]]$fwd = v[1]
    dna[[i]]$rev = v[2]    
  }

}

con_fwd <- "test_fwd.fastq"
con_rev <- "test_rev.fastq"
cat('', file = con_fwd)
cat('', file = con_rev)
for (i in 1:12) {
  fastq_write(dna[[i]], con_fwd, con_rev)
}

  
