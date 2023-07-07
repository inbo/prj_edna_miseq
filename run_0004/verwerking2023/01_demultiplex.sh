#!/bin/bash

cd ~/
mkdir run0004
mkdir run0004/run1
mkdir run0004/run2
mkdir run0004/run3
python3 -m venv obi3-env
 . obi3-env/bin/activate

cp /mnt/c/_GIT_PROJECTS/prj_edna_miseq/Annelies_demultiplex_origineel.sh ~/demultiplex.sh
dos2unix ~/demultiplex.sh

######
#run1
######
cp /mnt/c/_GIT_PROJECTS/prj_edna_miseq/run_0004/reads/Riaz1_S1_L001_R1_001.fastq.gz ~/run0004/run1/R1.fastq.gz 
cp /mnt/c/_GIT_PROJECTS/prj_edna_miseq/run_0004/reads/Riaz1_S1_L001_R2_001.fastq.gz ~/run0004/run1/R2.fastq.gz 
cp /mnt/c/_GIT_PROJECTS/prj_edna_miseq/run_0004/reads/R_samplesheet.smp ./run0004/run1/samplesheet.smp

cd ~/run0004/run1
gzip -d R1.fastq.gz
gzip -d R2.fastq.gz

~/demultiplex.sh -b samplesheet.smp -f R1.fastq -r R2.fastq

rm R1.fastq
rm R2.fastq

######
#run2
######
cp /mnt/c/_GIT_PROJECTS/prj_edna_miseq/run_0004/reads/Riaz2_S2_L001_R1_001.fastq.gz ~/run0004/run2/R1.fastq.gz 
cp /mnt/c/_GIT_PROJECTS/prj_edna_miseq/run_0004/reads/Riaz2_S2_L001_R2_001.fastq.gz ~/run0004/run2/R2.fastq.gz 
cp /mnt/c/_GIT_PROJECTS/prj_edna_miseq/run_0004/reads/R_samplesheet.smp ~/run0004/run2/samplesheet.smp

cd ~/run0004/run2
gzip -d R1.fastq.gz
gzip -d R2.fastq.gz
~/demultiplex.sh -b samplesheet.smp -f R1.fastq -r R2.fastq

rm R1.fastq
rm R2.fastq

######
#run3
######

cp /mnt/c/_GIT_PROJECTS/prj_edna_miseq/run_0004/reads/Riaz3_S3_L001_R1_001.fastq.gz ~/run0004/run3/R1.fastq.gz 
cp /mnt/c/_GIT_PROJECTS/prj_edna_miseq/run_0004/reads/Riaz3_S3_L001_R2_001.fastq.gz ~/run0004/run3/R2.fastq.gz 
cp /mnt/c/_GIT_PROJECTS/prj_edna_miseq/run_0004/reads/R_samplesheet.smp ~/run0004/run3/samplesheet.smp

cd ~/run0004/run3
gzip -d R1.fastq.gz
gzip -d R2.fastq.gz

~/demultiplex.sh -b samplesheet.smp -f R1.fastq -r R2.fastq

rm R1.fastq
rm R2.fastq

