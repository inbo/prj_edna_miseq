#!/bin/bash

InputBarcodeTable="/app/samples_multiplex.txt"
Freads="/app/test_fwd.fastq"
Rreads="/app/test_rev.fastq"


SabreBarcodeTable0="Barcode_table_for_Sabre_round1.txt"
SabreBarcodeTable1="Barcode_table_for_Sabre_round1_bis.txt"
cat $InputBarcodeTable | sed '/^$/d' > temp
while read col1 col2 col3; do 
	echo -e "$col2""\t""$col1"_R1.fq"\t""$col1"_F1.fq >> $SabreBarcodeTable0;		#first barcode sequence for this sample
	echo -e "$col3""\t""$col1"_R2.fq"\t""$col1"_F2.fq >> $SabreBarcodeTable1;		#second barcode sequence for this sample
	done < temp
	