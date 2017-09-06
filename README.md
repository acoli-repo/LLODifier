# LLODifier

A collection of tools for converting language resources into LLOD

## Corpora

Unlike many existing frameworks, we do not attempt to map different formats into a unified RDF representation. Instead, we only perform a shallow conversion: an isomorphic RDF representation of the original data structures is created. Further processing, e.g., by means of SPARQL UPDATE queries, may then be used to transform these into more generic RDF representations.

The second aspect is that our converters are meant to produce *Linked* Open Data, i.e., the converted resources should contain references to other resources in the Linguistic Linked Open Data (LLOD) cloud.

We distinguish two major types of corpus formalisms

1. anchor-based (timeline-based): annotations and/or transcriptions obligatory refers to anchors in one or multiple timelines, e.g., representing an audio stream. The naive modeling has been replaced by a model using Annotation Graphs (following Schmidt et al. 2009) as requires by the visualization routines (in vis/)
2. word-based (token-based): annotations are grounded on minimal units (character sequences) ordered along an axis. We adopt the NLP Interchange Format (nif) for basic datatypes, but note that it is not sufficiently generic. In particular, it defines Words (its basic unit) as a subclass of String. Also note that we do not adopt the NIF URI scheme.

A third group are interlinear glosses (e.g., flex) as produced in language documentation and linguistic typology. Traditionally, FLEx (and its predecessors Toolbox and Shoebox) export to anchor-based formats (e.g., ELAN), as they may include multimedia content, but mapping to a word-based model is also possible. We provide two approximative renderings based on NIF, but there are massive conceptual mismatches that render this a heuristic approximation, at best (we map FLEx morphs or terminal words to NIF words, FLEx phrases to NIF sentences, FLEx non-terminal words to NIF phrases). NIF rendering is recommended to be used for visualization only, otherwise, stay with the naive model.

Finally, we provide an RDF representation of the original XML data model, applicable for converting TEI data.

Future work will aim at providing a generalization over these different data models, to be implemented with SPARQL Update.

Directory vis/ contains visualization routines with sample output (restricted to the first few ag:anchors, resp. the first nif:Sentence).

## Other data

Toolbox and FLEx also contain lexical data. This is to be represented in accordance with lemon/ontolex. This is also true for other types of language resources, e.g., morpheme inventories. As an example for these, we provide a converter for UniMorph data. Note that the UniMorph format basically corresponds to the one-word-per-line format also adopted for lemmatized/POS-tagged corpora (the CoNLL format family) and the corresponding tools (e.g., TreeTagger), they are thus treated analoguously to corpus data.