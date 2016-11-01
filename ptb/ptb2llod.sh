#!/bin/bash
# reads PTB-style file(s) from stdin
# synopsis: ptb2llod.sh baseURI
# we perform the conversion with xslt, but in order to do so, we first convert the lisp-style format into XML markup
# the converter relies on two assumptions:
# (1) all round parentheses occurring in the text (rather than in the annotation) have been escaped
# (2) node labels do not contain "
if echo $1 | grep '.' 1>/dev/null; then 
	(echo '<ptbxml>';
	if iconv -f utf-8 -t utf-8 ; then
		echo encoding check '(utf-8)' ok 1>&2;
	else echo encoding check '(utf-8)' failed 1>&2;
	fi | \
	sed -e s/'[ \t]*('/'<node>'/g \
		-e s/')[ \t]*'/'<\/node>'/g \
		-e s/'<node>\([^ <][^ <]*\)[ \t]*'/'<node tag="\1">'/g;
	echo '</ptbxml>' )  | \
	#tee $0.raw.xml | \
	if xmllint --recover -format -; then
		echo XML validity check '(xmllint)' ok 1>&2;
	else echo XML validity check '(xmllint)' failed, trying to recover 1>&2;
	fi | \
	#tee $0.valid.xml |\
	xsltproc  --stringparam baseURI $1 ptbxml2llod.xsl -;
else
	echo synopsis: $0 baseURI 1>&2;
	echo '  'read PTB-style syntax annotation '(mrg)' from stdin 1>&2;
	echo '  'convert to XML and apply ptbxml2llod.xsl 1>&2;
	echo '  'write ttl to stdout 1>&2;
	echo '  'make sure to provide a baseURI as argument 1>&2;
fi;