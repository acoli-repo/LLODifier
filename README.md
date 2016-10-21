# LLODifier

A collection of tools for converting language resources into LLOD

## Idea

Unlike many existing frameworks, we do not attempt to map different formats into a unified RDF representation. Instead, we only perform a shallow conversion: an isomorphic RDF representation of the original data structures is created. Further processing, e.g., by means of SPARQL UPDATE queries, may then be used to transform these into more generic RDF representations.

The second aspect is that our converters are meant to produce *Linked* Open Data, i.e., the converted resources should contain references to other resources in the Linguistic Linked Open Data (LLOD) cloud.