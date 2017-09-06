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
	sed s/'$'/'\n'/g | \
	bash run.sh CoNLLStreamExtractor $TGT\# \
		WORD LEMMA FEATS \
		-u	unimorph2lemon.sparql \
			linkFEATS.sparql{0} | \
	bash run.sh CoNLLRDFUpdater \
		-custom -model file:///C:/Users/chiarcos/Desktop/olia/owl/experimental/unimorph/unimorph.owl \
					   http://purl.org/olia/unimorph.owl \
		-updates linkFEATS.sparql;
done;

#-custom -model http://purl.org/olia/owl/experimental/unimorph/unimorph.owl \
		