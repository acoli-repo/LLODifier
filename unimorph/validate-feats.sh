#!/bin/bash
# this is a helper routine that uses the unimorph LLODification to validate the Unimorph ontology (resp., its features)
bash ./unimorph2lemon.sh data/feats.tsv | egrep -A 1 'FEAT|writtenRep' | grep -v writtenRep | \
egrep -A 1 'FEAT' | grep -v '\-\-' | sed s/'.*FEAT'//g | perl -pe 's/\r//g; s/;\n/\t/gs;' | \
sed s/' *\t[\t ]*'/'\t'/g  > missing-feats.txt