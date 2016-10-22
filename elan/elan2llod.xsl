<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

    <!-- ELAN LLODifier -->
    <xsl:output method="text" indent="no"/>
    
    <xsl:param name="baseURI">http://example.org/PLEASE_PROVIDE_baseURI_PARAMETER</xsl:param>
    
    <xsl:template match="/">
        <!-- write TTL header -->
        <xsl:text>PREFIX elan: &lt;</xsl:text>
        <xsl:value-of xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" select="/ANNOTATION_DOCUMENT/@xsi:noNamespaceSchemaLocation"/>
        <xsl:text>#&gt;&#10;</xsl:text>
        <xsl:text>PREFIX : &lt;</xsl:text>
        <xsl:value-of select="$baseURI"/>
        <xsl:text>#&gt;&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
        
        <!-- write TTL body -->
        <xsl:apply-templates/>
    </xsl:template>
    
    <!-- encode ELAN header and locale metadata -->
    <xsl:template match="ANNOTATION_DOCUMENT">
        <xsl:text>&lt;</xsl:text>
        <xsl:value-of select="$baseURI"/>
        <xsl:text>&gt; a elan:</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:for-each select="@*|HEADER/@*">
            <xsl:if test="not(contains(name(),':')) and string-length(normalize-space(string(.)))&gt;0">
                <xsl:text>;&#10;  elan:</xsl:text>
                <xsl:value-of select="name()"/>
                <xsl:text> "</xsl:text>
                <xsl:value-of select="."/>
                <xsl:text>"</xsl:text>
            </xsl:if>
        </xsl:for-each>
        <xsl:for-each select="HEADER/PROPERTY">
            <xsl:if test="not(contains(@NAME,':')) and string-length(normalize-space(string(text()[1])))&gt;0">
                <xsl:text>;&#10;  elan:</xsl:text>
                <xsl:value-of select="@NAME"/>
                <xsl:text> "</xsl:text>
                <xsl:value-of select="text()"/>
                <xsl:text>"</xsl:text>
            </xsl:if>
        </xsl:for-each>
        <xsl:for-each select="//LOCALE">
            <xsl:text>;&#10;  &lt;http://purl.org/dc/elements/1.1/language&gt; "</xsl:text>
            <xsl:value-of select="@LANGUAGE_CODE"/>
            <xsl:if test="@COUNTRY_CODE!=''">
                <xsl:text>-</xsl:text>
                <xsl:value-of select="@COUNTRY_CODE"/>
            </xsl:if>
            <xsl:text>"</xsl:text>
        </xsl:for-each>
        <xsl:text>.&#10;&#10;</xsl:text>
        
        <xsl:for-each select="HEADER/MEDIA_DESCRIPTOR/@MEDIA_URL">
            <xsl:variable name="me" select="."/>
            <xsl:text>&lt;</xsl:text>
            <xsl:value-of select="$baseURI"/>
            <xsl:text>&gt; elan:</xsl:text>
            <xsl:value-of select="name()"/>
            <xsl:text> &lt;</xsl:text>
            <xsl:value-of select="$me"/>
            <xsl:text>&gt;.&#10;&#10;</xsl:text>
            
            <xsl:for-each select="../@*[string-length(normalize-space(string(.)))&gt;0][not(contains(name(),':'))]">
                <xsl:text>&lt;</xsl:text>
                <xsl:value-of select="$me"/>
                <xsl:text>&gt; elan:</xsl:text>
                <xsl:value-of select="name()"/>
                <xsl:text> "</xsl:text>
                <xsl:value-of select="."/>
                <xsl:text>".&#10;</xsl:text>
            </xsl:for-each>
        </xsl:for-each>
        
        <xsl:apply-templates/>
    </xsl:template>
    
    <!-- see ANNOTATION_DOCUMENT -->
    <xsl:template match="HEADER"/>
    
    <!--
        TIME_ORDER 
        explicit encoding may seem redundant, but in a first conversion, we aim to stay isomorphic to ELAN, and only here, an absolute sequence of timepoints is given
    -->
    <xsl:template match="TIME_ORDER">
        <xsl:text>&lt;</xsl:text>
        <xsl:value-of select="$baseURI"/>
        <xsl:text>&gt; elan:</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:text> ( </xsl:text>
        <xsl:for-each select="TIME_SLOT">
            <xsl:text>:</xsl:text>
            <xsl:value-of select="@TIME_SLOT_ID"/>
            <xsl:if test="count(./following-sibling::TIME_SLOT[1])&gt;0">
                <xsl:text> </xsl:text>
            </xsl:if>
        </xsl:for-each>
        <xsl:text>).&#10;</xsl:text>
        <xsl:for-each select="TIME_SLOT">
            <xsl:for-each select="@*[name()!='TIME_SLOT_ID'][string-length(normalize-space(string(.)))&gt;0]">
                <xsl:text>:</xsl:text>
                <xsl:value-of select="../@TIME_SLOT_ID"/>
                <xsl:text> elan:</xsl:text>
                <xsl:value-of select="name()"/>
                <xsl:text> "</xsl:text>
                <xsl:value-of select="."/>
                <xsl:text>".&#10;</xsl:text>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>
    
    <!-- TIER: note that we do not try to split sequences into subtokens -->
    <xsl:template match="TIER">
        <!-- TIER metadata -->
        <xsl:text>&lt;</xsl:text>
        <xsl:value-of select="$baseURI"/>
        <xsl:text>&gt; elan:TIER :</xsl:text>
        <xsl:value-of select="@TIER_ID"/>
        <xsl:text>.&#10;</xsl:text>
        <xsl:text>:</xsl:text>
        <xsl:value-of select="@TIER_ID"/>
        <xsl:text> a elan:TIER</xsl:text>
        <xsl:for-each select="@*">
            <xsl:text>;&#10;  elan:</xsl:text>
            <xsl:value-of select="name()"/>
            <xsl:text> "</xsl:text>
            <xsl:value-of select="."/>
            <xsl:text>"</xsl:text>
        </xsl:for-each>
        <xsl:text>.&#10;</xsl:text>
        
        <!-- TIER annotation: we encode annotations as properties, only indirectly linked with their metadata by TIER_ID and property name -->
        <xsl:for-each select="ANNOTATION//@ANNOTATION_ID">
            <xsl:choose>
                <xsl:when test="../@ANNOTATION_REF!=''">        <!-- property encoding for higher layers -->
                    <xsl:text>:</xsl:text>
                    <xsl:value-of select="../@ANNOTATION_REF"/>
                    <xsl:text> elan:</xsl:text>
                    <xsl:value-of select="./ancestor::*/@TIER_ID[1]"/>
                    <xsl:text> :</xsl:text>
                    <xsl:value-of select="."/>
                    <xsl:text>.&#10;</xsl:text>
                </xsl:when>
                <xsl:when test="../@TIME_SLOT_REF1!=''">            <!-- class encoding for transcription layer(s), only if not referring to other annotations -->
                    <xsl:text>:</xsl:text>
                    <xsl:value-of select="."/>
                    <xsl:text> a elan:</xsl:text>                   <!-- note: leads to a type class if transcription and annotation are not poperly distinguished -->
                    <xsl:value-of select="./ancestor::*/@TIER_ID[1]"/>
                    <xsl:text>;&#10;  elan:TIME_SLOT_REF1 :</xsl:text>
                    <xsl:value-of select="../@TIME_SLOT_REF1"/>
                    <xsl:if test="../@TIME_SLOT_REF2!=''">
                        <xsl:text>;&#10;  elan:TIME_SLOT_REF2 :</xsl:text>
                        <xsl:value-of select="../@TIME_SLOT_REF2"/>
                    </xsl:if>
                    <xsl:text>.&#10;</xsl:text>
                </xsl:when>
            </xsl:choose>
            
            <xsl:text>:</xsl:text>
            <xsl:value-of select="."/>
            <xsl:text> elan:ANNOTATION_VALUE "</xsl:text>
            <xsl:value-of select="../ANNOTATION_VALUE/text()[1]"/>
            <xsl:text>".&#10;</xsl:text>
        </xsl:for-each>
    </xsl:template>
    
    <!-- ELAN processing metadata -->
    <xsl:template match="LINGUISTIC_TYPE|CONSTRAINT"/>
</xsl:stylesheet>
