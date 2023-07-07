#!/bin/bash

for smp in ./2_trimmed/*-fullytrimmed.fq; do
  #echo $smp
  tmp=${smp%-fullytrimmed.fq}
  #echo $tmp
  SAMPLE=${tmp##*/}
  echo "renaming sequences from $SAMPLE...."
  #voeg sample=samplename toe aan de fastq files zodat obitools hiermee kan werken
  awk '/^>/ {$0=$1 " sample='"$SAMPLE"';"}1' ./3_quality_filtered/"$SAMPLE"_merged_filtered.fa > ./4_obi_input/"$SAMPLE"_merged_filtered_renamed.fa
  echo "done renaming sequences from $SAMPLE."
  
  #voeg de fastas samen van alle stalen in de variabele ALLSAMPLES
  ALLSAMPLES+="./4_obi_input/"$SAMPLE"_merged_filtered_renamed.fa "
done

#Schrijf het object ALLSAMPLES weg in het bestand all_samples.fa
echo "concatenating all samples...."
cat $ALLSAMPLES > ./4_obi_input/all_samples.fa
echo "done concatenating all samples."

