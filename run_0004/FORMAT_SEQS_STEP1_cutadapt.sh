#!/bin/bash

#################################################################


#BASED ON script from Annelies Haegeman
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
#if [ $# == 0 ]; then
#    echo "
# This script analyzes metabarcoding data, from demultiplexed data to count table. It uses several third party software tools, which should be installed on your computer: sabre, cutadapt, pear, vsearch and OBITools.
# 
# Usage: eDNA_pipeline.sh -f fragment -d input_directory -r reference_database -a amplicon_database -m mincount
# Where:
# 	-f : fragment which is being analyzed, currently "Riaz" and "Teleo" are supported. These correspond to the primers ACTGGGATTAGATACCCC and TAGAACAGGCTCCTCTAG for "Riaz" and ACACCGCCCGTCACTCT and CTTCCGGTACACTTACCRTG for "Teleo".
# 	-d : directory which contains the demultiplexed sequence files, ending in _1.fq (forward reads) and _2.fq (reverse reads)
# 
# The script does the following:
# 	0. Removal of adapters at the end of the sequenced fragment (because the fragments are shorter than the used sequencing length) with cutadapt
# 	1. Merging of forward and reverse reads using pear (https://cme.h-its.org/exelixis/web/software/pear/)
# 	2. Removal of primers using cutadapt (https://cutadapt.readthedocs.io/en/stable/guide.html)
# 	3. Quality filtering using fastq_filter from vsearch (https://github.com/torognes/vsearch), with a maximum expected error of 0.5
# 	4. Renaming the sequences to contain the sample name and concatenating the sequences of all samples
# "
#     exit 1
# fi
# 
# 
# 
# #Read input arguments
# while getopts f:d:r:a:m: option
# do
# case "${option}" in
# f) FRAGMENT=${OPTARG};;
# d) DIR=${OPTARG};;
# r) REF_DB=${OPTARG};;
# a) AMPLICON_DB=${OPTARG};;
# m) MINCOUNT=${OPTARG};;
# esac
# done


# #Riaz or Teleo analysis?
# if [ $FRAGMENT == "Riaz" ]; then
# 	FWD="ACTGGGATTAGATACCCC"
# 	REV="CTAGAGGAGCCTGTTCTA"  #reverse complement of reverse primer
# 	N=60	#minimum size for pear
# 	M=195	#maximum size for pear
# elif [ $FRAGMENT == "Teleo" ]; then
# 	FWD="ACACCGCCCGTCACTCT"
# 	REV="CATGGTAAGTGTACCGGAAG"  #reverse complement of reverse primer
# 	N=20	#minimum size for pear
# 	M=140	#maximum size for pear
# else
# 	exit 1
# fi
# 
# date
# echo

# #change directory to specified folder
# cd $DIR

#create several new directories to put the output after each step
mkdir ./0_adapters_removed
mkdir ./1_merged
mkdir ./2_trimmed
mkdir ./3_quality_filtered
mkdir ./4_renamed_and_concatenated


#Static assignment of RIaz (uncomment if working with CHOICE TELEO RIAZ)
FWD="ACTGGGATTAGATACCCC" #original forward RIAZ primer
FWDRC="GGGGTATCTAATCCCAGT" #reverse complement of forward RIAZ primer
REVRC="CTAGAGGAGCCTGTTCTA"  #reverse complement of reverse primer (hier gebruiken)
REV="TAGAACAGGCTCCTCTAG" #orignal reverse primer
N=60	#minimum size for pear
M=195	#maximum size for pear
V=20 #minimum overlap
CADMIN=20 #minium length
CADERR=0.12 #Allow 2 errors on 18 (RIAZ primer length)



# Define the variable FILES that contains all the forward data sets (here only forward, otherwise you will do everything in duplicate!)
# When you make a variable, you can not use spaces! Otherwise you get an error.
#ADAPTER REMOVAL AT 3' END 
#Since we sequenced with MiSeq at 2x220 bp, we expect the complete Riaz fragment in both the forward and the reverse read. 
#This means that we will reach the other end of the fragment in the same read.
#FastQC reports confirm that the Nextera adapter is indeed found at the end of some of the reads.
#To remove it, we look for the reverse complement R primer at the end of the F read. Similarly, we look in the R read for the reverse complement primer at the end of the read.
#This can be done for both F and R reads simultaneously using cutadapt. We set an additional length filter of minimum 20 bp (-m 20) to avoid having empty sequences at the end (sequences that contained adapters only for example).
#Riaz-F : ACTGGGATTAGATACCCC (RC GGGGTATCTAATCCCAGT)
#Riaz-R : TAGAACAGGCTCCTCTAG (RC CTAGAGGAGCCTGTTCTA)
#The standard cutadapt command uses the setting -e 0.1 by default, this means that max. 10% errors in the adapter are allowed (1 base out of 18). 
#If we allow 2 errors out of 18 bases, we set the maximum error at 0.12.


### STAP1: Removing adapters
FILES=( *_F.fq ) #UITZONDERLIJK, NORMAAL GEZIEN F en R, maar in deze opzet F alleen

#IK GA HIER ANDERS TEWERK GAAN EN GA STAP PER STAP ALS APARTE LUS ZIEN
#EEN BEETJE OVERHEAD NAAR MEER IN LIJN MET R
#EN DUIDELIJKER ALS BEGINNER
for f in "${FILES[@]}"
do 
echo (f)
done
  #Define the variable SAMPLE who contains the basename where the extension is removed (-1.fastq.gz)
  SAMPLE=`basename $f _F.fq`
  echo "removing adapters for $SAMPLE...."
  #Dus hier enkel de forward primers (specifiek voor deze case)
  #-a ADAPTOR 3'end to be removed from the first read in a pear
  #-A ADAPTER            3' adapter to be removed from second read in a pair.
  #-o outputfile first read pair
  #main argument (no flag) input file (here the F file, wegens de specifieke omstandigheden in dit project)
  #-p outputfile second read in a pair
  #-m mininum length, discard lower length
  #-e error rate allowed (2/18 = 0.12) in adapter
  cutadapt -a $REVRC -A $FWDRC -o ./0_adapters_removed/"$SAMPLE"_F.fq -p ./0_adapters_removed/"$SAMPLE"_R.fq "$SAMPLE"_F.fq "$SAMPLE"_R.fq -m $CADMIN -e $CADERR
  echo "done removing adapters for $SAMPLE."
done
