#! /bin/bash

#zorg voor een refdb-file met Unix lijnscheiding
#Reduceer de file tot de essentiële velden (>naam, TAXID, species, genus, family, rank)
#Gebruik een taxdump.tar.gz die compatibel is met de referentiedatabank (niet het new_taxdump formaat)

python3 -m venv obi3-env
 . obi3-env/bin/activate
 
cd ~/run0004

#import

obi import ./run1_samples.fa run0004/run1_reads
obi import ./run2_samples.fa run0004/run2_reads
obi import ./run3_samples.fa run0004/run3_reads

#dereplication
obi uniq -m sample run0004/run1_reads run0004/run1_dereplicated
obi uniq -m sample run0004/run2_reads run0004/run2_dereplicated
obi uniq -m sample run0004/run3_reads run0004/run3_dereplicated

#clean metadata
obi annotate -k COUNT -k MERGED_sample run0004/run1_dereplicated run0004/run1_cleaned_metadata
obi annotate -k COUNT -k MERGED_sample run0004/run2_dereplicated run0004/run2_cleaned_metadata
obi annotate -k COUNT -k MERGED_sample run0004/run3_dereplicated run0004/run3_cleaned_metadata

#filter lengths
obi grep -p "len(sequence)>=80 and sequence['COUNT']>=80" run0004/run1_cleaned_metadata run0004/run1_denoised
obi grep -p "len(sequence)>=80 and sequence['COUNT']>=80" run0004/run2_cleaned_metadata run0004/run2_denoised
obi grep -p "len(sequence)>=80 and sequence['COUNT']>=80" run0004/run3_cleaned_metadata run0004/run3_denoised

#clean sequence variants
obi clean -s MERGED_sample -r 0.05 -H  run0004/run1_denoised run0004/run1_cleaned
obi clean -s MERGED_sample -r 0.05 -H  run0004/run2_denoised run0004/run2_cleaned
obi clean -s MERGED_sample -r 0.05 -H  run0004/run3_denoised run0004/run3_cleaned

obi export run0004/run1_cleaned -o run1_cleaned_sequences.fasta --fasta-output
obi export run0004/run2_cleaned -o run2_cleaned_sequences.fasta --fasta-output
obi export run0004/run3_cleaned -o run3_cleaned_sequences.fasta --fasta-output

#taxonomic assignment
obi ecotag -m 0.97 --taxonomy run0004/taxonomy/taxdump -R run0004/refdb run0004/run1_cleaned run0004/run1_assigned
obi ecotag -m 0.97 --taxonomy run0004/taxonomy/taxdump -R run0004/refdb run0004/run2_cleaned run0004/run2_assigned
obi ecotag -m 0.97 --taxonomy run0004/taxonomy/taxdump -R run0004/refdb run0004/run3_cleaned run0004/run3_assigned

#check results (optional)
obi stats -c SCIENTIFIC_NAME run0004/run1_assigned
obi stats -c SCIENTIFIC_NAME run0004/run2_assigned
obi stats -c SCIENTIFIC_NAME run0004/run3_assigned

#align results (optional? geen idee wat hier precies gebeurt)
obi align -t 0.95 run0004/run1_assigned run0004/run1_aligned
obi align -t 0.95 run0004/run2_assigned run0004/run2_aligned
obi align -t 0.95 run0004/run3_assigned run0004/run3_aligned

#exporteer results
obi export --tab-output run0004/run1_assigned -o run1_assigned.csv
obi export --tab-output run0004/run2_assigned -o run2_assigned.csv
obi export --tab-output run0004/run3_assigned -o run3_assigned.csv

obi history -d run0004 > run0004.dot #win11: hierna dot -Tx11 run0004.dot
dot -Tpng run0004.dot -o run0004.png

cp *.csv /mnt/c/_GIT_PROJECTS/prj_edna_miseq/run_0004/verwerking2023/
cp *.png /mnt/c/_GIT_PROJECTS/prj_edna_miseq/run_0004/verwerking2023/
cp *.fasta /mnt/c/_GIT_PROJECTS/prj_edna_miseq/run_0004/verwerking2023/







