#!/bin/bash

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
  flash ./0_adapters_removed/"$SAMPLE"_F.fq ./0_adapters_removed/"$SAMPLE"_R.fq -m $FLASHMIN -M $N -o ./1_merged/"$SAMPLE"
  echo "done merging reads for $SAMPLE."
done

