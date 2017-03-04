
# ODIN 2.0

ODIN, the Online Database of INterlinear glossed text, is a collection of
IGT extracted from linguistic documents on the web.

This release encodes the data into the
[Xigt](http://depts.washington.edu/uwcl/xigt/)
format, which provides several benefits:

  * XML data format is more explicit than plain text, so it's more
    interpretable
  * Xigt data model is extensible, so additional layers of annotation can
    be provided on top of the existing data
  * The Xigt project provides tools for querying and processing the data,
    as well as an API for working with the data programmatically

In addition, this release improves the original ODIN text data in some ways:

  * The original sentences have been cleaned and noise/errors from the
    PDF extraction process have been reduced
  * Basic alignments between the language, gloss, and translation lines
    have been created where possible

## Using ODIN data

The ODIN data is released under an open license (please see LICENSE.txt
for details), requiring only attribution. Users may fulfill the attribution
requirement by linking to the ODIN website, and/or by citing the ODIN
publications.

When using individual IGT, such as in a linguistic paper, it is good practice
to also cite the original source. Each IGT in ODIN has a `doc-id` metadatum,
which is an identifier for the document the IGT was extracted from. This
identifier can be looked up in the `citations.txt` file to find information
about this document, such as the title, year, and author.

## Corpus Contents

This release of ODIN contains three "views" of the data:

  * `full`: all ODIN data in one XML file
  * `by-lang`: an XML file for each language (by ISO-639-3 code)
  * `by-doc-id`: an XML file for the IGT from each source document

Each of these views reside in an eponymous directory along with two files
providing information about the contents:

  * `summary.txt`: an overview of the number of items, languages, etc. in
    each XML file
  * `languages.txt`: a listing of the languages (with their ISO codes) found
    in each XML file

In addition to the Xigt-formatted XML corpora, we also include the original
text form of the data, split by language (`txt-by-lang`) or document
identifier (`txt-by-doc-id`)

## Xigt format

The [Xigt project](http://depts.washington.edu/uwcl/xigt/) has documenation
about the structure of the XML, but we provide a brief explanation here.

The data contains only four levels of nesting: the root element,
`<xigt-corpus>`, contains a list of `<igt>` elements, which contain `<tier>`
elements, which in turn contain `<item>` elements. The actual IGT data is
expressed in the `<item>` elements, and `<tier>` elements group `<item>`
elements of the same type (e.g. all glosses). In addition, `<metadata>`
elements may appear at the `<xigt-corpus>`, `<igt>`, or `<tier>` levels,
before the other kinds of child elements.
