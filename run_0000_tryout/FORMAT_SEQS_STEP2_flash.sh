
#!/bin/bash

###STAP1: Alignment F en R (Stash ipv pear)

FLASHMIN=20
N=195 #maximaal fragment (enkel voor RIAZ?, Voor TELEO andere waarde)
FILES=(./0_adapters_removed/*_F.fq ) #kijk welke fq files er zijn om hier de stalen uit te halen

 
for smp in ./0_adapters_removed/*_F.fq; do
  #echo $smp
  tmp=${smp%_F.fq}
  #echo $tmp
  SAMPLE=${tmp##*/}
  echo aligning $SAMPLE
  #arg1: reads1 (forward)
  #arg2: reads2 (reverse)
  #-m: minimal overlap (always set to 20)
  #-o: output prefix
  #-O: allow outies, match <-- ipv -->
  #andere argumenten voor aantal processoren en zo kunnen nog toegevoegd worden
  flash ./0_adapters_removed/"$SAMPLE"_F.fq ./0_adapters_removed/"$SAMPLE"_R.fq -m $FLASHMIN -M $N -o ./1_MERGED/"$SAMPLE"
  echo "done merging reads for $SAMPLE."
done


# #Loop over all files and do all the commands
# for f in "${FILES[@]}" 
# 
# 
# 
# cutadapt -a CTAGAGGAGCCTGTTCTA -A GGGGTATCTAATCCCAGT -o ./0_adapters_removed/"$SAMPLE"_F.fq -p ./0_adapters_removed/"$SAMPLE"_R.fq "$SAMPLE"_F.fq "$SAMPLE"_R.fq -m 20 -e 0.12
# echo "done removing adapters for $SAMPLE."
# echo
# 
# #MERGE F AND R READ
# echo "merging reads for $SAMPLE...."
# pear -f ./0_adapters_removed/"$SAMPLE"_F.fq -r ./0_adapters_removed/"$SAMPLE"_R.fq -o ./1_merged/"$SAMPLE" -v 20 -n $N -m $M -y 100G -j 8 -u 1
# echo "done merging reads for $SAMPLE."
# 
# #PRIMER REMOVAL
# echo "removing primers for $SAMPLE...."
# #remove first primer using cutadapt. 
# cutadapt -g $FWD --discard-untrimmed -e 0.15 -o ./2_trimmed/"$SAMPLE"-trimmed-5prime.fq ./1_merged/"$SAMPLE".assembled.fastq
# #remove second primer using cutadapt.
# cutadapt -a $REV --discard-untrimmed -e 0.15 -o ./2_trimmed/"$SAMPLE"-fullytrimmed.fq ./2_trimmed/"$SAMPLE"-trimmed-5prime.fq
# echo "done removing primers for $SAMPLE."
# 
# #QUALITY STATISTICS AND FILTERING
# echo "calculating quality statistics and filtering $SAMPLE...."
# vsearch -fastq_stats ./2_trimmed/"$SAMPLE"-fullytrimmed.fq -log ./3_quality_filtered/"$SAMPLE"_fastqstats.log
# vsearch -fastq_filter ./2_trimmed/"$SAMPLE"-fullytrimmed.fq -fastaout ./3_quality_filtered/"$SAMPLE"_merged_filtered.fa -fastq_maxee 0.5
# echo "done calculating quality statistics and trimming $SAMPLE."
# 
# #RENAMING SEQUENCES OF ALL SAMPLES
# echo "renaming sequences from $SAMPLE...."
# awk '/^>/ {$0=$1 " sample='"$SAMPLE"';"}1' ./3_quality_filtered/"$SAMPLE"_merged_filtered.fa > ./4_renamed_and_concatenated/"$SAMPLE"_merged_filtered_renamed.fa
# echo "done renaming sequences from $SAMPLE."
# 
# # echo
# # echo "DONE PROCESSING SAMPLE $SAMPLE."
# 
# #create a new variable that is a string which contains all sample names ($SAMPLE) with extension _merged_filtered_renamed.fa
# ALLSAMPLES+="./4_renamed_and_concatenated/"$SAMPLE"_merged_filtered_renamed.fa "
# 
# done
# 
# #from now on, all samples will be concatenated, and can be processed in single commands only (the loop is not necessary anymore).
# 
# #CONCATENATE ALL SEQUENCES
# echo
# echo "concatenating all samples...."
# cat $ALLSAMPLES > ./4_renamed_and_concatenated/all_samples.fa
# echo "done concatenating all samples."
# echo
# 
# #activate virtual environment for OBItools
# source /home/genomics/ahaegeman/.venv_obitools/bin/activate
# 
# #DEREPLICATION
# echo
# echo "dereplicating sequences of all samples...."
# obiuniq --without-progress-bar -m sample ./4_renamed_and_concatenated/all_samples.fa > ./5_dereplication/all_derep.fa
# #count number of occurrences of each sequence
# obistat --without-progress-bar -c count ./5_dereplication/all_derep.fa | sort -nk1 > ./5_dereplication/all_derep_unique_sequence_counts.txt
# echo "done dereplicating sequences of all samples."
# echo
# 
# #FILTERING
# echo
# echo "filtering sequences of all samples...."
# #keep only sequences that occur > MINCOUNT times
# obigrep --without-progress-bar -p "count>=$MINCOUNT" ./5_dereplication/all_derep.fa > ./6_filtering/all_derep_mincount"$MINCOUNT".fa
# #identify PCR and/or sequencing errors
# obiclean --without-progress-bar -s merged_sample -r 0.05 -H -d 1 ./6_filtering/all_derep_mincount"$MINCOUNT".fa > ./6_filtering/all_derep_mincount"$MINCOUNT"_cleaned.fa
# echo "done filtering sequences of all samples."
# echo
# 
# #TAXONOMY ASSIGNMENT
# echo
# echo "assigning taxonomy to sequences...."
# ecotag --without-progress-bar -d $REF_DB -R $AMPLICON_DB ./6_filtering/all_derep_mincount"$MINCOUNT"_cleaned.fa > ./7_tax_assignment_after_filtering/all_derep_mincount"$MINCOUNT"_cleaned_tagged.fa
# echo "done assigning taxonomy to sequences."
# echo
# 
# #GENERATE OUTPUT TABLE
# echo
# echo "generating output table..."
# #first remove some of the attributes which you do not need anymore
# obiannotate --without-progress-bar --delete-tag=scientific_name_by_db --delete-tag=obiclean_samplecount --delete-tag=definition --delete-tag=obiclean_status --delete-tag=obiclean_count --delete-tag=obiclean_singletoncount --delete-tag=obiclean_cluster --delete-tag=obiclean_internalcount --delete-tag=obiclean_head --delete-tag=taxid_by_db --delete-tag=obiclean_headcount --delete-tag=id_status --delete-tag=rank_by_db --delete-tag=order_name --delete-tag=order ./7_tax_assignment_after_filtering/all_derep_mincount"$MINCOUNT"_cleaned_tagged.fa > ./7_tax_assignment_after_filtering/all_derep_mincount"$MINCOUNT"_cleaned_tagged_ann.fa
# #sort the sequences according to abundance
# obisort --without-progress-bar -k count -r ./7_tax_assignment_after_filtering/all_derep_mincount"$MINCOUNT"_cleaned_tagged_ann.fa > ./7_tax_assignment_after_filtering/all_derep_mincount"$MINCOUNT"_cleaned_tagged_ann_sort.fa
# #generate a tab delimited output table
# obitab --without-progress-bar -o ./7_tax_assignment_after_filtering/all_derep_mincount"$MINCOUNT"_cleaned_tagged_ann_sort.fa > ./7_tax_assignment_after_filtering/all_derep_mincount"$MINCOUNT"_cleaned_tagged_ann_sort_final_table.txt
# echo "done generating output table."
# echo
# date
# 
# #deactivate virtual environment for OBItools
# deactivate