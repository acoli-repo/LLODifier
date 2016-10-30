<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

    <!-- TIGER XML LLODifier -->
    <xsl:output method="text" indent="no"/>
    
    <xsl:param name="baseURI">http://example.org/PLEASE_PROVIDE_baseURI_PARAMETER</xsl:param>
    
    <xsl:template match="/">
        <!-- write TTL header -->
        <xsl:text>@prefix tiger: &lt;http://www.ims.uni-stuttgart.de/forschung/ressourcen/korpora/TIGERCorpus/public/TigerXML.xsd#&gt;.&#10;</xsl:text>
        <xsl:text>@prefix nif: &lt;http://persistence.uni-leipzig.org/nlp2rdf/ontologies/nif-core#&gt;.&#10;</xsl:text>
        <xsl:text>@prefix rdfs: &lt;http://www.w3.org/2000/01/rdf-schema#&gt;.&#10;</xsl:text>
		<xsl:text>@prefix rdf: &lt;http://www.w3.org/1999/02/22-rdf-syntax-ns#&gt;.&#10;</xsl:text>
        <xsl:text>@prefix : &lt;</xsl:text>
        <xsl:value-of select="$baseURI"/>
        <xsl:text>#&gt;.&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
        
        <!-- write TTL body -->
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template name="get-collection-id">
        <xsl:variable name="subcorpusid" select="ancestor-or-self::subcorpus[1]/@id"/>
        <xsl:variable name="corpusid" select="ancestor-or-self::corpus[1]/@id"/>
        <xsl:variable name="subcorpusname" select="ancestor-or-self::subcorpus[1]/@name"/>
		<xsl:call-template name="normalize-id">
			<xsl:with-param name="id">
				<xsl:choose>
					<xsl:when test="starts-with($subcorpusid,'http:/') or starts-with($subcorpusid,'https:/')"> <!-- subcorpus with HTTP URL -->
						<xsl:text>&lt;</xsl:text>
						<xsl:value-of select="$subcorpusid"/>
						<xsl:text>&gt;</xsl:text>
					</xsl:when>
					<xsl:when test="$subcorpusid!=''">                <!-- subcorpus with @id (should be @name, actually) -->
						<xsl:text>:</xsl:text>
						<xsl:value-of select="$subcorpusid"/>
					</xsl:when>
					<xsl:when test="$subcorpusname!=''">              <!-- subcorpus with @name -->
						<xsl:text>:</xsl:text>
						<xsl:value-of select="$subcorpusname"/>
					</xsl:when>
					<xsl:when test="count(ancestor-or-self::subcorpus[1])&gt;0">            <!-- subcorpus without attributes -->
						<xsl:text>:subcorpus.</xsl:text>
						<xsl:value-of select="count(./ancestor-or-self::subcorpus[1]/preceding::subcorpus)"/>
					</xsl:when>
					<xsl:when test="starts-with($corpusid,'http:/') or starts-with($corpusid,'https:/')">   <!-- corpus with HTTP URL -->
						<xsl:text>&lt;</xsl:text>
						<xsl:value-of select="$corpusid"/>
						<xsl:text>&gt;</xsl:text>
					</xsl:when>
					<xsl:otherwise>                                                         <!-- corpus -->
						<xsl:text>&lt;</xsl:text>
						<xsl:value-of select="$baseURI"/>
						<xsl:text>&gt;</xsl:text>            
					</xsl:otherwise>
				</xsl:choose>
			</xsl:with-param>
		</xsl:call-template>
    </xsl:template>
    
    <xsl:template match="corpus|subcorpus">
        <xsl:call-template name="get-collection-id"/>
        <xsl:text> a tiger:corpus</xsl:text>
        <xsl:for-each select="@*">
            <xsl:if test="not(contains(name(),':'))">
                <xsl:text>;&#10;  tiger:</xsl:text>
                <xsl:value-of select="name()"/>
                <xsl:text> "</xsl:text>
                <xsl:value-of select="."/>
                <xsl:text>"</xsl:text>
            </xsl:if>
        </xsl:for-each>
        <xsl:if test="count(./ancestor::*[name()='corpus' or name()='subcorpus'][1])&gt;0">
            <xsl:text>;&#10;  tiger:subcorpus </xsl:text>
            <xsl:for-each select="..">
                <xsl:call-template name="get-collection-id"/>
            </xsl:for-each>
        </xsl:if>
        <xsl:text>.&#10;&#10;</xsl:text>
        <xsl:apply-templates/>
    </xsl:template>
    
    <!-- nodes with structural function but without actual meaning -->
    <xsl:template match="head|body|graph|terminals|nonterminals">
        <xsl:apply-templates/>
    </xsl:template>
    
    <!-- skipped, can be compiled from the corpus itself -->
    <xsl:template match="annotation"/>
    
    <!-- not an aspect of the data -->
    <xsl:template match="match"/>
    
    <!-- should be /corpus/head/meta -->
    <xsl:template match="meta">
        <xsl:for-each select="*">
            <xsl:if test="string-length(string(text()[1]))&gt;0">
                <xsl:text>&gt;</xsl:text>
                <xsl:value-of select="$baseURI"/>
                <xsl:text> </xsl:text>
                <xsl:value-of select="name()"/>
                <xsl:text> "</xsl:text>
                <xsl:value-of select="."/>
                <xsl:text>.&#10;</xsl:text>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <!-- ids for s nodes -->
    <xsl:template name="get-sentence-id">
        <xsl:variable name="sid" select="./ancestor-or-self::s[1]/@id"/>
		<xsl:call-template name="normalize-id">
			<xsl:with-param name="id">
				<xsl:choose>
					<xsl:when test="starts-with($sid,'http:/') or starts-with($sid,'https:/')">
						<xsl:text>&lt;</xsl:text>
						<xsl:value-of select="$sid"/>
						<xsl:text>&gt;</xsl:text>
					</xsl:when>
					<xsl:when test="$sid!='' and not(contains($sid,':'))">
						<xsl:text>:</xsl:text>
						<xsl:value-of select="$sid"/>
					</xsl:when>
					<xsl:when test="count(./ancestor-or-self::s[1])&gt;0">
						<xsl:text>:s</xsl:text>
						<xsl:value-of select="count(./ancestor-or-self::s[1]/preceding::s)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:message>get-sentence-id should only be called on s elements</xsl:message>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:with-param>
		</xsl:call-template>
    </xsl:template>    

    <!-- modelled as nif:Sentence -->
    <xsl:template match="s">
        <xsl:call-template name="get-collection-id"/>
        <xsl:text> tiger:s </xsl:text>
        <xsl:call-template name="get-sentence-id"/>
        <xsl:text>.&#10;</xsl:text>
        <xsl:call-template name="get-sentence-id"/>
        <xsl:text> a nif:Sentence</xsl:text>
        <xsl:for-each select="@*|graph/@*">
            <xsl:if test="not(contains(name(),':')) and string-length(string(.))&gt;0">
                <xsl:text>;&#10;  tiger:</xsl:text>
                <xsl:value-of select="name()"/>
                <xsl:text> "</xsl:text>
                <xsl:value-of select="."/>
                <xsl:text>"</xsl:text>
            </xsl:if>
        </xsl:for-each>
        <xsl:text>;&#10;  nif:firstWord </xsl:text>
        <xsl:for-each select=".//t[1]">
            <xsl:call-template name="get-node-id"/>
        </xsl:for-each>
        <xsl:text>;&#10;  nif:lastWord </xsl:text>
        <xsl:for-each select=".//t[last()]">
            <xsl:call-template name="get-node-id"/>
        </xsl:for-each>
        <xsl:if test="count(following-sibling::s[1])&gt;0">
            <xsl:text>;&#10;  nif:nextSentence </xsl:text>
            <xsl:for-each select="./following-sibling::s[1]">
                <xsl:call-template name="get-sentence-id"/>
            </xsl:for-each>
        </xsl:if>
        <xsl:text>.&#10;</xsl:text>
        <xsl:apply-templates/>
    </xsl:template>
    
    <!-- get ids for t and nt nodes -->
    <xsl:template name="get-node-id">
		<xsl:call-template name="normalize-id">
			<xsl:with-param name="id">
				<xsl:choose>
					<xsl:when test="count(./ancestor-or-self::*[name()='t' or name()='nt'][1])=0">
						<xsl:message>warning get-node-id must be called on a t or nt node</xsl:message>
					</xsl:when>
					<xsl:when test="starts-with(./ancestor-or-self::*[name()='t' or name()='nt'][1]/@id,'http:/') or starts-with(./ancestor-or-self::*[name()='t' or name()='nt'][1]/@id,'https:/')">
						<xsl:text>&lt;</xsl:text>
						<xsl:value-of select="./ancestor-or-self::*[name()='t' or name()='nt'][1]/@id"/>
						<xsl:text>&gt;</xsl:text>
					</xsl:when>
					<xsl:when test="./ancestor-or-self::*[name()='t' or name()='nt'][1]/@id!='' and not(contains(./ancestor-or-self::*[name()='t' or name()='nt'][1]/@id,':'))">
						<xsl:text>:</xsl:text>
						<xsl:value-of select="./ancestor-or-self::*[name()='t' or name()='nt'][1]/@id"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:call-template name="get-sentence-id"/>
						<xsl:text>_</xsl:text>
						<xsl:value-of select="count(./preceding-sibling::nt)+count(./preceding-sibling::nt)+count(../preceding-sibling::terminals/t)+1"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:with-param>
		</xsl:call-template>
    </xsl:template>

	<!-- remove illegal URL characters from original IDs, only to the extent as encountered in the SCMRF sample data  -->
	<xsl:template name="normalize-id">
		<xsl:param name="id"/>
		<xsl:value-of select="translate($id,']','_')"/>
	</xsl:template>
	
    <!-- map word to rdfs:label, pos to nif:posTag, lemma to nif:lemma, stem to nif:stem, edge to reified nif:subString, secedge to reified nif:head -->
    <xsl:template match="t|nt">
        <xsl:variable name="id" select="@id"/>
        <xsl:call-template name="get-node-id"/>
        <xsl:text> a </xsl:text>
        <xsl:if test="name()='t'">nif:Word</xsl:if>
        <xsl:if test="name()='nt'">nif:Phrase</xsl:if>
        <xsl:for-each select="@*">
            <xsl:if test="not(contains(name(),':')) and string-length(string(.))&gt;0 and string(.)!='--'">
                <xsl:text>;&#10;  </xsl:text>
                <xsl:choose>
                    <xsl:when test="name()='word'">
                        <xsl:text>rdfs:label</xsl:text>
                    </xsl:when>
                    <xsl:when test="name()='lemma'">
                        <xsl:text>nif:lemma</xsl:text>
                    </xsl:when>
                    <xsl:when test="name()='pos'">
                        <xsl:text>nif:posTag</xsl:text>
                    </xsl:when>
                    <xsl:when test="name()='stem'">
                        <xsl:text>nif:stem</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>tiger:</xsl:text>
                        <xsl:value-of select="name()"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:text> "</xsl:text>
                <xsl:value-of select="."/>
                <xsl:text>"</xsl:text>
            </xsl:if>
        </xsl:for-each>
        <xsl:if test="count(following-sibling::t[1])&gt;0">
            <xsl:text>;&#10;  nif:nextWord </xsl:text>
            <xsl:for-each select="following-sibling::t[1]">
                <xsl:call-template name="get-node-id"/>
            </xsl:for-each>
        </xsl:if>
        <xsl:if test="count(./ancestor-or-self::s[1]//edge[@idref=$id][1])=0">
            <xsl:text>;&#10;  nif:sentence </xsl:text>
            <xsl:call-template name="get-sentence-id"/>
        </xsl:if>
        <xsl:text>.&#10;</xsl:text>
                
        <xsl:for-each select="edge|secedge">
            <xsl:variable name="idref" select="@idref"/>
            <xsl:text>_:</xsl:text>
            <xsl:value-of select="name()"/>
            <xsl:text>_</xsl:text>
            <xsl:value-of select="count(preceding::*)+count(ancestor-or-self::*)"/>
            <xsl:text> a rdf:Statement;</xsl:text>
            <xsl:text>&#10;  rdf:object </xsl:text>
            <xsl:call-template name="get-node-id"/>
            <xsl:text>;&#10;  rdf:predicate</xsl:text>
            <xsl:if test="name()='edge'">
                <xsl:text> nif:subString;</xsl:text>
            </xsl:if>
            <xsl:if test="name()='secedge'">
                <xsl:text> nif:head;</xsl:text>
            </xsl:if>
            <xsl:text>&#10;  rdf:subject </xsl:text>
            <xsl:for-each select="./ancestor::s[1]//*[@id=$idref][1]">
                <xsl:call-template name="get-node-id"/>
            </xsl:for-each>
            <xsl:for-each select="@*">
                <xsl:if test="not(contains(name(),':')) and string-length(.)&gt;0 and name()!='idref' and string(.)!='--'">
                    <xsl:text>;&#10;  tiger:</xsl:text>
                    <xsl:value-of select="name()"/>
                    <xsl:text> "</xsl:text>
                    <xsl:value-of select="."/>
                    <xsl:text>"</xsl:text>
                </xsl:if>
            </xsl:for-each>
            <xsl:text>.&#10;</xsl:text>
         </xsl:for-each>
    </xsl:template>
    
</xsl:stylesheet>
