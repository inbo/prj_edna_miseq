#!/bin/bash

####################################################################################################################################################################################################
# Author:	Annelies Haegeman, Flanders Research Institute for Agriculture, Fisheries and Food, Melle, Belgium
# Contact:	annelies.haegeman@ilvo.vlaanderen.be
# Date:		12/09/2016
#
# This script analyzes metabarcoding data, from demultiplexed data to count table. It uses several third party software tools, which should be installed on your computer:
#	1. sabre (https://github.com/najoshi/sabre) (demultiplexing tool, should be in $PATH)
#	2. cutadapt (https://cutadapt.readthedocs.io/en/stable/guide.html) (primer removal, should be in $PATH)
#	3. pear (https://cme.h-its.org/exelixis/web/software/pear/) (merging F and R reads, should be in $PATH)
#	4. vsearch (https://github.com/torognes/vsearch) (quality filtering, should be in $PATH)
#	5. OBITools (https://pythonhosted.org/OBITools/welcome.html) (sequence variant cleaning and counting, commands should be in $PATH)
#
# Procedure:
#	1. Merging of forward and reverse reads using pear (https://cme.h-its.org/exelixis/web/software/pear/)
#	2. Removal of primers using cutadapt (https://cutadapt.readthedocs.io/en/stable/guide.html)
#	3. Quality filtering using `fastq_filter`from vsearch (https://github.com/torognes/vsearch), with a maximum expected error of 0.5
#	4. Renaming the sequences to contain the sample name and concatenating the sequences of all samples
#	5. Dereplicate the sequences using `obiuniq` from OBITools (https://pythonhosted.org/OBITools/welcome.html)
#	6. Filtering and cleaning the sequences using `obigrep` and `obiclean` from OBITools (https://pythonhosted.org/OBITools/welcome.html) with as settings `-r 0.05`, `-H` and `-d 1`
#	7. Assigning a taxonomy to the sequences using `ecotag` from OBITools (https://pythonhosted.org/OBITools/welcome.html)
#	8. Generating an output table using `obiannotate`, `obisort` and `obitab` from OBITools (https://pythonhosted.org/OBITools/welcome.html)#
#
#How to run:
#`eDNA_pipeline.sh -f fragment -d input_directory -r reference_database -a amplicon_database -m mincount`
#
#`-f` : fragment which is being analyzed, currently "Riaz" and "Teleo" are supported. These correspond to the primers ACTGGGATTAGATACCCC and TAGAACAGGCTCCTCTAG for "Riaz" and ACACCGCCCGTCACTCT and CTTCCGGTACACTTACCRTG for "Teleo".
#`-d` : directory which contains the demultiplexed sequence files, ending in `_1.fq` (forward reads) and `_2.fq` (reverse reads)
#`-r` : full path to the reference database in ecoPCR (https://pythonhosted.org/OBITools/scripts/ecoPCR.html) format created by `obiconvert`
#`-a` : full path to the amplicon database in fasta format (result of ecoPCR (https://pythonhosted.org/OBITools/scripts/ecoPCR.html) and OBITools (https://pythonhosted.org/OBITools/welcome.html) commands `ecoPCR` and `obiuniq`)  
#`-m` : minimum number of counts (summed over all samples) for a sequence to be kept
####################################################################################################################################################################################################

# in case of no arguments, show help message
if [ $# == 0 ]; then
    echo "
This script analyzes metabarcoding data, from demultiplexed data to count table. It uses several third party software tools, which should be installed on your computer: sabre, cutadapt, pear, vsearch and OBITools.

Usage: eDNA_pipeline.sh -f fragment -d input_directory -r reference_database -a amplicon_database -m mincount
Where:
	-f : fragment which is being analyzed, currently "Riaz" and "Teleo" are supported. These correspond to the primers ACTGGGATTAGATACCCC and TAGAACAGGCTCCTCTAG for "Riaz" and ACACCGCCCGTCACTCT and CTTCCGGTACACTTACCRTG for "Teleo".
	-d : directory which contains the demultiplexed sequence files, ending in _1.fq (forward reads) and _2.fq (reverse reads)
	-r : full path to the reference database in ecoPCR (https://pythonhosted.org/OBITools/scripts/ecoPCR.html) format created by obiconvert
	-a : full path to the amplicon database in fasta format (result of ecoPCR (https://pythonhosted.org/OBITools/scripts/ecoPCR.html) and OBITools (https://pythonhosted.org/OBITools/welcome.html) commands ecoPCR and obiuniq)  
	-m : minimum number of counts (summed over all samples) for a sequence to be kept
	
The script does the following:
	1. Merging of forward and reverse reads using pear (https://cme.h-its.org/exelixis/web/software/pear/)
	2. Removal of primers using cutadapt (https://cutadapt.readthedocs.io/en/stable/guide.html)
	3. Quality filtering using fastq_filter from vsearch (https://github.com/torognes/vsearch), with a maximum expected error of 0.5
	4. Renaming the sequences to contain the sample name and concatenating the sequences of all samples
	5. Dereplicate the sequences using obiuniq from OBITools (https://pythonhosted.org/OBITools/welcome.html)
	6. Filtering and cleaning the sequences using obigrep and obiclean from OBITools (https://pythonhosted.org/OBITools/welcome.html) with as settings -r 0.05, -H and -d 1
	7. Assigning a taxonomy to the sequences using ecotag from OBITools (https://pythonhosted.org/OBITools/welcome.html)
	8. Generating an output table using obiannotate, obisort and obitab from OBITools (https://pythonhosted.org/OBITools/welcome.html)#
"
    exit 1
fi



#Read input arguments
while getopts f:d:r:a:m: option
do
case "${option}" in
f) FRAGMENT=${OPTARG};;
d) DIR=${OPTARG};;
r) REF_DB=${OPTARG};;
a) AMPLICON_DB=${OPTARG};;
m) MINCOUNT=${OPTARG};;
esac
done


#Riaz or Teleo analysis?
if [ $FRAGMENT == "Riaz" ]; then
	FWD="ACTGGGATTAGATACCCC"
	REV="CTAGAGGAGCCTGTTCTA"  #reverse complement of reverse primer
	N=60	#minimum size for pear
	M=195	#maximum size for pear
elif [ $FRAGMENT == "Teleo" ]; then
	FWD="ACACCGCCCGTCACTCT"
	REV="CATGGTAAGTGTACCGGAAG"  #reverse complement of reverse primer
	N=20	#minimum size for pear
	M=140	#maximum size for pear
else
	exit 1
fi

date
echo

#change directory to specified folder
cd $DIR

#create several new directories to put the output after each step
mkdir ./1_merged
mkdir ./2_trimmed
mkdir ./3_quality_filtered
mkdir ./4_renamed_and_concatenated
mkdir ./5_dereplication
mkdir ./6_filtering
mkdir ./7_tax_assignment_after_filtering

# Define the variable FILES that contains all the forward data sets (here only forward, otherwise you will do everything in duplicate!)
# When you make a variable, you can not use spaces! Otherwise you get an error.
FILES=( *_1.fq )

#Loop over all files and do all the commands
for f in "${FILES[@]}" 
do 
#Define the variable SAMPLE who contains the basename where the extension is removed (-1.fastq.gz)
SAMPLE=`basename $f _1.fq`

echo
echo "PROCESSING sample $SAMPLE "
echo

#MERGE F AND R READ
echo "merging reads for $SAMPLE...."
pear -f "$SAMPLE"_1.fq -r "$SAMPLE"_2.fq -o ./1_merged/"$SAMPLE" -p 1.0 -v 20 -n $N -m $M -y 100G -j 8 -u 1
echo "done merging reads for $SAMPLE."

#PRIMER REMOVAL
echo "removing primers for $SAMPLE...."
#remove first primer using cutadapt. 
cutadapt -g $FWD --discard-untrimmed -e 0.15 -o ./2_trimmed/"$SAMPLE"-trimmed-5prime.fq ./1_merged/"$SAMPLE".assembled.fastq
#remove second primer using cutadapt.
cutadapt -a $REV --discard-untrimmed -e 0.15 -o ./2_trimmed/"$SAMPLE"-fullytrimmed.fq ./2_trimmed/"$SAMPLE"-trimmed-5prime.fq
echo "done removing primers for $SAMPLE."

#QUALITY STATISTICS AND FILTERING
echo "calculating quality statistics and filtering $SAMPLE...."
vsearch -fastq_stats ./2_trimmed/"$SAMPLE"-fullytrimmed.fq -log ./3_quality_filtered/"$SAMPLE"_fastqstats.log
vsearch -fastq_filter ./2_trimmed/"$SAMPLE"-fullytrimmed.fq -fastaout ./3_quality_filtered/"$SAMPLE"_merged_filtered.fa -fastq_maxee 0.5
echo "done calculating quality statistics and trimming $SAMPLE."

#RENAMING SEQUENCES OF ALL SAMPLES
echo "renaming sequences from $SAMPLE...."
awk '/^>/ {$0=$1 " sample='"$SAMPLE"';"}1' ./3_quality_filtered/"$SAMPLE"_merged_filtered.fa > ./4_renamed_and_concatenated/"$SAMPLE"_merged_filtered_renamed.fa
echo "done renaming sequences from $SAMPLE."

# echo
# echo "DONE PROCESSING SAMPLE $SAMPLE."

#create a new variable that is a string which contains all sample names ($SAMPLE) with extension _merged_filtered_renamed.fa
ALLSAMPLES+="./4_renamed_and_concatenated/"$SAMPLE"_merged_filtered_renamed.fa "

done

#from now on, all samples will be concatenated, and can be processed in single commands only (the loop is not necessary anymore).

#CONCATENATE ALL SEQUENCES
echo
echo "concatenating all samples...."
cat $ALLSAMPLES > ./4_renamed_and_concatenated/all_samples.fa
echo "done concatenating all samples."
echo


#DEREPLICATION
echo
echo "dereplicating sequences of all samples...."
obiuniq --without-progress-bar -m sample ./4_renamed_and_concatenated/all_samples.fa > ./5_dereplication/all_derep.fa
#count number of occurrences of each sequence
obistat --without-progress-bar -c count ./5_dereplication/all_derep.fa | sort -nk1 > ./5_dereplication/all_derep_unique_sequence_counts.txt
echo "done dereplicating sequences of all samples."
echo

#FILTERING
echo
echo "filtering sequences of all samples...."
#keep only sequences that occur > MINCOUNT times
obigrep --without-progress-bar -p "count>=$MINCOUNT" ./5_dereplication/all_derep.fa > ./6_filtering/all_derep_mincount"$MINCOUNT".fa
#identify PCR and/or sequencing errors
obiclean --without-progress-bar -s merged_sample -r 0.05 -H -d 1 ./6_filtering/all_derep_mincount"$MINCOUNT".fa > ./6_filtering/all_derep_mincount"$MINCOUNT"_cleaned.fa
echo "done filtering sequences of all samples."
echo

#TAXONOMY ASSIGNMENT
echo
echo "assigning taxonomy to sequences...."
ecotag --without-progress-bar -d $REF_DB -R $AMPLICON_DB ./6_filtering/all_derep_mincount"$MINCOUNT"_cleaned.fa > ./7_tax_assignment_after_filtering/all_derep_mincount"$MINCOUNT"_cleaned_tagged.fa
echo "done assigning taxonomy to sequences."
echo

#GENERATE OUTPUT TABLE
echo
echo "generating output table..."
#first remove some of the attributes which you do not need anymore
obiannotate --without-progress-bar --delete-tag=scientific_name_by_db --delete-tag=obiclean_samplecount --delete-tag=definition --delete-tag=obiclean_status --delete-tag=obiclean_count --delete-tag=obiclean_singletoncount --delete-tag=obiclean_cluster --delete-tag=obiclean_internalcount --delete-tag=obiclean_head --delete-tag=taxid_by_db --delete-tag=obiclean_headcount --delete-tag=id_status --delete-tag=rank_by_db --delete-tag=order_name --delete-tag=order ./7_tax_assignment_after_filtering/all_derep_mincount"$MINCOUNT"_cleaned_tagged.fa > ./7_tax_assignment_after_filtering/all_derep_mincount"$MINCOUNT"_cleaned_tagged_ann.fa
#sort the sequences according to abundance
obisort --without-progress-bar -k count -r ./7_tax_assignment_after_filtering/all_derep_mincount"$MINCOUNT"_cleaned_tagged_ann.fa > ./7_tax_assignment_after_filtering/all_derep_mincount"$MINCOUNT"_cleaned_tagged_ann_sort.fa
#generate a tab delimited output table
obitab --without-progress-bar -o ./7_tax_assignment_after_filtering/all_derep_mincount"$MINCOUNT"_cleaned_tagged_ann_sort.fa > ./7_tax_assignment_after_filtering/all_derep_mincount"$MINCOUNT"_cleaned_tagged_ann_sort_final_table.txt
echo "done generating output table."
echo
date

