#!/bin/bash

for smp in ./2_trimmed/*-fullytrimmed.fq; do
  #echo $smp
  tmp=${smp%-fullytrimmed.fq}
  #echo $tmp
  SAMPLE=${tmp##*/}
  echo "quality filtering for $SAMPLE...."

  echo "calculating quality statistics and filtering $SAMPLE...."
  vsearch -fastq_stats ./2_trimmed/"$SAMPLE"-fullytrimmed.fq -log ./3_quality_filtered/"$SAMPLE"_fastqstats.log
  vsearch -fastq_filter ./2_trimmed/"$SAMPLE"-fullytrimmed.fq -fastaout ./3_quality_filtered/"$SAMPLE"_merged_filtered.fa -fastq_maxee 0.5
  echo "done calculating quality statistics and trimming $SAMPLE."
done

