#!/bin/bash


#02_adaptortrimming
FWD="ACTGGGATTAGATACCCC" #original forward RIAZ primer
FWDRC="GGGGTATCTAATCCCAGT" #reverse complement of forward RIAZ primer
REVRC="CTAGAGGAGCCTGTTCTA"  #reverse complement of reverse primer (hier gebruiken)
REV="TAGAACAGGCTCCTCTAG" #orignal reverse primer
N=60	#minimum size for pear
M=195	#maximum size for pear
V=20 #minimum overlap
CADMIN=20 #minimum length
CADERR=0.12 #Allow 2 errors on 18 (RIAZ primer length)

python3 -m venv obi3-env
 . obi3-env/bin/activate
 
cp /mnt/c/_GIT_PROJECTS/prj_edna_miseq/run_0004/verwerking2023/trim_adapters.sh ~/trim_adapters.sh
cp /mnt/c/_GIT_PROJECTS/prj_edna_miseq/run_0004/verwerking2023/alignment_flash.sh ~/alignment_flash.sh
cp /mnt/c/_GIT_PROJECTS/prj_edna_miseq/run_0004/verwerking2023/remove_primers.sh ~/remove_primers.sh
cp /mnt/c/_GIT_PROJECTS/prj_edna_miseq/run_0004/verwerking2023/quality_filtering.sh ~/quality_filtering.sh
cp /mnt/c/_GIT_PROJECTS/prj_edna_miseq/run_0004/verwerking2023/rename_and_concatenate.sh ~/rename_and_concatenate.sh
cp /mnt/c/_GIT_PROJECTS/prj_edna_miseq/taxonomy/taxdump2023-07-07.tar.gz ~/taxdump.tar.gz
cp /mnt/c/_GIT_PROJECTS/prj_edna_miseq/refdb/Refdb.fasta ~/refdb.fasta
dos2unix ~/trim_adapters.sh
dos2unix ~/alignment_flash.sh
dos2unix ~/remove_primers.sh
dos2unix ~/quality_filtering.sh
dos2unix ~/rename_and_concatenate.sh
dos2unix ~/obitools.sh

#########
#generic
#########
cd ~/run0004
dos2unix ~/refdb.fasta
obi import ~/refdb.fasta run0004/refdb_import
obi import --taxdump ~/taxdump.tar.gz run0004/taxonomy/taxdump
obi build_ref_db -t 0.97 --taxonomy run0004/taxonomy/taxdump run0004/refdb_import run0004/refdb

########
#run 01
########

cd ~/run0004/run1
mkdir ./0_adapters_removed/
mkdir ./1_merged/
mkdir ./2_trimmed/
mkdir ./3_quality_filtered/
mkdir ./4_obi_input/
mkdir ./5_dereplication
mkdir ./6_filtering
mkdir ./7_tax_assignment_after_filtering

#trim adapters
~/trim_adapters.sh

#align via flash
~/alignment_flash.sh

#remove primers
~/remove_primers.sh

#quality filtering
~/quality_filtering.sh

#rename_ and concatenate before obitools
~/rename_and_concatenate.sh

#copy and cleanup
cp ./4_obi_input/all_samples.fa ~/run0004/run1_samples.fa
rm -r ./0_adapters_removed/
rm -r ./1_merged/
rm -r ./2_trimmed/
rm -r ./3_quality_filtered/
rm -r ./4_obi_input/

########
#run 2
########

cd ~/run0004/run2
mkdir ./0_adapters_removed/
mkdir ./1_merged/
mkdir ./2_trimmed/
mkdir ./3_quality_filtered/
mkdir ./4_obi_input/
mkdir ./5_dereplication
mkdir ./6_filtering
mkdir ./7_tax_assignment_after_filtering

~/trim_adapters.sh
~/alignment_flash.sh
~/remove_primers.sh
~/quality_filtering.sh
~/rename_and_concatenate.sh

cp ./4_obi_input/all_samples.fa ~/run0004/run2_samples.fa
rm -r ./0_adapters_removed/
rm -r ./1_merged/
rm -r ./2_trimmed/
rm -r ./3_quality_filtered/
rm -r ./4_obi_input/


#########
#run 3
#########
cd ~/run0004/run3
mkdir ./0_adapters_removed/
mkdir ./1_merged/
mkdir ./2_trimmed/
mkdir ./3_quality_filtered/
mkdir ./4_obi_input/
mkdir ./5_dereplication
mkdir ./6_filtering
mkdir ./7_tax_assignment_after_filtering

~/trim_adapters.sh
~/alignment_flash.sh
~/remove_primers.sh
~/quality_filtering.sh
~/rename_and_concatenate.sh

cp ./4_obi_input/all_samples.fa ~/run0004/run3_samples.fa
rm -r ./0_adapters_removed/
rm -r ./1_merged/
rm -r ./2_trimmed/
rm -r ./3_quality_filtered/
rm -r ./4_obi_input/

######
#after
######

cd ~/run0004
cp *.fa /mnt/c/_GIT_PROJECTS/prj_edna_miseq/run_0004/verwerking2023/








