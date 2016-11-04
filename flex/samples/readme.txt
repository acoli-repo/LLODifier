samples from
	http://fieldworks.sil.org/download/fw-828/
	kept only those with ITGs
	
the original *.fwbackup files are zip archives, preserved in orig/
the relevant data files are *.fwdata files from these archives
for better processing under Cygwin, the *.fwdata files have been renamed: _ replaces whitespaces

The internal format is quite a mess, with basically unresolvable cross-references.
On the one hand, this may be because the XML format is basically a wrapper around some database representation, preserving the original (but not human-readable) database structure, but obfuscating the conceptual structure of the data.
On the other hand, this is also because numerous different types of information are lumped into a single format (but we're interested in ITGs, only, here).
The entire enterprise is complicated by the lack of a consistent schema.

Therefore: Instead of using fwdata, we work with the "Verifiable generic XML" export of interlinear text (http://fieldworks.sil.org/wp-content/TechnicalDocs/Export%20options%20in%20Flex.pdf, §7.7)
As this format is only a reordered version of the flextext export (that serves as input to generate it), the LLODifier should also work for the original flextext