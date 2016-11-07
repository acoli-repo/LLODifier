TEI Corpus LLODifier
====================

Note that we don't support full TEI P5, but only to the extent as used it the samples.
However, the converter is designed to support *any* inline XML format. 

We try to convert all IDREFs into URI references, but detect them only heuristically (containing #).
Note that the generated pseudo URIs might require postprocessing.

samples:
	MULTEXT-EAST annotated corpus (https://www.clarin.si/repository/xmlui/handle/11356/1043, http://nl.ijs.si/ME/V4/)