#!/bin/bash

####################################################################################################################################################################################################
# Author:	Annelies Haegeman, Flanders Research Institute for Agriculture, Fisheries and Food, Melle, Belgium
# Contact:	annelies.haegeman@ilvo.vlaanderen.be
# Date:		12/09/2016
#
# This script is made for demultiplexing samples that are made from dual barcodes of variable lengths.
# It uses the software "sabre" (https://github.com/najoshi/sabre) which can handle barcodes of variable lengths. However this software cannot handle barcodes on both ends of the fragment.
# Moreover, in ligation-based protocols, the fragments are NOT directional, which means that each barcode should be checked in both directions (each barcode can either be at the beginning of the F-read, or at the beginning of the R read).
# Procedure:
#	1. Read a table with a list of the sample names and both barcodes used for that sample (samplename<tab>barcode1<tab>barcode2) and read the input files (F and R reads file)
#	2. Make a new table which is suited for use in Sabre: this file contains only 1 barcode per line, and the name of the output files for the paired reads in the second and third column.
#	3. Start the first round of demultiplexing using Sabre. Each sample has to be done twice, once for the first barcode, and once for the second barcode. Since Sabre tries to find the barcode in the beginning of the read, it will identify both forward and reverse sequenced fragments by looking at both barcodes. 
#	   The output files of this first round of demultiplexing are reversed in order: the original forward files (where the barcode was found and trimmed off), become reverse files in the output, and the original reverse files (where no barcode was identified yet) now become forward files. This makes sure that in the resulting files, all new forward files start again with a barcode.
#	4. Both file pairs are catted together to end up with one output file after the first round of demultiplexing, which now has all remaining barcodes at the beginning of the read.
#	5. A second round of demultiplexing is done, again using the two barcodes per sample.
#	6. Both output file pairs of the second round of demultiplexing are catted together to have the final paired reads that do not contain barcodes anymore.
#
#
####################################################################################################################################################################################################

#Andere voorbereidingen
#gzip -d R1.fastq.gz
#gzip -d R2.fastq.gz
#./R_demux.sh -b R_samplesheet.smp -f R1.fastq -r R2.fastq

#output *.fq werkt niet rechtstreeks
#docker cp 933449a5db4d:/app/E2022STF275PC_F.fq .
#docker cp 933449a5db4d:/app/E2022STF275PC_R.fq .
#...



# in case of no arguments, show help message
if [ $# == 0 ]; then
    echo "
This program can be used for demultiplexing data which consists of variable length dual barcodes present at the beginning of the forward and the reverse reads.
It uses the software "sabre" (https://github.com/najoshi/sabre) which can handle barcodes of variable lengths. This software should be installed in should be in your PATH variable.
This script calls "sabre" multiple times to ensure that both directions are checked for the barcodes (undirectional cloning of the fragments).
Only exact matches to both barcodes end up in the resulting sample files.

Usage: eDNA_demultiplexing_exact_match_dual_barcodes.sh -b barcodefile.txt -f forwardreads.fq -r reversereads.fq
Where:
	-b : tab delimited file; column 1: name of sample corresponding to a certain  barcode combination; column2: barcode used in primer 1; column3 : barcode used in primer 2
	-f : forward reads file to be demultiplexed in fastq format (should be unzipped)
	-r : reverse reads file to be demultiplexed in fastq format (should be unzipped)
"
    exit 1
fi


#STEP1: read table and F and R reads using flagged arguments
#input file with samples names and the two barcodes
while getopts b:f:r:fe:re: option
do
case "${option}" in
b) InputBarcodeTable=${OPTARG};;
f) Freads=${OPTARG};;
r) Rreads=${OPTARG};;
esac
done


#InputBarcodeTable="/home/genomics/ahaegeman/eDNA/Run6_aug2018/1_Demultiplexing/barcodes_ligation3.txt"
#Freads="/home/genomics/ALL_RAW_SEQ_DATA/03_eDNA/Taxonomic_profiling/12S/1221/not_demultiplexed/17121-12/17121FL-12-01-03_S71_L005_R1_001.fastq"
#Rreads="/home/genomics/ALL_RAW_SEQ_DATA/03_eDNA/Taxonomic_profiling/12S/1221/not_demultiplexed/17121-12/17121FL-12-01-03_S71_L005_R2_001.fastq"

	
# Remove empty lines of barcode table 
cat $InputBarcodeTable | sed '/^$/d' > temp
			
# Remove header of barcode table if this is present (deletes lines starting with #)
cat temp | grep -v "^#" > temp2
		
		
#STEP2: create new table for Sabre
#create new file for sabre input (demultiplexing round 1)
SabreBarcodeTable0="Barcode_table_for_Sabre_round1.txt"
SabreBarcodeTable1="Barcode_table_for_Sabre_round1_bis.txt"
while read col1 col2 col3; do 
	echo -e "$col2""\t""$col1"_R1.fq"\t""$col1"_F1.fq >> $SabreBarcodeTable0;		#first barcode sequence for this sample
	echo -e "$col3""\t""$col1"_R2.fq"\t""$col1"_F2.fq >> $SabreBarcodeTable1;		#second barcode sequence for this sample
	done < temp2

# Remove temp file
rm temp

#STEP3: Sabre demultiplexing round 1
sabre pe -f $Freads -r $Rreads -b $SabreBarcodeTable0 -u unknown-round1-1.fq -w unknown-round1-2.fq
sabre pe -f $Freads -r $Rreads -b $SabreBarcodeTable1 -u unknown-round1bis-1.fq -w unknown-round1bis-2.fq

#STEP4: put both files together in a way that all forward reads start with the barcode not detected yet
FILES=( *_F1.fq )
#Loop over all files and do all the commands
for f in "${FILES[@]}" 
do 
SAMPLE=`basename $f _F1.fq`	#Define the variable SAMPLE who contains the basename where the extension is removed (_F1.fq)
cat "$SAMPLE"_F1.fq "$SAMPLE"_F2.fq > "$SAMPLE"_round1_F.fq	#concatenate the F reads
cat "$SAMPLE"_R1.fq "$SAMPLE"_R2.fq > "$SAMPLE"_round1_R.fq	#concatenate the R reads
rm "$SAMPLE"_F1.fq "$SAMPLE"_F2.fq "$SAMPLE"_R1.fq "$SAMPLE"_R2.fq	#remove original reads from first round
done

#STEP5: second round of demultiplexing, do this seperately for each sample by reading again the input barcode table file line per line, and doing the demultiplexing per input file
SabreBarcodeTable2="Barcode_table_for_Sabre_round2.txt"
while read col1 col2 col3; do 
		echo -e "$col2""\t""$col1"_round2_F1.fq"\t""$col1"_round2_R1.fq > $SabreBarcodeTable2;		#first barcode sequence for this sample
		echo -e "$col3""\t""$col1"_round2_R2.fq"\t""$col1"_round2_F2.fq >> $SabreBarcodeTable2;		#second barcode sequence for this sample
		sabre pe -f `echo "$col1"_round1_F.fq` -r `echo "$col1"_round1_R.fq` -b $SabreBarcodeTable2 -u `echo "$col1"_unknown_round2_1.fq` -w `echo "$col1"_unknown_round2_2.fq`
		done < temp2

# Remove temp files
rm temp2 $SabreBarcodeTable2 $SabreBarcodeTable0 $SabreBarcodeTable1
# Remove unknown files
rm unknown-round1-1.fq unknown-round1-2.fq unknown-round1bis-1.fq unknown-round1bis-2.fq

#STEP6: put both files together
FILES=( *_round2_F1.fq )
#Loop over all files and do all the commands
for f in "${FILES[@]}" 
do 
SAMPLE=`basename $f _round2_F1.fq`	#Define the variable SAMPLE who contains the basename where the extension is removed (_round2_F1.fq)
cat "$SAMPLE"_round2_F1.fq "$SAMPLE"_round2_F2.fq > "$SAMPLE"_F.fq	#concatenate the F reads
cat "$SAMPLE"_round2_R1.fq "$SAMPLE"_round2_R2.fq > "$SAMPLE"_R.fq	#concatenate the R reads
rm "$SAMPLE"_round1_F.fq "$SAMPLE"_round1_R.fq "$SAMPLE"_round2_F1.fq "$SAMPLE"_round2_F2.fq "$SAMPLE"_round2_R1.fq "$SAMPLE"_round2_R2.fq	#remove original reads from second round
done

#CLEANUP 
rm *_unknown_round2_1.fq # "unknown" files
rm *_unknown_round2_2.fq # "unknown" files
