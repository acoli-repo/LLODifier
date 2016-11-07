<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" xmlns:ag="http://www.ldc.upenn.edu/atlas/ag/" xmlns="http://www.tei-c.org/ns/1.0">

    <!-- 
        LLODifier for TEI P5 (as far as used in the samples) 
        Note that we ancode the structure of the XML file using the properties xml:following-sibling and xml:parent that represent the corresponding axes
        
        we need XSLT 2.0 for group references (we don't support containers)
        note that we presume that comments have been removed. otherwise, the following-sibling axis will break
    -->
    <xsl:output method="text" indent="no"/>
    
    <xsl:param name="baseURI">http://example.org/PLEASE_PROVIDE_baseURI_PARAMETER</xsl:param>
    
    <xsl:template match="/">
        <!-- write TTL header -->
        <xsl:text>PREFIX dc: &lt;http://purl.org/dc/elements/1.1/&gt;&#10;</xsl:text>
        <xsl:text>PREFIX tei: &lt;http://www.tei-c.org/ns/1.0/&gt;&#10;</xsl:text>
        <xsl:text>PREFIX xml: &lt;http://www.w3.org/XML/1998/namespace/&gt;&#10;</xsl:text>
        <xsl:text>PREFIX : &lt;</xsl:text>
        <xsl:value-of select="$baseURI"/>
        <xsl:text>#&gt;&#10;</xsl:text>
        <xsl:text>BASE &lt;</xsl:text>
        <xsl:value-of select="$baseURI"/>
        <xsl:text>&gt;&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
        
        <!-- write TTL body -->
        <xsl:for-each select="/*">
            <xsl:call-template name="get-id"/>
        </xsl:for-each>
        <xsl:text> xml:parent &lt;</xsl:text>
        <xsl:value-of select="$baseURI"/>
        <xsl:text>&gt;.&#10;</xsl:text>
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="*">
        <xsl:call-template name="get-id"/>
        <xsl:text> a tei:</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:for-each select="..[name()!='']">
            <xsl:text>;&#10;  xml:parent </xsl:text>
            <xsl:call-template name="get-id"/>
        </xsl:for-each>
        <xsl:for-each select="@*[string-length(normalize-space(.))&gt;0][not(contains(name(),':'))]">
            <xsl:text>;&#10;  tei:</xsl:text>
            <xsl:value-of select="name()"/>
            <xsl:text> </xsl:text>
            <xsl:choose>
                <!-- heuristic IDREF/URI detection -->
                <xsl:when test="(contains(.,':/') or contains(.,'#'))">
                    <xsl:if test="contains(normalize-space(.),' ')">
                        <xsl:text>(</xsl:text>
                    </xsl:if>
                    <xsl:value-of select="replace(
                        concat('&lt;',replace(normalize-space(string(.)),' +','&gt; &lt;'),'&gt;'),
                        '&lt;([^: #]+#)','&lt;file:$1')"/>
                    <xsl:if test="contains(normalize-space(.),' ')">
                        <xsl:text>)</xsl:text>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>"</xsl:text>
                    <xsl:value-of select="."/>
                    <xsl:text>"</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        <xsl:for-each select="./following-sibling::node()[string(.)='' or normalize-space(.)!=''][1]">
            <xsl:text>;&#10;  xml:following-sibling </xsl:text>
            <xsl:choose>
                <xsl:when test="name()!=''">
                    <xsl:call-template name="get-id"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>_:cdata_</xsl:text>
                    <xsl:value-of select="count(preceding::text())+count(ancestor-or-self::text())"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        <xsl:text> .&#10;&#10;</xsl:text>
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="comment()"/>
    
    <xsl:template match="text()">
        <xsl:if test="string-length(normalize-space(.))&gt;0">
            <xsl:text>_:cdata_</xsl:text>
            <xsl:value-of select="count(preceding::text())+count(ancestor-or-self::text())"/>
            <xsl:text> a xml:CDATA</xsl:text>
            <xsl:text>;&#10;  rdfs:label "</xsl:text>
            <xsl:value-of select="replace(replace(normalize-space(.),'&amp;','&amp;&amp;'),'&quot;','&amp;quot;')"/>
            <xsl:text>"</xsl:text>
            <xsl:for-each select="(./ancestor::*[@xml:lang!=''])[1]/@xml:lang">
                <xsl:text>@</xsl:text>
                <xsl:value-of select="."/>
            </xsl:for-each>
            <xsl:text>;&#10;  xml:parent </xsl:text>
            <xsl:for-each select="..">
                <xsl:call-template name="get-id"/>
            </xsl:for-each>
            <xsl:for-each select="./following-sibling::node()[string(.)='' or normalize-space(.)!=''][1]">
                <xsl:text>;&#10;  xml:following-sibling </xsl:text>
                <xsl:choose>
                    <xsl:when test="name()!=''">
                        <xsl:call-template name="get-id"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>_:cdata_</xsl:text>
                        <xsl:value-of select="count(preceding::text())+count(ancestor-or-self::text())"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
            <xsl:text> .&#10;&#10;</xsl:text>
        </xsl:if>
    </xsl:template>

    <!-- should be called on a node -->
    <xsl:template name="get-id">
        <xsl:choose>
            <xsl:when test="@xml:id!=''">
                <xsl:text>:</xsl:text>
                <xsl:value-of select="replace(@xml:id,'.$','_')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="name" select="name()"/>
                <xsl:text>:</xsl:text>
                <xsl:value-of select="name()"/>
                <xsl:text>_</xsl:text>
                <xsl:value-of select="count(preceding::*[name()=$name])+count(ancestor-or-self::*[name()=$name])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
