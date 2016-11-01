<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

    <!-- PTB LLODifier, via intermediate XML format -->
    <xsl:output method="text" indent="no"/>
    
    <xsl:param name="baseURI">http://example.org/PLEASE_PROVIDE_baseURI_PARAMETER</xsl:param>
    
    <xsl:template match="/">
        <!-- write TTL header -->
        <xsl:text>@prefix ptb: &lt;ftp://ftp.cis.upenn.edu/pub/treebank/doc/manual/notation.tex#&gt;.&#10;</xsl:text>
        <xsl:text>@prefix nif: &lt;http://persistence.uni-leipzig.org/nlp2rdf/ontologies/nif-core#&gt;.&#10;</xsl:text>
        <xsl:text>@prefix rdfs: &lt;http://www.w3.org/2000/01/rdf-schema#&gt;.&#10;</xsl:text>
		<xsl:text>@prefix rdf: &lt;http://www.w3.org/1999/02/22-rdf-syntax-ns#&gt;.&#10;</xsl:text>
        <xsl:text>@prefix : &lt;</xsl:text>
        <xsl:value-of select="$baseURI"/>
        <xsl:text>#&gt;.&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
        
        <!-- write TTL body -->
        <xsl:text>&lt;</xsl:text>
        <xsl:value-of select="$baseURI"/>
        <xsl:text>&gt; ptb:contains (</xsl:text>
        <xsl:for-each select="/*/node">
            <xsl:text> :</xsl:text>
            <xsl:call-template name="get-node-id"/>
        </xsl:for-each>
        <xsl:text> ).&#10;&#10;</xsl:text>
        
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="node">
        <xsl:text>:</xsl:text>
        <xsl:call-template name="get-node-id"/>
        <xsl:text> a nif:</xsl:text>
        <xsl:choose>
            <xsl:when test="count(node[1])=0">
                <xsl:text>Word</xsl:text>
                <xsl:variable name="sid">
                    <xsl:for-each select="ancestor-or-self::node[last()]">
                        <xsl:call-template name="get-node-id"/>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:for-each select="(following::node[count(node[1])=0])[1]">
                    <xsl:variable name="nextsid">
                        <xsl:for-each select="ancestor-or-self::node[last()]">
                            <xsl:call-template name="get-node-id"/>
                        </xsl:for-each>
                    </xsl:variable>
                    <xsl:if test="$sid=$nextsid">
                        <xsl:text>;&#10;  nif:nextWord :</xsl:text>
                        <xsl:call-template name="get-node-id"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:when>
            <xsl:when test="count(./ancestor::node[1])=0">
                <xsl:text>Sentence</xsl:text>
                <xsl:if test="count(following-sibling::node[1])&gt;0">
                    <xsl:text>;&#10;  nif:nextSentence :</xsl:text>
                    <xsl:for-each select="following-sibling::node[1]">
                        <xsl:call-template name="get-node-id"/>
                    </xsl:for-each>
                </xsl:if>
                <xsl:for-each select="(.//node[count(node[1])=0])[1]">
                    <xsl:text>;&#10;  nif:firstWord :</xsl:text>
                    <xsl:call-template name="get-node-id"/>
                </xsl:for-each>
                <xsl:for-each select="(.//node[count(node[1])=0])[last()]">
                    <xsl:text>;&#10;  nif:lastWord :</xsl:text>
                    <xsl:call-template name="get-node-id"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>Phrase</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:for-each select="@*[string-length(normalize-space(.))&gt;0]">
            <xsl:text>;&#10;  ptb:</xsl:text>
            <xsl:value-of select="name()"/>
            <xsl:text> "</xsl:text>
            <xsl:value-of select="."/>
            <xsl:text>"</xsl:text>
        </xsl:for-each>
        <xsl:if test="count(./text()[1][string-length(normalize-space(string(.)))&gt;0])&gt;0">
            <xsl:text>;&#10;  rdfs:label "</xsl:text>
            <xsl:value-of select="normalize-space(./text()[1])"/>
            <xsl:text>"</xsl:text>
        </xsl:if>
        <xsl:for-each select="./ancestor::node[1]">
            <xsl:text>;&#10;  nif:subString :</xsl:text>
            <xsl:call-template name="get-node-id"/>
        </xsl:for-each>
        <xsl:text>.&#10;</xsl:text>
        <xsl:apply-templates/>
    </xsl:template>
    
    <!-- see node -->
    <xsl:template match="text()"/>
    
    <!-- get ids for nodes (i.e., a pair of brackets) -->
    <xsl:template name="get-node-id">
        <xsl:for-each select="./ancestor-or-self::node[1]">
            <xsl:value-of select="name()"/>
            <xsl:value-of select="count(./preceding::*)+count(./ancestor::*)"/>
        </xsl:for-each>
    </xsl:template>

</xsl:stylesheet>
