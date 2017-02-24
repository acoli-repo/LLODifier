#!/bin/bash
# read Toolbox files as arguments, produce XML, convert XML to FLex-native LLOD and write to stdout
echo synopsis: $0 IGT_ANCHOR FILE1[..FILEn] 1>&2;
echo '  IGT_ANCHOR first marker per IGT, must be unique within an IGT' 1>&2
echo '  FILEi      Toolbox IGT files (normally *.tbt or *.txt)' 1>&2
echo 'Convert Toolbox files to FLex-style RDF' 1>&2

ANCHOR=`echo $1 | sed s/'[\\]'//g`;

for file in $*; do
	if [ -e $file ]; then
	
		# convert
		(echo '<tbxml src="'$file'">';
		 echo '<div>';
		 iconv -f utf-8 -t utf-8 $file | \
		 sed -e s/'\t'/'    '/g \
			-e s/'^\(.*\)'/'<line>\1<\/line>'/g \
			-e s/'>\\\([^ ]*\) '/' type="\1">'/ \
			-e s/'>\\\([^ ]*\)<'/' type="\1"><'/ \
			-e s/'<[^>]*type="'$ANCHOR'">'/'<\/div><div>&'/ \
			-e s/'\([> ]\)\([^ <>][^ <>]*\)\([ <]\)'/'\1<seg>\2<\/seg>\3'/g \
			-e s/'\(<\/seg> *\)\([^ <>][^ <>]*\)\( *<\)'/'\1<seg>\2<\/seg>\3'/g \
			-e s/'\(>\)\(  *\)\(<\)'/'\1<sep>\2<\/sep>\3'/g;
		 echo '</div>'
		 echo '</tbxml>') | \
		 xmllint --recover - |\
		 saxon -xsl:tbxml2flexllod.xsl -s:-
	fi;
done;
