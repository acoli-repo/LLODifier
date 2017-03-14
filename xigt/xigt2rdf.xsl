<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">

    <xsl:output method="text" indent="no"/>
    
    <!-- Xigt LLODifier -->
    <xsl:output method="text" indent="no"/>
    
    <xsl:param name="baseURI">http://example.org/PLEASE_PROVIDE_baseURI_PARAMETER</xsl:param>
    
    <xsl:template match="/">
        <!-- write TTL header -->
        <xsl:text>PREFIX xigt: &lt;https://github.com/xigt/xigt/wiki/Data-Model#&gt;&#10;</xsl:text>
        <xsl:text>PREFIX owl: &lt;http://www.w3.org/2002/07/owl#&gt;&#10;</xsl:text>
        <xsl:text>PREFIX rdfs: &lt;http://www.w3.org/2000/01/rdf-schema#&gt;&#10;</xsl:text>
        <xsl:text>PREFIX : &lt;</xsl:text>
        <xsl:value-of select="$baseURI"/>
        <xsl:text>#&gt;&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
        
        <!-- write TTL body -->
        <xsl:apply-templates/>
    </xsl:template>
    
    <!-- added in accordance with Readme.md -->
    <!-- note that we currently loose attributes of metadata (except @type, but incl. @id), but preserve attributes of meta 
         these could be added via reification
    -->
    <xsl:template match="metadata">
        <xsl:variable name="metadata_type" select="@type"/>
        <xsl:for-each select="meta">
            <xsl:variable name="id" select="@id"/>            
            <xsl:variable name="type">
                <xsl:choose>
                    <xsl:when test="string-length(@type)>0">
                        <xsl:value-of select="@type"/>
                    </xsl:when>
                    <xsl:otherwise>metadata</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:if test="$type!='metadata' and count(preceding::meta[name()=$type][1])=0">
                <xsl:text>xigt:</xsl:text>
                <xsl:value-of select="$type"/>
                <xsl:text> rdfs:subPropertyOf </xsl:text>
                <xsl:choose>
                    <xsl:when test="$metadata_type!=''">
                        <xsl:value-of select="$metadata_type"/>
                        <xsl:text>.&#10;</xsl:text>
                        <xsl:if test="count(./preceding::meta[1])+count(/preceding::metadata[@type=$metadata_type]/meta[1])=0">
                            <xsl:text>xigt:</xsl:text>
                            <xsl:value-of select="$metadata_type"/>
                            <xsl:text> rdfs:subPropertyOf xigt:metadata.&#10;</xsl:text>
                        </xsl:if>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>xigt:metadata.&#10;</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
                <xsl:for-each select="../..">
                    <xsl:call-template name="get-uri"/>
                    <xsl:text> </xsl:text>
                </xsl:for-each>
                <xsl:text> xigt:</xsl:text>
                <xsl:value-of select="$type"/>
            <xsl:text> </xsl:text>
            
                <xsl:choose>
                    <xsl:when test="string-length(@id)>0">
                        <xsl:text>:</xsl:text>
                        <xsl:value-of select="@id"/>
                        <xsl:text>.&#10;</xsl:text>
                        <xsl:text>:</xsl:text>
                        <xsl:value-of select="@id"/>
                        <xsl:text> </xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text> [ </xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            
            <xsl:variable name="meta_triple_raw">
                <xsl:if test="string-length(normalize-space(string-join(.,'')))&gt;0">
                <xsl:text> xigt:meta "</xsl:text>
                    <!--xsl:copy-of select="."/--> 
                    <!-- for XML content, as defined in the RelaxNG scheme -->
                    
                <xsl:value-of select="replace(replace(normalize-space(string-join(.,' ')),'&amp;','&amp;amp;'),'&quot;','&amp;quot;')"/>
                    <!-- for textual content, as found in the sample files -->
                    
                <xsl:text>" ; </xsl:text>
                </xsl:if>
                <xsl:for-each select="@*[name()!='type' and name()!='id']">
                    <xsl:text>xigt:</xsl:text>
                    <xsl:value-of select="name()"/>
                    <xsl:text> "</xsl:text>
                    <xsl:value-of select="replace(replace(.,'&amp;','&amp;amp;'),'&quot;','&amp;quot;')"/>
                    <xsl:text>"; </xsl:text>
                </xsl:for-each>
            
            </xsl:variable>
            <xsl:value-of select="replace($meta_triple_raw,'; $','')"/>
                <xsl:if test="string-length(@id)=0">
                    <xsl:text> ]</xsl:text>
                </xsl:if>
             <xsl:text> .&#10;</xsl:text>

        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="*">
        <xsl:variable name="name" select="name()"/>
        <xsl:variable name="me">
            <xsl:call-template name="get-uri"/>
        </xsl:variable>
        
        <xsl:for-each select="..[string-length(name())>0]">
            <xsl:call-template name="get-uri"/>
            <xsl:text> xigt:has_</xsl:text>
            <xsl:value-of select="$name"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="$me"/>
            <xsl:text>.&#10;</xsl:text>
        </xsl:for-each>
        
        <xsl:value-of select="$me"/>
        <xsl:text> a xigt:</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:apply-templates select="@*"/>
        
        <xsl:variable name="text">
            <xsl:if test="count(text()[1])&gt;0">
                <xsl:value-of select="string-join(text(),' ')"/>
            </xsl:if>
        </xsl:variable>
        
        <xsl:if test=" normalize-space($text)!=''">
            <xsl:text>;&#10;rdfs:label "</xsl:text>
            <xsl:value-of select="replace(replace(.,'&amp;','&amp;amp;'),'&quot;','&amp;quot;')"/>
            <xsl:text>"</xsl:text>
        </xsl:if>
        
        <xsl:for-each select="./following-sibling::*[name()=$name][1]">
            <xsl:text>;&#10;</xsl:text>
            <xsl:text>xigt:next </xsl:text>
            <xsl:call-template name="get-uri"/>
        </xsl:for-each>
        
        <xsl:text>.&#10;&#10;</xsl:text>
        <xsl:apply-templates/>
    </xsl:template>
    
    <!-- attributes, special treatment of some default attributes -->
    <xsl:template match="@*">
        <xsl:choose>
            <xsl:when test="name()='id'"/>  <!-- cf. URI -->
            <xsl:otherwise>                 <!-- datatype properties -->
                <xsl:text>;&#10;</xsl:text>
                <xsl:text>xigt:</xsl:text>
                <xsl:value-of select="name()"/>
                <xsl:text> "</xsl:text>
                <xsl:value-of select="replace(replace(.,'&amp;','&amp;amp;'),'&quot;','&amp;quot;')"/>
                <xsl:text>"</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="text()"/>
    
    <xsl:template name="get-uri">
        <xsl:variable name="name" select="name()"/>
        <xsl:choose>
            <xsl:when test="name()='xigt-corpus' and string-length(@id)=0">
                <xsl:text disable-output-escaping="yes">&lt;</xsl:text>
                <xsl:value-of select="$baseURI"/>
                <xsl:text disable-output-escaping="yes">&gt;</xsl:text>
            </xsl:when>
            <xsl:when test="string-length(@id)>0">
                <xsl:text>:</xsl:text>
                <xsl:value-of select="@id"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>:</xsl:text>
                <xsl:value-of select="$name"/>
                <xsl:text>_</xsl:text>
                <xsl:value-of select="count(./preceding::*[name()=$name]) + count(./ancestor-or-self::*[name()=$name])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
