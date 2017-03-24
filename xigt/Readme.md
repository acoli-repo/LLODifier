Xigt (eXtensible Interlinear Glossed Text)
==========================================

XML-based format and infrastructure for representing Interlinear Glossed Text (IGT).
Xigt was originally developed by the ODIN project (http://linguistics-ontology.org/project/4), an effort aiming at mining IGT data from scientific publications (i.e., PDF).
However, it has been extended 

https://github.com/xigt/xigt, https://github.com/xigt/xigt/wiki, http://depts.washington.edu/uwcl/xigt, http://depts.washington.edu/uwcl/xigt-edit/

Converting annotations
----
(See below for metadata.)

Goal is a direct, shallow conversion to RDF. 
The Relax NG schema is extensible: additional attributes can be defined and additional constraints on types or metadata can be defined as needed, etc.
See xigt-rnc.png, resp. xigt-rnc.dia for core data structures.

![Xigt data model, from RNC scheme][https://raw.githubusercontent.com/acoli-repo/LLODifier/master/xigt/xigt-rnc.png xigt-rnc.png]

In general, ID attributes (@id) should become URIs in the document namespace, IDREF (e.g., @alignment) Object Properties, other attributes Datatype Properties, nested elements should be represented by Datatype Properties, their name being defined by @type attributes.
In the example data and default-xigt.rnc, tier/@type is a plural forms (this is a convention). As these do not easily translate into Object Property names, aggregator elements for which plural names occur are represented as RDF collections.

* **Item.type**: "affix", "clitic", "leipzig", "lexeme", "original", "transliteration"
* **Meta.type**: "author", "comment", "data-provenance", "date", "extended-data", "judgment", "language", "phenomena", "source", "vetted"
* **Metadata.type**: "intent-meta", "xigt-meta"
* **Tier.type**: "bilingual-alignments", "dependencies", "glosses", "morphemes", "odin", "phrases", "phrase-structure", "pos", "syntax", "translations", "words"

This has the disadvantage that the Xigt RDF schema will not be compliant with OWL (nor with other LLODifier schemes), it has the advantage that we do not require explicit properties for representing sequences, but instead can rely on RDF-inherent (implicit) properties for accessing list data structures.

Xigt employs a proprietary scheme to refer to substrings. In RDF, this could be represented using NIF String URIs at a later point in time. For the moment, we keep the original references along with segment alignment information.

Unlike FLex, Xigt doesn't predefine its units of segmentation, this is subject to schema extensions and represented only in the @type attribute. Hence much more generic, but also much harder to parse because character offsets need to be converted.

As a general convention, the xml following-sibling axis is modeled by xigt:next (not transitive), the child relation of any content element X as xigt:has_X.

Corpus data (xigt-corpus, igt, tier)
---

	1	<xigt-corpus>
	2	  <igt id="i1">
	3		<tier type="phrases" id="p">
	4		  <item id="p1">at͡ʂʰkʷʰən atəpha dəjəbajt</item>
	5		</tier>
	6		<tier type="words" id="w" segmentation="p">
	7		  <item id="w1" segmentation="p1[0:10]"/>
	8		  <item id="w2" segmentation="p1[11:17]"/>
	9		  <item id="w3" segmentation="p1[18:26]"/>
	10		</tier>
	ff.		...

This corpus doesn't have an id, but the document should have a (user-provided) URI. 
Without @id, use the base uri as corpus URI.
We use the base URI https://github.com/xigt/xigt/examples/abkhaz/abkhaz.xml

We thus arrive at the following

	PREFIX doc: <https://github.com/xigt/xigt/examples/abkhaz/abkhaz.xml#>				# baseURI
	<https://github.com/xigt/xigt/examples/abkhaz/abkhaz.xml> a xigt:xigt-corpus.		# 1, with base URI instead of id-defined URI in the doc namespace
	<https://github.com/xigt/xigt/examples/abkhaz/abkhaz.xml> xigt:has_igt doc:i1.		# 2, igt URI from the @id attribute, with property has_{name()}
	doc:i1 a xigt:igt.																	# 2, element name
	doc:i1 xigt:has_phrases doc:p.														# 3, has_{name()} doc:{@id}
	doc:p a xigt:tier.																	# 3, this can be omitted if xigt:has_tier is given rdfs:range xigt:tier.
	xigt:has_phrases rdfs:subPropertyOf xigt:has_tier.									# 3, for every tier/@type

	doc:p xigt:has_item doc:p1.															# 4
	doc:p1 xigt:text "at͡ʂʰkʷʰən atəpha dəjəbajt".										# 4, novel property xigt:text

As we refer to the strings later, we need explicit URIs, no list structures, thus. 
We thus have to use an explicit xigt:next property instead of list data structures. (TBC: Can we rely on the sequence in Xigt?)
(TODO: update description above.)
The xigt:text property corresponds to the text data type in the RelaxNG schema.

	doc:i1 xigt:has_words doc:w.
	xigt:has_words rdfs:subPropertyOf xigt:has_tier.
	doc:w xigt:segmentation doc:p.														# 6: segmentation is an idref, hence an object property, but see below.
	doc:w xigt:has_item doc:w1, doc:w2, doc:w3.											# 6-9

Treatment of subsegmented strings is problematic. As this is always item/@segmentation, and this refers to character offsets, I just define them as nif:subString and keep segmentation as a datatype property. Note that tier/@segmentation is actually redundant and thus omitted. Accordingly, xigt:segmentation is always a datatype property.

	doc:w1 nif:subString doc:p1; xigt:segmentation "p1[0:10]"; xigt:next doc:w2.		# 7, xigt:segmentation is later treated using a simple SPARQL Update script
	doc:w2 nif:subString doc:p1; xigt:segmentation "p1[11:17]"; xigt:next doc:w3.		# 8
	doc:w3 nif:subString doc:p1; xigt:segmentation "p1[18:26]".							# 9

nif:subString is not ideal because xigt items do not have to be strings, but can also be (zero!) morphology. 
xigt:segmentation is always a datatype property, as it is redundant with nif:subString otherwise.

Other layers accordingly:

	...
	11    <tier type="morphemes" id="m" segmentation="w">
	12      <item id="m1.1" segmentation="w1[0:1]"/>
	13      <item id="m1.2" segmentation="w1[1:10]"/>
	14      <item id="m2.1" segmentation="w2[0:1]"/>
	15      <item id="m2.2" segmentation="w2[1:6]"/>
	16      <item id="m3.1" segmentation="w3[0:2]"/>
	17      <item id="m3.2" segmentation="w3[2:4]"/>
	18      <item id="m3.3" segmentation="w3[4:6]"/>
	19      <item id="m3.4" segmentation="w3[6:8]"/>
	20    </tier>
	...

Another alignment operation is mere reference, marked by @alignment

	...
	21    <tier type="glosses" id="g" alignment="m">
	22      <item id="g1.1" alignment="m1.1">the</item>
	23      <item id="g1.2" alignment="m1.2">boy</item>
	24      <item id="g2.1" alignment="m2.1">the</item>
	25      <item id="g2.2" alignment="m2.2">girl</item>
	26      <item id="g3.1" alignment="m3.1">her</item>
	27      <item id="g3.2" alignment="m3.2">he</item>
	28      <item id="g3.3" alignment="m3.3">see</item>
	29      <item id="g3.4.1" alignment="m3.4">DYN</item>
	30      <item id="g3.4.2" alignment="m3.4">FIN</item>
	31    </tier>
	32  </igt>
	ff.  ...

	doc:i1 xigt:has_glosses doc:g.														# 21, alignment is dropped, because alignment ids are assumed to be unambiguous
	doc:g xigt:has_item doc:g1.1, doc:g1.2, doc:g2.1, doc:g2.2, doc:g3.1, doc:g3.2, doc:g3.3, doc:g3.4.1, doc:g3.4.2.

The example shows that order is not necessarily respected. However, we interpret these as fused morphemes, cf. the use of . in the Leipzig Glossing Rules.

	doc:g1.1 xigt:alignment doc:m1.1; xigt:text "the"; xigt:next doc:g1.2.			# 22
	doc:g1.2 xigt:alignment doc:m1.2; xigt:text "boy"; xigt:next doc:g2.1.			# 23
	doc:g2.1 xigt:alignment doc:m2.2; xigt:text "the"; xigt:next doc:g2.2.			# 24
	doc:g2.2 xigt:alignment doc:m3.2; xigt:text "girl"; xigt:next doc:g3.1.		# 25
	doc:g3.1 xigt:alignment doc:m3.1; xigt:text "her"; xigt:next doc:g3.2.			# 26
	doc:g3.2 xigt:alignment doc:m3.2; xigt:text "he"; xigt:next doc:g3.3.			# 27
	doc:g3.3 xigt:alignment doc:m3.3; xigt:text "see"; xigt:next doc:g3.4.1.		# 28
	doc:g3.4.1 xigt:alignment doc:m3.4; xigt:text "DYN"; xigt:next doc:g3.4.2.		# 29 (we assume this is an ordered sequence of annotations for a fused morpheme
	doc:g3.4.2 xigt:alignment doc:m3.4; xigt:text "FIN".							# 30

This modeling is not very efficient, more practical would be a property-based model as in FLex RDF. The problem is that the type of annotation is hidden in the tier/@type attribute and normally uses a plural form.

Along with @alignment, we also find @segmentation (implemented by nif:subString plus a datatype property representing the original @segmentation value) and @content (like @segmentation, but referring to values of annotation rather than the annotated unit, implemented by rdfs:label [with label information recovered] plus a datatype property representing the original @content value). The exact alignment information is dropped. For a potential Xigt export, it can be approximated by equally distributing xigt:next-connected sequences of nif:subString values along the underlying string.

Alignment expressions are resolved for @content, only, cf. https://github.com/xigt/xigt/wiki/Alignment-Expressions for their original definition.

NOTICE on tier: In the Abkhaz example, tier/@id is unique per IGT only, not within document (seems just to define a shorthand for @type), therefore preserve @id as a datatype property and create a positional URI for tiers

NOTICE on @id: In fact, *NO* @id seems to be unique, cf. item/@id in Abkhaz. Hence globally disabled @id-based URI generation. We keep @id-based URIs for metadata, though. Note that this means that @idref resolution needs to be revised. Let's assume @ids are unique within a IGT.

Corpus metadata
---

* metadata is an aggregator element for metadata properties, not necessary in RDF, all metadata properties are just defined as subproperties of xigt:metadata
* metadata/meta refers to multiple layers and combines multiple additional attributes (i.e., requires reification), also modelled as a Collection, i.e. 

		xigt:{@type} rdfs:subPropertyOf xigt:metadata.
		doc:xigt_corpus_1 xigt:{@type} [ ... ].

(I use doc: for the document namespace.)
		
e.g., samples/Abkhaz.xml

	1	<xigt-corpus>
	2		<metadata>
	3			<meta type="language" name="Abkhaz" iso-639-3="abk" tiers="phrases words morphemes"/>
	4			<meta type="language" name="English" iso-639-3="eng" tiers="glosses translations"/>
	5			<meta type="date">May 1 2009</meta>
	6			<meta type="author">Safiyyah Saleem</meta>
	7			<meta type="source" id="src-a">Abkhaz by Viacheslav A. Chirkba</meta>
	8			<meta type="source" id="src-b">Safiyyah Saleem</meta>
	9		</metadata>
	ff.		...
		
becomes

		doc:corp1 a xigt:xigt-corpus.																					# 1
		
		doc:corp1 xigt:language [ xigt:name "Abkhaz"; xigt:iso-639-3 "abk"; xigt:tiers "phrases words morphemes" ].	# 3
		xigt:language rdfs:subPropertyOf xigt:metadata.																# 2(+3)
		
		doc:corp1 xigt:language [ xigt:name "English"; xigt:iso-639-3 "eng"; xigt:tiers "glosses translations" ].	# 4
		xigt:language rdfs:subPropertyOf xigt:metadata.																# 2(+4)
		
As meta can contain other (undefined) elements, these can be captured in RDF as either literal XML or serialized into a String literal.

As lines 7 and 8 show, it is still necessary to use a reified representation, because additional attributes could be added. 

As for the property representing the actual content, I suggest xigt:meta (following the original element name).

Hence, we have
	
		doc:corp1 xigt:date [ xigt:meta "May 1 2009" ].																# 5
		xigt:date rdfs:subPropertyOf xigt:metadata.																	# 2(+5)
		
		doc:corp1 xigt:author [ xigt:meta "Safiyyah Saleem" ].														# 6
		xigt:author rdfs:subPropertyOf xigt:metadata.																# 2(+6)

The @id attribute is special insofar as it provides a name (=> a URI) for the reified element.
	
		doc:corp1 xigt:source doc:src-a.																			# 7
		doc:src-a xigt:meta "Abkhaz by Viacheslav A. Chirkba".															# 7
		xigt:source rdfs:subPropertyOf xigt:metadata.																# 2(+7)
		
		doc:corp1 xigt:source doc:src-b.																			# 8
		doc:src-b xigt:meta "Safiyyah Saleem".																			# 8
		# no need to repeat 2(+7) triple
		
Note that these explicit triples are equivalent with the list notation above, as the list is internally represented by a blank node.

Hence
		
		doc:corp1 xigt:author [ xigt:meta "Safiyyah Saleem " ].														# 6
		
is equivalent with
	
		doc:corp1 xigt:author _:some_internal_id.																	# 6
		_:some_internal_id xigt:meta "Safiyyah Saleem".																	# 6

Should @type ever be missing, use xigt:metadata.

Update: The value of xigt:meta is an rdf:XMLLiteral, not just a plain string. This has been added to support nested XML content as in kor-ex-olac.xml.

Detecting Object properties
---
Beyond the core RelaxNG scheme, additional attributes are possible and are being used. It is not a priori clear, however, whether they represent object properties (references) or datatype properties (values). This is heuristically guessed *from the data*: If all ([, ]-separated) values of an XML attribute (regardless of parent) are defined by some @id attribute, the attribute must be an object property, otherwise, it's a datatype property.

RDFS datatype inference
---

For bootstrapping relations between classes and properties from the converted data, it is useful to assign blank nodes a class. 
In particular, objects of (subproperties of) xigt:metadata and subjects of xigt:meta. To avoid confusion with metadata, we define that

	xigt:metadata rdfs:range xigt:Metadata.
	
The @type attribute (outside metadata, cf. above) represents information akin to rdf:type ("a").
Therefore, implementation has been revised to represent (non-metadata) types as classes.
However, as the @type values may be underspecified and potentially applicable to tiers and items (say, "POS"), the newly created class is a composite together with the element name

	xigt:{@type}_{name()}

The original @type value is stored as label of this newly created class, e.g.,

	<item ... type="null" ...>    => xigt:null_item    rdfs:subClassOf xigt:item; rdfs:label "null". 
	<tier ... type="phrases" ...> => xigt:phrases_tier rdfs:subClassOf xigt:tier; rdfs:label "phrases".

These specialized types are then used in place of xigt:tier, xigt:item, etc., whenever a @type is defined.

RDF(S) data model
---

RDF(S) data model can be basically read off the converted sample data:

	PREFIX xigt: <https://github.com/xigt/xigt/wiki/Data-Model#>
	SELECT DISTINCT ?aC ?rel ?bC ?aSuper
	WHERE {
	  { ?aC rdfs:subClassOf ?aSuper } UNION 
	  { ?a ?rel ?b.
		?a a ?aC. FILTER(?b!=?aC)
		OPTIONAL { ?b a ?bC }
		OPTIONAL { ?b ?otherrel []. BIND(xigt:Metadata AS ?bC)
				 FILTER(NOT EXISTS{ ?b a ?bC})} 
	  } UNION 
	  { ?a ?rel ?b.
		FILTER(NOT EXISTS{ ?a a [] })
		OPTIONAL { ?b a ?bC }
		BIND(xigt:Metadata AS ?aC) }
		
	} ORDER BY ?aC ?rel

Slightly summarized in the figure below.

![RDF(S) data model for kor-ex.xml, kor-ex-olac.xml, abkhaz.xml][https://raw.githubusercontent.com/acoli-repo/LLODifier/master/xigt/xigt-rdfs.png xigt-rdfs.png]

Open issues
---

* implement the following fixes using SPARQL Update ?

* resolve offsets? (we don't actually need them, but we cannot easily regenerate them, because we don't know which tiers contain the literal forms)
 * for Xigt export, we can just generate them positionally, this isn't beautiful, but should work

* Xigt properties translated to singular forms using an online morphology ?
(We can also hard-wire some simple rules in SPARQL.)

Serialization as Xigt
---

keep singular forms for tiers (this is not fully consistent anyway).