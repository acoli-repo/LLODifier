#!/bin/bash
for file in `grep -l ag:Anchor ../*/*/*.ttl ../*/*.ttl`; do 
	echo AG2dot $file 1>&2;
	./run.sh AG2dot $file | \
	tee `echo $file | sed -e s/'.*\/'//g -e s/'ttl$'/'dot'/` | \
	dot -Tgif > `echo $file | sed -e s/'.*\/'//g -e s/'ttl$'/'gif'/`;
done

for file in `grep -l nif:Word ../*/*/*.ttl ../*/*.ttl`; do 
	echo NIFdot $file 1>&2;
	./run.sh NIF2dot $file | \
	tee `echo $file | sed -e s/'.*\/'//g -e s/'ttl$'/'dot'/` | \
	dot -Tgif > `echo $file | sed -e s/'.*\/'//g -e s/'ttl$'/'gif'/`;
done

echo render srcmf 1>&2;
./visualize-srcmf.sh