<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" xmlns:atlas="http://www.ldc.upenn.edu/atlas/ag/">

    <!-- LLODifier for Annotation Graphs (ATLAS/AIF level 0) -->
    <xsl:output method="text" indent="no"/>
    
    <xsl:param name="baseURI">http://example.org/PLEASE_PROVIDE_baseURI_PARAMETER</xsl:param>
    
    <xsl:template match="/">
        <!-- write TTL header -->
        <xsl:text>PREFIX dc: &lt;http://purl.org/dc/elements/1.1/&gt;&#10;</xsl:text>
        <xsl:text>PREFIX xlink: &lt;http://www.w3.org/1999/xlink/&gt;&#10;</xsl:text>
        <xsl:text>PREFIX atlas: &lt;http://www.ldc.upenn.edu/atlas/ag/&gt;&#10;</xsl:text>   <!-- this was given in the examples, doesn't resolve, an actual [but invalid] DTD is under http://xml.coverpages.org/atlas-ag-DTD.txt -->
        <xsl:text>PREFIX : &lt;</xsl:text>
        <xsl:value-of select="$baseURI"/>
        <xsl:text>#&gt;&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
        
        <!-- write TTL body -->
        <xsl:apply-templates/>
    </xsl:template>
    
    <!-- annotation header and metadata -->
    <xsl:template match="atlas:AGSet">
        <xsl:text>&lt;</xsl:text>
        <xsl:value-of select="$baseURI"/>
        <xsl:text>&gt; atlas:</xsl:text>
        <xsl:value-of select="translate(name(),'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')"/>
        <xsl:text> :</xsl:text>
        <xsl:value-of select="@id"/>
        <xsl:text>.&#10;</xsl:text>
        <xsl:text>:</xsl:text>
        <xsl:value-of select="@id"/>
        <xsl:text> a atlas:</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:for-each select="@*">
            <xsl:if test="not(contains(name(),':')) and string-length(normalize-space(string(.)))&gt;0 and name()!='id'">
                <xsl:text>;&#10;  atlas:</xsl:text>
                <xsl:value-of select="name()"/>
                <xsl:text> "</xsl:text>
                <xsl:value-of select="."/>
                <xsl:text>"</xsl:text>
            </xsl:if>
        </xsl:for-each>
        <xsl:for-each select="atlas:Metadata/*">
            <xsl:if test="string-length(normalize-space(string(.)))&gt;0">
                <xsl:text>;&#10;  </xsl:text>
                <xsl:if test="not(contains(name(),':'))">
                    <xsl:text>atlas:</xsl:text>
                </xsl:if>
                <xsl:value-of select="name()"/>
                <xsl:text> "</xsl:text>
                <xsl:value-of select="."/>
                <xsl:text>"</xsl:text>
            </xsl:if>
        </xsl:for-each>
        <xsl:text>.&#10;&#10;</xsl:text>

        <xsl:apply-templates/>
    </xsl:template>
    
    <!-- see AGset -->
    <xsl:template match="atlas:Metadata"/>
    
    <!-- NB: Timeline does *not* provide timeline information, but identifies the audio files associated with a particular timeline -->
    <xsl:template match="atlas:Timeline|atlas:Signal|atlas:AG|atlas:Anchor|atlas:Annotation">
        <xsl:text>:</xsl:text>
        <xsl:value-of select="../@id"/>
        <xsl:text> atlas:</xsl:text>
        <xsl:value-of select="translate(name(),'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')"/>
        <xsl:text> :</xsl:text>
        <xsl:value-of select="@id"/>
        <xsl:text>.&#10;</xsl:text>
        <xsl:text>:</xsl:text>
        <xsl:value-of select="@id"/>
        <xsl:text> a atlas:</xsl:text>
        <xsl:value-of select="name()"/>
        
        <!-- object properties -->
        <xsl:for-each select="@timeline|@start|@end">
            <xsl:text>;&#10;  atlas:</xsl:text>
            <xsl:value-of select="name()"/>
            <xsl:text> :</xsl:text>
            <xsl:value-of select="."/>
        </xsl:for-each>
        
        <!-- datatype properties -->
        <xsl:for-each select="@*[name()!='id' and name()!='timeline' and string-length(normalize-space(.))&gt;0]">
            <xsl:text>;&#10;  </xsl:text>
            <xsl:if test="not(contains(name(),':'))">
                <xsl:text>atlas:</xsl:text>
            </xsl:if>
            <xsl:value-of select="name()"/>
            <xsl:text> "</xsl:text>
            <xsl:value-of select="."/>
            <xsl:text>"</xsl:text>
        </xsl:for-each>
        <xsl:text>.&#10;&#10;</xsl:text>
        <xsl:apply-templates/>
    </xsl:template>
    
    <!-- note that we have to disentangle datatype properties ("normal") and object properties (e.g., for alignment, coref) *heuristically*:
         we check whether the feature value represents an id in the local file -->
    <xsl:template match="atlas:Feature">
        <xsl:text>:</xsl:text>
        <xsl:value-of select="../@id"/>
        <xsl:text> atlas:</xsl:text>
        <xsl:choose>
            <xsl:when test="@name!=''">
                <xsl:value-of select="@name"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="name()"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:variable name="value" select="."/>
        <xsl:choose>
            <xsl:when test="count(//*[@id=$value][1])&gt;0">
                <xsl:text> :</xsl:text>
                <xsl:value-of select="."/>      <!-- object prop, "foreign key" -->
            </xsl:when>
            <xsl:otherwise>
                <xsl:text> "</xsl:text>
                <xsl:value-of select="."/>      <!-- datatype prop, literal value -->
                <xsl:text>"</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>.&#10;&#10;</xsl:text>
    </xsl:template>
    
    <xsl:template match="text()"/>
    
</xsl:stylesheet>
