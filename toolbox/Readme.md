Toolbox LLODifier
=================

Field Linguist’s Toolbox. Data management, parsing and text analysis
--------------------------------------------------------------------

Toolbox is a data management and analysis tool for field linguists. It is especially useful for maintaining lexical data, and for parsing and interlinearizing text, but it can be used to manage virtually any kind of data.

Field Linguist's Toolbox is actively supported. Some places on the SIL website appear to say that it is unsupported or discontinued. But that only means that no SIL international people are involved in supporting Toolbox. Toolbox support is provided by people from an SIL field entity. 

(http://www-01.sil.org/computing/toolbox)

Information for those considering using the Field Linguist’s Toolbox computer program
-------------------------------------------------------------------------------------

Field Linguist's Toolbox is actively supported. Some places on the SIL website appear to say that it is unsupported or discontinued. But that only means that no SIL international people are involved in supporting Toolbox. Toolbox support is provided by people from an SIL field entity. You can always get help by writing to Toolbox @ sil.org.

Toolbox is a data management and analysis tool for field linguists. It is especially useful for maintaining lexical data, and for parsing and interlinearizing text, but it can be used to manage virtually any kind of data.

Toolbox is a text-oriented database management system with added functionality designed to meet the needs of a field linguist. The underlying dbms offers full user flexibililty in the design of any type of database. But for ease of use, the Toolbox package includes prepared database definitions for a typical dictionary and text corpus.

The Toolbox database management system offers powerful functionality like customized sorting, multiple views of the same database, browse view to show data in tabular form, and filtering to show subsets of a database. It can handle any number of scripts in the same database. Each script has its own font and sorting characteristics. While Unicode is preferred, Toolbox can handle scripts in most legacy encoding systems.

Toolbox also has powerful linguistic functionality. It includes a morphological parser that can handle almost all types of morphophonemic processes. It has a word formula component that allows the linguist to describe all the possible affix patterns that occur in words. It has a user-definable interlinear text generation system which uses the morphological parser and lexicon to generate annotated text. Interlinear text can be exported in a form suitable for use in linguistic papers. Toolbox has export capabilities that can be used to produce a publishable dictionary from a dictionary database.

Although Toolbox is very powerful, it is designed to be easy to learn. The user can start with a simple standard setup and gradually add the use of more powerful features as desired. The Toolbox downloads include a training package that is usable for self-paced individual learning as well as for classroom teaching of Toolbox.

Toolbox is freeware. There is no charge for any of its components. It may be freely distributed.

http://www-01.sil.org/computing/toolbox/information.htm

Toolbox converter
-----------------

Builds on FLex LLODifier data types. Developed for the sample IGT data, not for Toolbox in its entirety.

Data
----

Axiska/Meskhet sample, provided by Irina Nevskaya and Monika Rind-Pawlowski, Goethe University Frankfurt

file structure:
Toolbox layers ("markers") can be freely defined. We do thus not know what is a marker and what is a 

Axiska sample:
1 \_sh	text meta data

5 \ft	recurring elements (i.e., IGT markers)
5 \ge
5 \id
5 \ltr
5 \mb
5 \nt
5 \per
5 \ps
5 \ref
5 \tx

no straight-forward interpretation in terms of FLex.

simplification:
- no paragraphs
- list IGT markers as arguments, as soon as this order is violated, we know we're in a new flex:Phrase

conversion:
trivial XML conversion, logic in XSLT