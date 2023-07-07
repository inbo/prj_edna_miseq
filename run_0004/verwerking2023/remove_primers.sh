#!/bin/bash

FWD="ACTGGGATTAGATACCCC"
REV="CTAGAGGAGCCTGTTCTA"  #reverse complement of reverse primer
PRMERR=0.15

for smp in ./1_merged/*.extendedFrags.fastq; do
  #echo $smp
  tmp=${smp%.extendedFrags.fastq}
  #echo $tmp
  SAMPLE=${tmp##*/}
  echo "removing primers for $SAMPLE...."

  #remove first primer using cutadapt. 
  echo "remove first primer"
  cutadapt -g $FWD --discard-untrimmed -e $PRMERR -o ./2_trimmed/"$SAMPLE"-trimmed-5prime.fq ./1_merged/"$SAMPLE".extendedFrags.fastq
  #remove second primer using cutadapt.
  echo "remove second primer"
  cutadapt -a $REV --discard-untrimmed -e $PRMERR -o ./2_trimmed/"$SAMPLE"-fullytrimmed.fq ./2_trimmed/"$SAMPLE"-trimmed-5prime.fq
  echo "done removing primers for $SAMPLE."
done
