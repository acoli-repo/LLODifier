#!/bin/bash
echo $0': reads unimorph file(s) from arg, write lemon to stdout' 1>&2

HOME=`echo $0 | sed s/'[^\/]*$'//g`./;
if echo $ostype | grep 'cygwin' >/dev/null; then
	cd $HOME;
	cygpath -wa .;
	cd - >/dev/null;
else
	cd $HOME;
	pwd;
	cd - >/dev/null;
fi;

for file in $*; do
	TGT=https://github.com/unimorph/`echo $file | sed s/'.*\/'//g;`
	echo $file " => " $TGT 1>&2;
	iconv -f utf-8 -t utf-8 $file | \
	bash run.sh CoNLLStreamExtractor $TGT\# \
		WORD LEMMA FEATS \
		-u	unimorph2lemon.sparql \
			link-and-load-FEATS.sparql;
done;

#-custom -model http://purl.org/olia/owl/experimental/unimorph/unimorph.owl \
		