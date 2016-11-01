Penn Treebank format

sample
	wsj_1640.parse
		sample file taken from OntoNotes v. 5.0 (https://catalog.ldc.upenn.edu/LDC2013T19)
		note that the original text is also distributed as part of the MPQA corpus
		(http://mpqa.cs.pitt.edu/corpora/mpqa_corpus/) for research and/or academic purposes
		under the terms of the latter, we include the source text of the sample file in the distribution
		
Note that we do not parse compounds of bracket labels, function tags and cross-references, as these reqire corpus-specific processing.
Also note that empty PTB elements are treated like regular tokens (i.e., become nif:String!).