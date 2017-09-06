Unimorph LLODifier

The Universal Morphology (UniMorph) project is a collaborative effort to improve how NLP handles complex morphology in the world&#39;s languages. The goal of UniMorph is to annotate morphological data in a universal schema that allows an inflected word from any language to be defined by its lexical meaning, typically carried by the lemma, and by a rendering of its inflectional form in terms of a bundle of morphological features from our schema. (http://unimorph.org)

Here, we provide a LLOD converter for Unimorph data, together with its linking with Unimorph Annotation model.

Note that Unimorph provides dictionary data (comparable to FLex/Toolbox dictionaries) in a format comparable to CoNLL (tab-separated columns of WORD, LEMMA and FEATS). The output follows lemon/ontolex. However, as the data comes without sense information or metadata, the lemon specification will be underspecified and only provide LexicalEntry and LexicalForm information.

The converter builds on CoNLL-RDF (Chiarcos and Fäth 2017), it does, however, neither provide an up-to-date nor a complete version of CoNLL-RDF, but only the classes that are needed.

Note that because CoNLL-RDF is an intermediate format, non-resolvable feature abbreviations end up in conll:FEAT properties. This can be used for debugging the data and the Unimorph ontology. A Unimorph validator and the current list of Unimorph features are provided in validate-feats.sh, resp. data/feats.tsv.

We provide two converter scripts:
(1) unimorph2lemon.sh
	processes every line separately
	PRO: streamable: can be used to read and write data streams
	CON: creates more verbose TTL: for every line, prefixes and dictionary metadata are repeated
	
(2) unimorph2lemon-mono.sh
	reads a unimorph file, applies the transformations, writes
	PRO: non-redundant TTL
	CON: may not be able to process *very* large files, then we recommend unimorph2lemon.sh
	
In terms of runtime, both converters are comparable

cf. performance on sqi (Albanian) sample data (on a Surface Pro 2, 8GB RAM) 
unimorph2lemon.sh: 13m35,756s
unimorph2lemon.sh-mono.sh: 13m37,145s

But there is an immense difference in space:
unimorph2lemon.sh:   	940922 lines
unimorph2lemon-mono.sh: 449308 lines

We thus go with unimorph2lemon-mono.sh

References

Christian Chiarcos and Christian Fäth (2017), CoNLL-RDF: Linked Corpora Done in an NLP-Friendly Way, LNCS 10318 (Language, Data, and Knowledge, Proceedings of the International Conference on Language, Data and Knowledge LDK 2017), Galway, Ireland, June 2017, pp 74-88, https://rd.springer.com/chapter/10.1007%2F978-3-319-59888-8_6
