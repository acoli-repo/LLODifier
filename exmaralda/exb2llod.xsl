<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

    <!-- Exmaralda LLODifier -->
    <xsl:output method="text" indent="no"/>
    
    <xsl:param name="baseURI">http://example.org/PLEASE_PROVIDE_baseURI_PARAMETER</xsl:param>
    
    <xsl:template match="/">
        <!-- write TTL header -->
        <xsl:text>PREFIX exb: &lt;http://exmaralda.org/en/&gt;&#10;</xsl:text>
        <xsl:text>PREFIX rdfs: &lt;http://www.w3.org/2000/01/rdf-schema#&gt;&#10;</xsl:text>
        <xsl:text>PREFIX : &lt;</xsl:text>
        <xsl:value-of select="$baseURI"/>
        <xsl:text>#&gt;&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
        
        <!-- write TTL body -->
        <xsl:apply-templates/>
    </xsl:template>
    
    <!-- encode Exmaralda header -->
    <xsl:template match="basic-transcription">
        <xsl:text>&lt;</xsl:text>
        <xsl:value-of select="$baseURI"/>
        <xsl:text>&gt; a exb:</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:for-each select="head/meta-information//text()|head//@*">
            <xsl:variable name="val">
                <xsl:value-of select="normalize-space(string(.))"/>
            </xsl:variable>
            <xsl:if test="string-length(normalize-space($val))&gt;0">
                <xsl:text>;&#10;  exb:</xsl:text>
                <xsl:value-of select="name(..)"/>
                <xsl:if test="name()!=''">
                    <xsl:text>_</xsl:text>
                    <xsl:value-of select="name()"/>
                </xsl:if>
                <xsl:text> "</xsl:text>
                <xsl:value-of select="translate($val,';\',',/')"/>
                <xsl:text>"</xsl:text>
            </xsl:if>
        </xsl:for-each>
        <xsl:text>.&#10;&#10;</xsl:text>
        <xsl:apply-templates/>
    </xsl:template>

    <!-- see basic-transcription -->
    <xsl:template match="meta-information"/>

    <xsl:template match="basic-body|head">
            <xsl:apply-templates/>
        </xsl:template>
            
     <xsl:template match="speakertable">
         <xsl:if test="count(speaker[1])&gt;0">
         <xsl:text>&lt;</xsl:text>
         <xsl:value-of select="$baseURI"/>
         <xsl:text>&gt; </xsl:text>
         <xsl:text> exb:speakertable (</xsl:text>
         <xsl:for-each select="speaker">
             <xsl:text> :</xsl:text>
             <xsl:value-of select="@id"/>
         </xsl:for-each>
         <xsl:text>).&#10;</xsl:text>
         <xsl:for-each select="speaker">
             <xsl:text>:</xsl:text>
             <xsl:value-of select="@id"/>
             <xsl:text> a exb:speaker</xsl:text>
             <xsl:for-each select=".//text()|.//@*">
                 <xsl:if test="string-length(normalize-space(.))&gt;0">
                     <xsl:text>;&#10;  exb:</xsl:text>
                     <xsl:value-of select="name(..)"/>
                     <xsl:if test="name()!=''">
                         <xsl:text>_</xsl:text>
                         <xsl:value-of select="name()"/>
                     </xsl:if>
                     <xsl:text> "</xsl:text>
                     <xsl:value-of select="normalize-space(.)"/>
                     <xsl:text>"</xsl:text>
                 </xsl:if>
             </xsl:for-each>
             <xsl:text>.&#10;&#10;</xsl:text>
         </xsl:for-each>
         </xsl:if>
     </xsl:template>
            
    <!--
        common_timeline
        explicit encoding may seem redundant, but in a first conversion, we aim to stay isomorphic to Exmaralda, and only here, an absolute sequence of timepoints is given
    -->
    <xsl:template match="common-timeline">
        <xsl:text>&lt;</xsl:text>
        <xsl:value-of select="$baseURI"/>
        <xsl:text>&gt; exb:</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:text> ( </xsl:text>
        <xsl:for-each select="tli">
            <xsl:text>:</xsl:text>
            <xsl:value-of select="@id"/>
            <xsl:if test="count(./following-sibling::tli[1])&gt;0">
                <xsl:text> </xsl:text>
            </xsl:if>
        </xsl:for-each>
        <xsl:text>).&#10;</xsl:text>
        <xsl:for-each select="tli">
            <xsl:for-each select="@*[name()!='id'][string-length(normalize-space(string(.)))&gt;0]">
                <xsl:text>:</xsl:text>
                <xsl:value-of select="../@id"/>
                <xsl:text> exb:</xsl:text>
                <xsl:value-of select="name()"/>
                <xsl:text> "</xsl:text>
                <xsl:value-of select="."/>
                <xsl:text>".&#10;</xsl:text>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>
    
    <!-- tier: note that we anchor all annotations at the timeline (as in ELAN), not with a priviledged token layer -->
    <xsl:template match="tier">
        <!-- tier metadata -->
        <xsl:text>&lt;</xsl:text>
        <xsl:value-of select="$baseURI"/>
        <xsl:text>&gt; exb:tier :</xsl:text>
        <xsl:value-of select="@id"/>
        <xsl:text>.&#10;</xsl:text>
        <xsl:text>:</xsl:text>
        <xsl:value-of select="@id"/>
        <xsl:text> a exb:tier</xsl:text>
        <xsl:if test="@speaker!=''">
            <xsl:text>;&#10;  exb:speaker :</xsl:text>
            <xsl:value-of select="@speaker"/>
        </xsl:if>
        <xsl:for-each select="@*[name()!='id' and name()!='speaker']">
            <xsl:text>;&#10;  exb:</xsl:text>
            <xsl:value-of select="name()"/>
            <xsl:text> "</xsl:text>
            <xsl:value-of select="."/>
            <xsl:text>"</xsl:text>
        </xsl:for-each>
        <xsl:text>.&#10;&#10;</xsl:text>
        
        <!-- 
             tier events: we encode annotations and transcription as individuals with time anchoring, their value as an rdfs:label
             class derives from tier/@category, linked with the exb:event property with the tier
             note that this is very different from ELAN, a more advanced format
             
             also note that Exmaralda does not have the concept of tokens, so, we don't try to retokenize (as in ELAN)
        -->
        <xsl:for-each select="event">
            <xsl:variable name="id">
                <xsl:text>:event</xsl:text>
                <xsl:value-of select="count(./preceding::event)+1"/>    
            </xsl:variable>
            <xsl:text>:</xsl:text>
            <xsl:value-of select="../@id"/>
            <xsl:text> exb:event </xsl:text>
            <xsl:value-of select="$id"/>
            <xsl:text>.&#10;</xsl:text>
            <xsl:value-of select="$id"/>
            <xsl:text> a exb:</xsl:text>
            <xsl:value-of select="../@category"/>
            <xsl:if test="@start!=''">
                <xsl:text>;&#10;  exb:start :</xsl:text>
                <xsl:value-of select="@start"/>
            </xsl:if>
            <xsl:if test="@end!=''">
                <xsl:text>;&#10;  exb:end :</xsl:text>
                <xsl:value-of select="@end"/>
            </xsl:if>
            <xsl:for-each select="@*[name()!='start' and name()!='end' and string-length(.)&gt;0]">
                <xsl:text>;&#10;  exb:</xsl:text>
                <xsl:value-of select="name()"/>
                <xsl:text> "</xsl:text>
                <xsl:value-of select="."/>
                <xsl:text>"</xsl:text>
            </xsl:for-each>
            <xsl:for-each select="text()[string-length(normalize-space(.))&gt;0]">
                <xsl:text>;&#10;  rdfs:label "</xsl:text>
                <xsl:value-of select="translate(normalize-space(.),'&quot;',&quot;&apos;&quot;)"/>
                <xsl:text>"</xsl:text>
            </xsl:for-each>
            <xsl:text>.&#10;&#10;</xsl:text>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="text()"/>
</xsl:stylesheet>
