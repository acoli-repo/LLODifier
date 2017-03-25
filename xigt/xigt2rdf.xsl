<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"  xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0">

    <xsl:output method="text" indent="no"/>
    
    <!-- Xigt LLODifier -->
    <xsl:output method="text" indent="no"/>
    
    <xsl:param name="baseURI">http://example.org/PLEASE_PROVIDE_baseURI_PARAMETER</xsl:param>
    
    <xsl:variable name="DEBUG">false</xsl:variable>
    
    <xsl:template match="/">
        <!-- write TTL header -->
        <xsl:text>PREFIX xigt: &lt;https://github.com/xigt/xigt/wiki/Data-Model#&gt;&#10;</xsl:text>
        <xsl:text>PREFIX owl: &lt;http://www.w3.org/2002/07/owl#&gt;&#10;</xsl:text>
        <xsl:text>PREFIX rdfs: &lt;http://www.w3.org/2000/01/rdf-schema#&gt;&#10;</xsl:text>
        <xsl:text>PREFIX nif: &lt;http://persistence.uni-leipzig.org/nlp2rdf/ontologies/nif-core#&gt;&#10;</xsl:text>
        
        <!-- we preserve namespace bindings as PREFIXes to support interpretability of XML metadata -->
        <xsl:variable name="namespaces">
            <xsl:for-each select="//(*|@*)[contains(name(),':')]">
                    <xsl:sort select="substring-before(name(),':')"/>
                    <xsl:variable name="prefix" select="substring-before(name(),':')"/>
                    <xsl:if test="count(preceding::*[starts-with(name(),concat($prefix,':'))][1])=0 and
                        count(preceding::*/@*[starts-with(name(),concat($prefix,':'))][1])=0">
                        <xsl:value-of select="$prefix"/>
                        <xsl:text>=</xsl:text>
                        <xsl:value-of select="namespace-uri(.)"/>
                        <xsl:text> </xsl:text>
                    </xsl:if>                
                </xsl:for-each>
            </xsl:variable>
            <xsl:for-each select="tokenize(normalize-space($namespaces),' ')">
                    <xsl:text>PREFIX </xsl:text>
                    <xsl:value-of select="substring-before(.,'=')"/>
                    <xsl:text disable-output-escaping="yes">: &lt;</xsl:text>
                    <xsl:value-of select="substring-after(.,'=')"/>
                    <xsl:if test="not(matches(.,'.*[#/]$'))">
                        <xsl:text>#</xsl:text>
                    </xsl:if>
                    <xsl:text disable-output-escaping="yes">>&#10;</xsl:text>
            </xsl:for-each>
        
        <xsl:text>PREFIX : &lt;</xsl:text>
        <xsl:value-of select="$baseURI"/>
        <xsl:text>#&gt;&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
        
        <!-- RDFS schema information -->
        <xsl:text># RDFS schema information&#10;&#10;</xsl:text>
        <xsl:text>xigt:metadata rdfs:range xigt:Metadata.&#10;</xsl:text>
        <xsl:for-each select="//*[count(./ancestor-or-self::metadata[1])=0]/@type">
            <xsl:variable name="element" select="../name()"/>
            <xsl:variable name="type" select="."/>
            <xsl:if test="not(exists(./preceding::*[name()=$element and @type=$type]))">
                <xsl:text>xigt:</xsl:text>
                <xsl:value-of select="$type"/>
                <xsl:text>_</xsl:text>
                <xsl:value-of select="$element"/>
                <xsl:text> rdfs:subClassOf xigt:</xsl:text>
                <xsl:value-of select="name(..)"/>
                <xsl:text>; rdfs:label "</xsl:text>
                <xsl:value-of select="$type"/>
                <xsl:text>".&#10;</xsl:text>
            </xsl:if>
        </xsl:for-each>
        <xsl:text>&#10;</xsl:text>
        
        <!-- write TTL body -->
        <xsl:text># data&#10;&#10;</xsl:text>
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
                        <xsl:text>xigt:</xsl:text>
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
                <xsl:if test="count(*)&gt;0 or string-length(normalize-space(string-join(.,'')))&gt;0">
                <xsl:text> xigt:meta """</xsl:text>
                <xsl:call-template name="get-meta"/>                    
                <xsl:text>"""^^rdf:XMLLiteral ; </xsl:text>
                </xsl:if>
                <xsl:for-each select="@*[name()!='type' and name()!='id']">
                    <xsl:text>xigt:</xsl:text>
                    <xsl:value-of select="name()"/>
                    <xsl:text> </xsl:text>
                    <xsl:call-template name="guess-object-type"/>
                    <xsl:text>; </xsl:text>
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
        <xsl:if test="string-length(@type)&gt;0">
            <xsl:value-of select="@type"/>
            <xsl:text>_</xsl:text>
        </xsl:if>
        <xsl:value-of select="name()"/>
        <xsl:apply-templates select="@*"/>
        
        <xsl:variable name="text">
            <xsl:if test="count(text()[1])&gt;0">
                <xsl:value-of select="string-join(text(),' ')"/>
            </xsl:if>
        </xsl:variable>
        
        <xsl:if test=" normalize-space($text)!=''">
            <xsl:text>;&#10;xigt:text "</xsl:text>
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
    
    <!-- retrieve string representation, this is necessary because @segmentation may point to an element that has no textual content, but a @content attribute <br/>
        note that we do not check for cycles of @content links
    -->
    <xsl:template name="get-label">
        <xsl:param name="context"/>
        <xsl:variable name="result" select="string-join(.//text(),' ')"/>
        <xsl:if test="$DEBUG=true">
            <xsl:message>
                <xsl:text>get-label(</xsl:text>
                <xsl:value-of select="$context"/>
                <xsl:text>)=</xsl:text>
                <xsl:value-of select="$result"/>
            </xsl:message>
        </xsl:if>
        <xsl:value-of select="$result"/>
    </xsl:template>
    
    <!-- cf. https://github.com/xigt/xigt/wiki/Alignment-Expressions, called from an attribute -->
    <xsl:template name="resolve-alignment-expression">
        <xsl:param name="alignment"/>
        <xsl:param name="context"/>
        <xsl:if test="$DEBUG=true">
        <xsl:message>
            <xsl:text>resolve-alignment-expression(</xsl:text>
            <xsl:value-of select="$alignment"/>
            <xsl:text>)</xsl:text>
        </xsl:message>
        </xsl:if>
        <xsl:variable name="result">
        <xsl:choose>
            <xsl:when test="contains($alignment,']+')">
                <xsl:variable name="head" select="replace($alignment,'\]\+.*','\]')"/>
                <xsl:call-template name="resolve-alignment-expression">
                    <xsl:with-param name="alignment" select="$head"/>
                    <xsl:with-param name="context" select="$context"/>
                </xsl:call-template>
                <xsl:call-template name="resolve-alignment-expression">
                    <xsl:with-param name="alignment" select="substring-after($alignment,concat($head,'+'))"/>
                    <xsl:with-param name="context" select="$context"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="contains($alignment,'],')">
                <xsl:variable name="head" select="replace($alignment,'\],.*','\]')"/>
                <xsl:call-template name="resolve-alignment-expression">
                    <xsl:with-param name="alignment" select="$head"/>
                    <xsl:with-param name="context" select="$context"/>
                </xsl:call-template>
                <xsl:text> </xsl:text>
                <xsl:call-template name="resolve-alignment-expression">
                    <xsl:with-param name="alignment" select="substring-after($alignment,concat($head,','))"/>
                    <xsl:with-param name="context" select="$context"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="contains($alignment,',')">
                <xsl:call-template name="resolve-alignment-expression">
                    <xsl:with-param name="context" select="$context"/>
                    <xsl:with-param name="alignment" select="concat(substring-before($alignment,','),']')"/>
                </xsl:call-template>
                <xsl:text> </xsl:text>
                <xsl:call-template name="resolve-alignment-expression">
                    <xsl:with-param name="context" select="$context"/>
                    <xsl:with-param name="alignment" select="concat(substring-before($alignment,'['),substring-after($alignment,','))"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="contains($alignment,'+')">
                <xsl:call-template name="resolve-alignment-expression">
                    <xsl:with-param name="context" select="$context"/>
                    <xsl:with-param name="alignment" select="concat(substring-before($alignment,','),']')"/>
                </xsl:call-template>
                <xsl:call-template name="resolve-alignment-expression">
                    <xsl:with-param name="context" select="$context"/>
                    <xsl:with-param name="alignment" select="concat(substring-before($alignment,'['),substring-after($alignment,','))"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="contains($alignment,':')">
                <xsl:variable name="range" select="substring-before(substring-after($alignment,'['),']')"/>
                <xsl:variable name="start" select="number(substring-before($range,':'))" as="xs:double"/>
                <xsl:variable name="end" select="number(substring-after($range,':'))" as="xs:double"/>
                <xsl:variable name="label">
                    <xsl:for-each select="./ancestor-or-self::igt//*[@id=substring-before($alignment,'[')][1]">
                        <xsl:choose>
                            <xsl:when test="string-length(normalize-space(string-join(.//text(),' ')))>0">
                                <xsl:call-template name="get-label">
                                    <xsl:with-param name="context" select="$context"/>
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:when test="string-length(@content)>0">
                                <xsl:call-template name="resolve-alignment-expression">
                                    <xsl:with-param name="context" select="$context"/>
                                    <xsl:with-param name="alignment" select="@content"/>
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:when test="string-length(@segmentation)>0">
                                <xsl:call-template name="resolve-alignment-expression">
                                    <xsl:with-param name="context" select="$context"/>
                                    <xsl:with-param name="alignment" select="@segmentation"/>
                                </xsl:call-template>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:value-of select="substring($label,1+$start,$end - $start)"/>
            </xsl:when>
            <xsl:when test="exists(//item[@id=$alignment][string-length(normalize-space(string-join(.//text(),' ')))>0])">
                <xsl:for-each select="./ancestor-or-self::igt//*[@id=$alignment][1]">
                    <xsl:call-template name="get-label">
                        <xsl:with-param name="context" select="$context"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>
                    <xsl:text>cannot process resolve-alignment-expression(</xsl:text>
                    <xsl:value-of select="$alignment"/>
                    <xsl:text>)</xsl:text>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
        </xsl:variable>
        <xsl:if test="$DEBUG=true">
        <xsl:message>
            <xsl:text>resolve-alignment-expression(</xsl:text>
            <xsl:value-of select="$alignment"/>
            <xsl:text>)=</xsl:text>
            <xsl:value-of select="$result"/>
        </xsl:message>
        </xsl:if>
        <xsl:value-of select="$result"/>
    </xsl:template>
    
    <!-- attributes, special treatment of @id, @segmentation, @content, @type -->
    <xsl:template match="@*">
        <xsl:variable name="value" select="."/> 
        
        <!-- evaluate segmentation (> nif:subString) -->
        <xsl:if test="name()='segmentation'">
            <xsl:text>;&#10;</xsl:text>
            <xsl:text>nif:subString </xsl:text>
            <xsl:for-each select="./ancestor-or-self::igt//*[@id=replace($value,'\[.*\]','')][1]">
                <xsl:call-template name="get-uri"/>
            </xsl:for-each>
        </xsl:if>
        
        <!-- evaluate alignment expressions for content (> rdfs:label) -->
        <xsl:if test="(name()='content' or name()='segmentation') and ../name()='item'">
            <xsl:text>;&#10;</xsl:text>
            <xsl:text>rdfs:label "</xsl:text>
            <xsl:variable name="raw-label">
               <xsl:call-template name="resolve-alignment-expression">
                   <xsl:with-param name="context" select="."/>
                   <xsl:with-param name="alignment" select="."/>
               </xsl:call-template>
            </xsl:variable>
            <xsl:value-of select="replace(replace(
                    $raw-label,
                    '&amp;','&amp;amp;'),
                    '&quot;','&amp;quot;')"/>
            <xsl:text>"</xsl:text>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="name()='id' and name(..)='metadata'"/>          <!-- metadata: @id becomes URI, otherwise datatype property -->
            <xsl:when test="name()='segmentation' or name()='content'">     <!-- segmentation, content: always datatype properties, but see above -->
                <xsl:text>;&#10;xigt:</xsl:text>
                <xsl:value-of select="name()"/>
                <xsl:text> "</xsl:text>
                <xsl:value-of select="normalize-space(.)"/>
                <xsl:text>"</xsl:text>
            </xsl:when>
            <xsl:when test="name()='type'"/> <!-- processed with .. -->
            <xsl:otherwise>                 <!-- datatype properties -->
                <xsl:text>;&#10;</xsl:text>
                <xsl:text>xigt:</xsl:text>
                <xsl:value-of select="name()"/>
                <xsl:text> </xsl:text>
                <xsl:call-template name="guess-object-type"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="text()"/>
    
    <!-- Heuristic detection of object properties (slow):
        The generic XML data structre doesn't distinguish object and datatype properties, but we can guess that an 
         attribute is an object property if all its values are defined by @id <br/>
         This is called upon an xml attribute.
    -->
    <xsl:template name="guess-object-type">
        <xsl:param name="name" select="name()"/>
        <xsl:param name="value" select="."/>
        <xsl:variable name="document" select="/"/>
        <xsl:variable name="non-id-vals">
            <xsl:for-each select="//@*[name()=$name]">
                <xsl:for-each select="tokenize(.,'[, ]')">
                    <xsl:variable name="tmp" select="."/>
                    <xsl:if test="not(exists($document//@id[.=$tmp]))">
                        <xsl:value-of select="$tmp"/>
                        <xsl:text> </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$name='id' or string-length($non-id-vals)>0">
                <!-- applies only if @id is *not* transformed to a URI, hence a datatype property -->
                <xsl:text>"</xsl:text>
                <xsl:value-of select="replace(replace($value,'&amp;','&amp;amp;'),'&quot;','&amp;quot;')"/>
                <xsl:text>"</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="get-arg-uris">
                    <xsl:with-param name="arg" select="$value"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>        
    </xsl:template>
    
    <xsl:template name="get-arg-uris">
        <xsl:param name="arg"/>
        <xsl:variable name="narg" select="normalize-space($arg)"/>
        <xsl:choose>
            <xsl:when test="contains($narg,',')">
                <xsl:call-template name="get-arg-uris">
                    <xsl:with-param name="arg" select="substring-before($narg,',')"/>
                </xsl:call-template>
                <xsl:text>,</xsl:text>
                <xsl:call-template name="get-arg-uris">
                    <xsl:with-param name="arg" select="substring-after($narg,',')"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="contains($narg,' ')">
                <xsl:call-template name="get-arg-uris">
                    <xsl:with-param name="arg" select="substring-before($narg,' ')"/>
                </xsl:call-template>
                <xsl:text>,</xsl:text>
                <xsl:call-template name="get-arg-uris">
                    <xsl:with-param name="arg" select="substring-after($narg,' ')"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="local">
                    <xsl:for-each select="./ancestor-or-self::igt//*[@id=$narg][1]">
                        <xsl:call-template name="get-uri"/>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:variable name="global">
                    <xsl:for-each select="//*[@id=$narg][1]">
                        <xsl:call-template name="get-uri"/>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="$local!=''">
                        <xsl:value-of select="$local"/>
                    </xsl:when>
                    <xsl:when test="$global!=''">
                        <xsl:value-of select="$global"/>
                    </xsl:when>
                    <xsl:when test="$narg!=''">
                        <xsl:text>:</xsl:text>
                        <xsl:value-of select="$narg"/>
                        <xsl:message>
                            <xsl:text>warning: unresolved reference to </xsl:text>
                            <xsl:value-of select="$narg"/>
                        </xsl:message>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>""</xsl:text>
                        <xsl:message>warning: empty URI</xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>            
    
    <xsl:template name="get-uri">
        <xsl:variable name="name" select="name()"/>
        <xsl:choose>
            <xsl:when test="name()='xigt-corpus' and string-length(@id)=0">
                <xsl:text disable-output-escaping="yes">&lt;</xsl:text>
                <xsl:value-of select="$baseURI"/>
                <xsl:text disable-output-escaping="yes">&gt;</xsl:text>
            </xsl:when>
            <xsl:when test="string-length(@id)>0 and name()!='item' and name()!='tier'">   <!-- within an IGT, @id is not unique, hence a datatype property -->
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
    
    <!-- return content of meta elements and their descendants as text -->
    <xsl:template name="get-meta">
        <xsl:if test="exists(./ancestor-or-self::meta)">
            <xsl:for-each select="*|text()">
                <xsl:choose>
                    <xsl:when test="string-length(name())&gt;0">
                        <xsl:text disable-output-escaping="yes">&lt;</xsl:text>
                        <xsl:value-of select="name()"/>
                        <xsl:for-each select="@*">
                            <xsl:text> </xsl:text>
                            <xsl:value-of select="name()"/>
                            <xsl:text>="</xsl:text>
                            <xsl:value-of select="replace(replace(.,'&amp;','&amp;amp;'),'&quot;','&amp;quot;')"/>
                            <xsl:text>"</xsl:text>
                        </xsl:for-each>
                        <xsl:variable name="children">
                            <xsl:call-template name="get-meta"/>
                        </xsl:variable>
                        <xsl:choose>
                            <xsl:when test="string-length(normalize-space($children))&gt;0">
                                <xsl:text disable-output-escaping="yes">&gt;</xsl:text>
                                <xsl:value-of select="$children"></xsl:value-of>
                                <xsl:text disable-output-escaping="yes">&lt;/</xsl:text>
                                <xsl:value-of select="name()"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>/</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:text disable-output-escaping="yes">&gt;</xsl:text>
                    </xsl:when>
                    <xsl:otherwise> <!-- text/CDATA. Note that we normalize spaces -->
                        <xsl:value-of select="normalize-space(.)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:if>
        <!-- performs a deep XML copy -->
    </xsl:template>
</xsl:stylesheet>
