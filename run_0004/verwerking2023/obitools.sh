#!/bin/bash
cd ~
. obi3-env/bin/activate
cd run004/run1

#import in obitools

#obi import --taxdump ~/new_taxdump.tar.gz run0004/taxonomy/taxdump
#obi import --taxdump ~/taxdump.tar.gz run0004/taxonomy/taxdump
#dos2unix refdb.fasta
#obi import ~/refdb.fasta run0004/refdb_import
#obi build_ref_db -t 0.97 --taxonomy run0004/taxonomy/taxdump run0004/refdb_import run0004/refdb

obi import ./4_obi_input/all_samples.fa run0004/reads #saves under run0004.obidms


#dereplication
obi uniq -m sample run0004/reads run0004/reads_dereplicated

#clean metadata
obi annotate -k COUNT -k MERGED_sample run0004/reads_dereplicated run0004/reads_cleaned_metadata

#filter lengths
obi grep -p "len(sequence)>=80 and sequence['COUNT']>=80" run0004/reads_cleaned_metadata run0004/reads_denoised

#clean sequence variants
obi clean -s MERGED_sample -r 0.05 -H  run0004/reads_denoised run0004/reads_cleaned
obi export run0004/reads_cleaned -o cleaned_sequences.fasta --fasta-output

#taxonomic assignment
obi ecotag -m 0.97 --taxonomy run0004/taxonomy/taxdump -R run0004/refdb run0004/reads_cleaned run0004/reads_assigned

#check results
obi stats -c SCIENTIFIC_NAME run0004/reads_assigned

#align results
obi align -t 0.95 run0004/reads_assigned run0004/reads_aligned

#export results
obi export --fasta-output run0004/reads_aligned -o results_aligned.fasta
obi export --tab-output run0004/reads_aligned -o results_aligned.csv
obi export --tab-output run0004/reads_assigned -o results_assigned.csv
obi history run0004
obi history -d run0004 > run0004.dot
obi history -d run0004/reads_cleaned > reads_one_view.dot

dot -Tx11 run0004.dot
dot -Tpng run0004.dot -o run0004.png
open wolf.png &
cp run0004.png /mnt/c/_GIT_PROJECTS/prj_edna_miseq/
cp results_aligned.csv /mnt/c/_GIT_PROJECTS/prj_edna_miseq/
cp results_assigned.csv /mnt/c/_GIT_PROJECTS/prj_edna_miseq/
