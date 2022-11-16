#!/bin/bash

#IN POWERSHELL
# cd c:/PROJECTEN_GIT/prj_edna/INBOMISEQ
# docker cp ./4_renamed_and_concatenated/all_samples.fa 5871cb60faa1:/home/INBOMISEQ/

#IN DOCKER (instantie 5871cb60faa1):
#NIEUWE DIRECTORIES

cd /home
mkdir INBOMISEQ
cd INBOMISEQ
mkdir ./5_dereplication
mkdir ./6_filtering
mkdir ./7_tax_assignment_after_filtering
MINCOUNT=80

### OBITOOLS

#DEREPLICATION
echo "dereplicating sequences of all samples...."
obiuniq -m sample all_samples.fa > ./5_dereplication/all_derep.fa

#count number of occurrences of each sequence (-nk1 is for numerical sort on kolomn 1)
obistat -c count ./5_dereplication/all_derep.fa | sort -nk1 > ./5_dereplication/all_derep_unique_sequence_counts.txt
echo "done dereplicating sequences of all samples."
echo

#FILTERING
echo "filtering sequences of all samples...."
#keep only sequences that occur > MINCOUNT times
obigrep -p "count>=$MINCOUNT" ./5_dereplication/all_derep.fa > ./6_filtering/all_derep_mincount"$MINCOUNT".fa
#identify PCR and/or sequencing errors
obiclean --without-progress-bar -s merged_sample -r 0.05 -H -d 1 ./6_filtering/all_derep_mincount"$MINCOUNT".fa > ./6_filtering/all_derep_mincount"$MINCOUNT"_cleaned.fa
echo "done filtering sequences of all samples."
echo

#TAXONOMY ASSIGNMENT
REF_DB="/home/Riaz_2022_05_17/Riaz_2022_05_17"
AMPLICON_DB="/home/Riaz_2022_05_17/amplified_clean_uniq.fasta"
echo
echo "assigning taxonomy to sequences...."
ecotag -d $REF_DB -R $AMPLICON_DB ./6_filtering/all_derep_mincount"$MINCOUNT"_cleaned.fa > ./7_tax_assignment_after_filtering/all_derep_mincount"$MINCOUNT"_cleaned_tagged.fa
echo "done assigning taxonomy to sequences."
echo


#GENERATE OUTPUT TABLE
echo
echo "generating output table..."
#first remove some of the attributes which you do not need anymore
obiannotate  --delete-tag=scientific_name_by_db --delete-tag=obiclean_samplecount --delete-tag=definition --delete-tag=obiclean_status --delete-tag=obiclean_count --delete-tag=obiclean_singletoncount --delete-tag=obiclean_cluster --delete-tag=obiclean_internalcount --delete-tag=obiclean_head --delete-tag=taxid_by_db --delete-tag=obiclean_headcount --delete-tag=id_status --delete-tag=rank_by_db --delete-tag=order_name --delete-tag=order ./7_tax_assignment_after_filtering/all_derep_mincount"$MINCOUNT"_cleaned_tagged.fa > ./7_tax_assignment_after_filtering/all_derep_mincount"$MINCOUNT"_cleaned_tagged_ann.fa
#sort the sequences according to abundance
obisort --without-progress-bar -k count -r ./7_tax_assignment_after_filtering/all_derep_mincount"$MINCOUNT"_cleaned_tagged_ann.fa > ./7_tax_assignment_after_filtering/all_derep_mincount"$MINCOUNT"_cleaned_tagged_ann_sort.fa
#generate a tab delimited output table
obitab --without-progress-bar -o ./7_tax_assignment_after_filtering/all_derep_mincount"$MINCOUNT"_cleaned_tagged_ann_sort.fa > ./7_tax_assignment_after_filtering/all_derep_mincount"$MINCOUNT"_cleaned_tagged_ann_sort_final_table.txt
echo "done generating output table."
echo
date


### KOPIEER RESULTATEN VAN DOCKER TERUG (in powershell)

cd c:/PROJECTEN_GIT/prj_edna/INBOMISEQ
docker cp 5871cb60faa1:/home/INBOMISEQ/5_dereplication ./
docker cp 5871cb60faa1:/home/INBOMISEQ/6_filtering ./
docker cp 5871cb60faa1:/home/INBOMISEQ/7_tax_assignment_after_filtering ./

