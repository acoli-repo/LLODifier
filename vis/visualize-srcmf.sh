#!/bin/bash
# aux script for rendering the SRCMF example
# filters out a lot of irrelevant information to create a human-readable graph
# nevertheless, the graph remains highly redundant
# KNOWN BUGS: rendering of "fake" nodes, e.g. http://www.srcmf.org/annotations/strasbBfm#sophie/cp_strasbBfm_1439909865.47_fake
./run.sh NIF2dot ../tiger/strasbBfm_final.ttl  \
	-skip http://www.ims.uni-stuttgart.de/forschung/ressourcen/korpora/TIGERCorpus/public/TigerXML.xsd#editionUri \
		  http://www.ims.uni-stuttgart.de/forschung/ressourcen/korpora/TIGERCorpus/public/TigerXML.xsd#editionId \
		  http://www.ims.uni-stuttgart.de/forschung/ressourcen/korpora/TIGERCorpus/public/TigerXML.xsd#annotationFile \
		  http://www.ims.uni-stuttgart.de/forschung/ressourcen/korpora/TIGERCorpus/public/TigerXML.xsd#annotationUri \
		  http://www.ims.uni-stuttgart.de/forschung/ressourcen/korpora/TIGERCorpus/public/TigerXML.xsd#editionNs \
 | dot -Tgif > strasbBfm_final.gif
