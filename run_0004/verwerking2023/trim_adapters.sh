#!/bin/bash

FILES=( *_F.fq ) #enkel forward omdat read length miseq (220bp) >  Fragment, dus R is gewoon een RC duplicaat
FWD="ACTGGGATTAGATACCCC" #original forward RIAZ primer
FWDRC="GGGGTATCTAATCCCAGT" #reverse complement of forward RIAZ primer
REVRC="CTAGAGGAGCCTGTTCTA"  #reverse complement of reverse primer (hier gebruiken)
REV="TAGAACAGGCTCCTCTAG" #orignal reverse primer
CADMIN=20 #minimum length
CADERR=0.12 #Allow 2 errors on 18 (RIAZ primer length)

for f in "${FILES[@]}"
do 
  echo "-----------------"
  echo $f
  SAMPLE=`basename $f _F.fq` #contains the basename where the extension is removed (-1.fastq.gz)
  echo "removing adapters for $SAMPLE...."
  #Dus hier enkel de forward primers (specifiek voor deze case)
  cutadapt -a $REVRC -A $FWDRC -o ./0_adapters_removed/"$SAMPLE"_F.fq -p ./0_adapters_removed/"$SAMPLE"_R.fq "$SAMPLE"_F.fq "$SAMPLE"_R.fq -m $CADMIN -e $CADERR
  echo "done removing adapters for $SAMPLE."
done
cutadapt -a CTAGAGGAGCCTGTTCTA -A GGGGTATCTAATCCCAGT -o ./0_adapters_removed/"$SAMPLE"_F.fq -p ./0_adapters_removed/"$SAMPLE"_R.fq "$SAMPLE"_F.fq "$SAMPLE"_R.fq -m 20 -e 0.12
