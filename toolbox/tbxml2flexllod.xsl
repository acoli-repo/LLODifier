<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">

    <!-- Toolbox LLODifier based on the FLEx ITG LLODifier vocabulary -->
    <xsl:output method="text" indent="no"/>
    
    <!-- we only support transforming local files, conversion to resolvable URIs must be implemented via SPARQL update -->
    <xsl:variable name="baseURI" select="concat('file:',/tbxml/@src)"/>
    
    <xsl:template match="/">
        <!-- write TTL header -->
        <xsl:text>PREFIX flex: &lt;http://fieldworks.sil.org/flex/interlinear/&gt;&#10;</xsl:text> 
            <!-- this is only an informative site, the actual xsd schema is not online accessible, but available only within a package -->
        <xsl:text>PREFIX toolbox: &lt;http://www-01.sil.org/computing/toolbox/&gt;&#10;</xsl:text>
            <!-- markers become toolbox properties --> 
        <xsl:text>PREFIX owl: &lt;http://www.w3.org/2002/07/owl#&gt;&#10;</xsl:text>    <!-- we use owl:sameAs for media/@location as this has to be a URI -->
        <xsl:text>PREFIX rdfs: &lt;http://www.w3.org/2000/01/rdf-schema#&gt;&#10;</xsl:text>
        <xsl:text>PREFIX : &lt;</xsl:text>
        <xsl:value-of select="$baseURI"/>
        <xsl:text>#&gt;&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
        
        <!-- write TTL body -->
        <xsl:apply-templates select="/tbxml"/>
    </xsl:template>
    
    <!-- flex:document, flex:interlinear-text and flex:paragraph --> 
    <xsl:template match="tbxml">
        <xsl:text disable-output-escaping="yes">&lt;</xsl:text>
        <xsl:value-of select="$baseURI"/>
        <xsl:text disable-output-escaping="yes">></xsl:text>
        <xsl:text> a flex:document</xsl:text>
        <xsl:text>;&#10; flex:has_interlinear-text _:interlinear-text</xsl:text>
        <xsl:text>.&#10;&#10;</xsl:text>
        
        <xsl:text>_:interlinear-text a flex:interlinear-text;</xsl:text>
        <xsl:for-each select="div[1]/line[normalize-space(string-join(.//text(),''))!='']">
            <xsl:text>;&#10; </xsl:text>
            <xsl:choose>
                <xsl:when test="string-length(@type)>0">
                    <xsl:text>toolbox:</xsl:text>
                    <xsl:value-of select="@type"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>rdfs:comment</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text> "</xsl:text>
            <xsl:value-of select="replace(replace(string-join(./(seg|sep)/text(),''),'&amp;','&amp;amp;'),'&quot;','&amp;quot;')"/>
            <xsl:text>"</xsl:text>
        </xsl:for-each>
        <xsl:text>.&#10;&#10;</xsl:text>
        
        <!-- we omit flex:paragraph -->
        
        <xsl:apply-templates/>
    </xsl:template>
    
    <!-- flex:phrase, only the first is metadata -->
    <xsl:template match="div[position()>1]">
        <xsl:text>&#10;_:interlinear-text flex:has_phrase :</xsl:text>
        <xsl:call-template name="get-id"/>
        <xsl:text>. :</xsl:text>
        <xsl:call-template name="get-id"/>
        <xsl:text> a flex:phrase</xsl:text>
        <xsl:for-each select="./following-sibling::div[1]">
            <xsl:text>; flex:next_phrase :</xsl:text>
            <xsl:call-template name="get-id"/>
        </xsl:for-each>        
        <xsl:text>.&#10;</xsl:text>
        
        <xsl:apply-templates/>
    </xsl:template>

    <!-- flex:phrase properties or subsegments -->
    <xsl:template match="line">
        <xsl:variable name="type" select="@type"/>
        <xsl:variable name="segs" select="count(seg)"/>
        
        <xsl:choose>
            <xsl:when test="count(seg[1])=0"/>
            
            <!-- attributes of flex:phrase: 
                    (a) a few hard-wired types
                    (b) most annotations have some multiple whitespaces in it, if it doesn't, it is likely to be a phrase attribute *if* if there is no following line with the same segmentation -->
            <xsl:when test="@type='nt' or 
                    (count(sep[string-length(text())>1][1])=0 and count(./following-sibling::line[1]/seg)!=$segs)">
                <xsl:text>:</xsl:text>
                <xsl:for-each select="..">
                    <xsl:call-template name="get-id"/>
                </xsl:for-each>
                <xsl:text> </xsl:text>
                <xsl:choose>
                    <xsl:when test="@type!=''">
                        <xsl:text>toolbox:</xsl:text>
                        <xsl:value-of select="@type"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>rdfs:comment</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:text> "</xsl:text>
                <xsl:value-of select="replace(replace(normalize-space(string-join(seg/text(),' ')),'&amp;','&amp;amp;'),'&quot;','&amp;quot;')"/>
                <xsl:text>".&#10;</xsl:text>
            </xsl:when>
            <!-- otherwise: subsegments -->
            
            <!-- if the last sibling of the same type is not preceded by a multi-space annotation, consider this a flex:word -->
            <xsl:when test="count(../line[@type=$type][1]/preceding-sibling::line/sep[string-length(text())>1])=0">
                <xsl:for-each select="seg">
                    <xsl:text>:</xsl:text>
                    <xsl:for-each select="..">
                        <xsl:call-template name="get-id"/>
                    </xsl:for-each>
                    <xsl:text> flex:has_word :</xsl:text>
                    <xsl:call-template name="get-id"/>
                    <xsl:text>. </xsl:text>
                    <xsl:text>:</xsl:text>
                    <xsl:call-template name="get-id"/>
                    <xsl:text> a flex:word</xsl:text>
                    <xsl:text>; </xsl:text>
                    <xsl:choose>
                        <xsl:when test="$type!=''">
                            <xsl:text>toolbox:</xsl:text>
                            <xsl:value-of select="$type"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>rdfs:comment</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:text> "</xsl:text>
                    <xsl:value-of select="replace(replace(string-join(text(),' '),'&amp;','&amp;amp;'),'&quot;','&amp;quot;')"/>
                    <xsl:text>"</xsl:text>
                    <xsl:for-each select="(following-sibling::seg|../following-sibling::line[@type=$type]/seg)[1]">
                        <xsl:text>; flex:next_word :</xsl:text>
                        <xsl:call-template name="get-id"/>
                    </xsl:for-each>
                    <xsl:text>.&#10;</xsl:text>        
                </xsl:for-each>
                <xsl:text>&#10;</xsl:text>
            </xsl:when>
            
            <!-- if the last line has the same granularity, is just a datatype property -->
            <xsl:when test="count(./preceding-sibling::line[1]/seg)=count(seg)">
                <xsl:for-each select="seg">
                    <xsl:text>:</xsl:text>
                    <xsl:call-template name="get-id"/>
                    <xsl:text> </xsl:text>
                    <xsl:choose>
                        <xsl:when test="../@type!=''">
                            <xsl:text>toolbox:</xsl:text>
                            <xsl:value-of select="../@type"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>rdfs:comment</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:text> "</xsl:text>
                    <xsl:value-of select="replace(replace(string-join(text(),' '),'&amp;','&amp;amp;'),'&quot;','&amp;quot;')"/>
                    <xsl:text>".&#10;</xsl:text>
                </xsl:for-each>
                <xsl:text>&#10;</xsl:text>
            </xsl:when>
            
            <!-- if any preceding line has higher granularity, this can only mean that the segmented part of the gloss is done, then do a datatype property of the flex:phrase -->
            <xsl:when test="exists(../line[@type=$type][1]/preceding-sibling::line[count(seg)>number($segs)])">
                <xsl:text>:</xsl:text>
                <xsl:for-each select="..">
                    <xsl:call-template name="get-id"/>
                </xsl:for-each>
                <xsl:text> </xsl:text>
                <xsl:choose>
                    <xsl:when test="@type!=''">
                        <xsl:text>toolbox:</xsl:text>
                        <xsl:value-of select="@type"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>rdfs:comment</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:text> "</xsl:text>
                <xsl:value-of select="replace(replace(normalize-space(string-join(seg/text(),' ')),'&amp;','&amp;amp;'),'&quot;','&amp;quot;')"/>
                <xsl:text>".&#10;</xsl:text>
            </xsl:when>
                
            <!-- otherwise (if the last line has lower granularity), consider this a morph --> 
            <xsl:otherwise>
                <xsl:for-each select="seg">
                    <!-- TODO: link with flex:word, here: with flex:phrase --> 
                    <xsl:text>:</xsl:text>
                    <xsl:for-each select="..">
                        <xsl:call-template name="get-id"/>
                    </xsl:for-each>
                    <xsl:text> toolbox:has_morph :</xsl:text>
                    <xsl:call-template name="get-id"/>
                    <xsl:text>. </xsl:text>
                    <xsl:text>:</xsl:text>
                    <xsl:call-template name="get-id"/>
                    <xsl:text> a flex:morph</xsl:text>
                    <xsl:text>; </xsl:text>
                    <xsl:choose>
                        <xsl:when test="$type!=''">
                            <xsl:text>toolbox:</xsl:text>
                            <xsl:value-of select="$type"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>rdfs:comment</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:text> "</xsl:text>
                    <xsl:value-of select="replace(replace(string-join(text(),' '),'&amp;','&amp;amp;'),'&quot;','&amp;quot;')"/>
                    <xsl:text>"</xsl:text>
                    <xsl:for-each select="(following-sibling::seg|../following-sibling::line[@type=$type]/seg)[1]">
                        <xsl:text>; flex:next_morph :</xsl:text>
                        <xsl:call-template name="get-id"/>
                    </xsl:for-each>
                    <xsl:text>.&#10;</xsl:text>        
                </xsl:for-each>
                <xsl:text>&#10;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- flex:word or flex:morph -->
    <xsl:template match="seg">
        <xsl:text>:</xsl:text>
        <xsl:call-template name="get-id"/>
        <xsl:text> a </xsl:text>
        <xsl:value-of select="../@type"/>
        <xsl:text>.&#10;&#10;</xsl:text>
        
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="*"/>
    
    <!-- local name for divs and segs, naming scheme follows TIGER -->
    <xsl:template name="get-id">
        <xsl:variable name="type" select="@type"/>
        <xsl:text>s</xsl:text>
        <xsl:value-of select="count(./preceding::div)+count(./ancestor-or-self::div)-1"/>
        <xsl:if test="name()='seg'">
            <xsl:variable name="siblings" select="count(../seg)"/>
            <xsl:variable name="basesegment" select="(../../line[string-length(@type)>0 and count(seg)=$siblings])[1]/@type"/>
                <!-- basesegment is the first line in the IGT that has the same number of segments -->
            <xsl:text>_</xsl:text>
            <xsl:value-of select="$basesegment"/>
            <xsl:value-of select="count(./preceding-sibling::seg)+count(../preceding-sibling::line[@type=$type]/seg)+1"/>
        </xsl:if>
    </xsl:template>

    <xsl:template match="text()"/>
    
</xsl:stylesheet>
