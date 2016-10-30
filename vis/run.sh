#!/bin/bash
# args java class and its args
TGT=`echo $1 | sed s/'\.java$'//;`

# config
HOME=`echo $0 | sed s/'\/[^\/]*$'/'\/'/`./;
JAVA=java
JAVAC=javac
PATHSEP=':'

CLASSPATH=$HOME$PATHSEP`find $HOME/../lib | grep 'jar$' | perl -pe 's/\n/\t/g;' | sed -e s/'\t$'// -e s/'\t'/$PATHSEP/g;`
if echo $OSTYPE | grep -i cygwin >/dev/null; then 
	PATHSEP=';';
	CLASSPATH=`for jar in $(echo $CLASSPATH | sed s/':'/' '/g); do cygpath -wa $jar; done | perl -pe 's/\n/\t/g;' | sed -e s/'\t$'// -e s/'\t'/$PATHSEP/g;`
fi;

# compile
STATUS=ok;
if [ -e $TGT.class ]; then
	if [ $TGT.java -nt $TGT.class ]; then
		rm $TGT.class;
	fi;
fi;

if [ ! -e $TGT.class ]; then
	if javac -cp $CLASSPATH $TGT.java; then echo updated $TGT; else STATUS=nok; fi;
fi;

# run
if [ $STATUS=ok ]; then
	java -cp $CLASSPATH $*;
fi;