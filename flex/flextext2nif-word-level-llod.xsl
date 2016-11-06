<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

    <!-- FLEx ITG LLODifier, using the ITG XML export (cf. FlexInterlinear.xsd packaged with the tool -->
    <xsl:output method="text" indent="no"/>
    
    <xsl:param name="baseURI">http://example.org/PLEASE_PROVIDE_baseURI_PARAMETER</xsl:param>
    
    <xsl:template match="/">
        <!-- write TTL header -->
        <xsl:text>PREFIX flex: &lt;http://fieldworks.sil.org/flex/interlinear/&gt;&#10;</xsl:text> 
            <!-- this is only an informative site, the actual xsd schema is not online accessible, but available only within a package -->
        <xsl:text>PREFIX owl: &lt;http://www.w3.org/2002/07/owl#&gt;&#10;</xsl:text>    <!-- we use owl:sameAs for media/@location as this has to be a URI -->
        <xsl:text>PREFIX rdfs: &lt;http://www.w3.org/2000/01/rdf-schema#&gt;&#10;</xsl:text>
        <xsl:text>PREFIX nif: &lt;http://persistence.uni-leipzig.org/nlp2rdf/ontologies/nif-core#&gt;&#10;</xsl:text>
        <xsl:text>PREFIX : &lt;</xsl:text>
        <xsl:value-of select="$baseURI"/>
        <xsl:text>#&gt;&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
        
        <!-- write TTL body -->
        <xsl:apply-templates select="/document"/>
    </xsl:template>
    
    <xsl:template match="document">
        <xsl:call-template name="get-id"/>
        <xsl:text> a flex:</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:for-each select="@*[not(contains(name(),':')) and string-length(normalize-space(.))&gt;0]">
            <xsl:text>;&#10;  flex:</xsl:text>
            <xsl:value-of select="name()"/>
            <xsl:text> "</xsl:text>
            <xsl:value-of select="."/>
            <xsl:text>"</xsl:text>
        </xsl:for-each>
        <xsl:text>.&#10;&#10;</xsl:text>
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="interlinear-text">
        <xsl:for-each select="..">
            <xsl:call-template name="get-id"/>
        </xsl:for-each>
        <xsl:text> flex:has_</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:text> </xsl:text>
        <xsl:call-template name="get-id"/>
        <xsl:text>.&#10;</xsl:text>

        <xsl:call-template name="get-id"/>
        <xsl:text> a flex:</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:text> </xsl:text>
        <xsl:for-each select="@*[name()!='guid' and string-length(normalize-space(.))&gt;0]">
            <xsl:text>;&#10;  flex:</xsl:text>
            <xsl:value-of select="name()"/>
            <xsl:text> "</xsl:text>
            <xsl:value-of select="."/>
            <xsl:text>"</xsl:text>
        </xsl:for-each>
        <xsl:text>.&#10;&#10;</xsl:text>
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="media-files|languages|paragraphs|phrases|words">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="media|language">
        <xsl:for-each select="./ancestor::interlinear-text[1]">
            <xsl:call-template name="get-id"/>
        </xsl:for-each>
        <xsl:text> flex:has_</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:text> </xsl:text>
        <xsl:call-template name="get-id"/>
        <xsl:text>.&#10;</xsl:text>

        <xsl:call-template name="get-id"/>
        <xsl:text> a flex:</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:if test="@location!=''">
            <xsl:text>;&#10;  owl:sameAs &lt;</xsl:text>
            <xsl:value-of select="@location"/>
            <xsl:text>&gt;</xsl:text>
        </xsl:if>
        <xsl:for-each select="../@*|@*[name()!='location' and name()!='guid']">
            <xsl:if test="string-length(normalize-space(.))&gt;0">
                <xsl:text>;&#10;  flex:</xsl:text>
                <xsl:value-of select="name()"/>
                <xsl:text> "</xsl:text>
                <xsl:value-of select="."/>
                <xsl:text>"</xsl:text>
            </xsl:if>
        </xsl:for-each>
        <xsl:text>.&#10;&#10;</xsl:text>
    </xsl:template>
    
    <!-- using reification if additional information applies -->
    <xsl:template match="item[count(@*[name()!='type' and name()!='lang'])=0]">
        <xsl:text>_:item_</xsl:text>
        <xsl:value-of select="count(./ancestor-or-self::item)+count(preceding::item)"/>
        <xsl:text> rdfs:subject </xsl:text>
        <xsl:for-each select="..">
            <xsl:call-template name="get-id"/>
        </xsl:for-each>
        <xsl:text>; rdfs:predicate flex:</xsl:text>
        <xsl:value-of select="@type"/>
        <xsl:text>; rdfs:object "</xsl:text>
        <xsl:value-of select="translate(text(),'&quot;',&quot;&apos;&quot;)"/>
        <xsl:text>"@</xsl:text>
        <xsl:value-of select="@lang"/>
        <xsl:for-each select="@*[name()!='lang' and name()!='type' and string-length(normalize-space(.))&gt;0]">
            <xsl:text>; flex:</xsl:text>
            <xsl:value-of select="name()"/>
            <xsl:text> "</xsl:text>
            <xsl:value-of select="."/>
            <xsl:text>"</xsl:text>
        </xsl:for-each>
        <xsl:text>.&#10;</xsl:text>
    </xsl:template>
    
    <!-- note that we have to conflate txt and punct to get the full string -->
    <xsl:template match="item[count(@*[name()!='type' and name()!='lang'])=0]">
        <xsl:for-each select="..">
            <xsl:call-template name="get-id"/>
        </xsl:for-each>
        <xsl:choose>
            <xsl:when test="@type='txt' or @type='punct'">
                <xsl:text> rdfs:label</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text> flex:</xsl:text>
                <xsl:value-of select="@type"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text> "</xsl:text>
        <xsl:value-of select="translate(text(),'&quot;',&quot;&apos;&quot;)"/>
        <xsl:text>"@</xsl:text>
        <xsl:value-of select="@lang"/>
        <xsl:text>.&#10;&#10;</xsl:text>
    </xsl:template>
    
    <!-- note that flex "phrases" are usually not phrases in a syntactic sense, but "utterances", hence modeled as nif:Sentence <br/>
         similarly, flex:words can be recursive (for MWEs), and are thus modeled as nif:Phrases, this is tag abuse, though
    -->
    <xsl:template match="paragraph|phrase|word|scrMilestone|morph">
        <xsl:variable name="name" select="name()"/>
        <xsl:variable name="nifName">
            <xsl:choose>
                <xsl:when test="name()='word' and count(word[1])&gt;0">
                    <xsl:text>nif:Phrase</xsl:text>
                </xsl:when>
                <xsl:when test="name()='phrase'">
                    <xsl:text>nif:Sentence</xsl:text>
                </xsl:when>
                <xsl:when test="name()='word' or name()='paragraph'">
                    <xsl:text>nif:</xsl:text>
                    <xsl:value-of select="translate(substring(name(),1,1),'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
                    <xsl:value-of select="substring(name(),2)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>flex:</xsl:text>
                    <xsl:value-of select="name()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:for-each select="./ancestor::*[name()='interlinear-text' or name()='paragraph' or name()='phrase' or name()='word' or name()='morph'][1]">
            <!-- special treatment for words to account for scrMilestone -->
            <xsl:call-template name="get-id"/>
        </xsl:for-each>
        <xsl:choose>
            <xsl:when test="starts-with($nifName,'nif:')">
                <xsl:text> nif:superString </xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text> flex:has_</xsl:text>
                <xsl:value-of select="name()"/>
                <xsl:text> </xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:call-template name="get-id"/>
        <xsl:text>.&#10;</xsl:text>
        <xsl:call-template name="get-id"/>
        <xsl:text> a </xsl:text>
        <xsl:value-of select="$nifName"/>
        <xsl:if test="@type!=''">
            <xsl:text>;&#10;  a flex:</xsl:text>
            <xsl:value-of select="@type"/>
        </xsl:if>
        <xsl:if test="count(ancestor::word[1])&gt;0">
            <xsl:text>;&#10;  nif:subString </xsl:text>
            <xsl:for-each select="ancestor::word[1]">
                <xsl:call-template name="get-id"/>
            </xsl:for-each>
        </xsl:if>
        <xsl:if test="$nifName='nif:Sentence'">
            <xsl:text>;&#10;  nif:firstWord </xsl:text>
            <xsl:for-each select=".//word[count(word[1])=0][1]">
                <xsl:call-template name="get-id"/>
            </xsl:for-each>
        </xsl:if>
        <xsl:for-each select="@*[name()!='guid' and name()!='type' and string-length(normalize-space(.))&gt;0]">
            <xsl:text>;&#10;  flex:</xsl:text>
            <xsl:value-of select="name()"/>
            <xsl:text> "</xsl:text>
            <xsl:value-of select="."/>
            <xsl:text>"</xsl:text>
        </xsl:for-each>
        <xsl:if test="$nifName='nif:Word'">
            <!-- note that we skip scrMilestones -->
            <xsl:if test="count(following-sibling::word[count(word[1])=0][1])&gt;0">
                <xsl:text>;&#10;  nif:nextWord </xsl:text>
                <xsl:for-each select="following-sibling::word[count(word[1])=0][1]">
                    <xsl:call-template name="get-id"/>
                </xsl:for-each>
            </xsl:if>
        </xsl:if>
        <xsl:if test="$nifName='nif:Sentence'">
            <!-- note that these are flex:phrases (!) -->
            <xsl:if test="count(following-sibling::phrase[1])&gt;0">
                <xsl:text>;&#10;  nif:nextSentence </xsl:text>
                <xsl:for-each select="following-sibling::phrase[1]">
                    <xsl:call-template name="get-id"/>
                </xsl:for-each>
            </xsl:if>
        </xsl:if>
        <xsl:if test="count(following-sibling::*[name()=$name or name()='scrMilestone'][1])&gt;0">
            <!-- special treatment of scrMilestone and Word, because these are alternating -->
            <xsl:text>;&#10;  flex:next_</xsl:text>
            <xsl:choose>
                <xsl:when test="$name='scrMilestone'">
                    <xsl:text>word</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="name()"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text> </xsl:text>
            <xsl:for-each select="following-sibling::*[name()=$name or name()='scrMilestone'][1]">
                <xsl:call-template name="get-id"/>
            </xsl:for-each>
        </xsl:if>
        <xsl:text>.&#10;&#10;</xsl:text>
        <xsl:apply-templates/>
    </xsl:template>
    
    <!-- guid seems to refer to types, not tokens, hence disabled -->
    <xsl:template name="get-id">
        <xsl:choose>
            <xsl:when test="name()='document'">
                <xsl:text>&lt;</xsl:text>
                <xsl:value-of select="$baseURI"/>
                <xsl:text>&gt;</xsl:text>
            </xsl:when>
            <!--xsl:when test="@guid!=''">
                <xsl:text>:</xsl:text>
                <xsl:value-of select="@guid"/>
            </xsl:when-->
            <xsl:otherwise>
                <xsl:variable name="name" select="name()"/>
                <xsl:text>:</xsl:text>
                <xsl:value-of select="$name"/>
                <xsl:text>_</xsl:text>
                <xsl:value-of select="count(./ancestor-or-self::*[name()=$name])+count(preceding::*[name()=$name])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="text()"/>
    
</xsl:stylesheet>
