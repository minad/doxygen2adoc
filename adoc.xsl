<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="3.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:adoc="http://asciidoc.org/"
                expand-text="yes">

    <xsl:output method="text" indent="no"/>
    <xsl:strip-space elements="*"/>

    <xsl:function name="adoc:hl">
        <xsl:param name="s"/>
        <xsl:text>&lt;inline-highlight&gt;{$s}&lt;/inline-highlight&gt;</xsl:text>
    </xsl:function>

    <xsl:function name="adoc:trim">
        <xsl:param name="text"/>
        <xsl:value-of select="replace(replace($text, '&#10;&#10;+', '&#10;&#10;'), '^&#10;+|&#10;+$', '')"/>
    </xsl:function>

    <xsl:function name="adoc:item">
        <xsl:param name="text"/>
        <xsl:text>{replace(adoc:trim($text), '&#10;&#10;', '&#10;+&#10;')}&#10;</xsl:text>
    </xsl:function>

    <!-- Sanitize underscores in ids (See asciidoctor #2746) -->
    <xsl:function name="adoc:sanitize">
        <xsl:param name="id"/>
        <xsl:value-of select="replace($id, '__+', '_')"/>
    </xsl:function>

    <xsl:function name="adoc:id">
        <xsl:param name="id"/>
        <xsl:text>codedoc-{replace(adoc:sanitize($id), '_', '-')}</xsl:text>
    </xsl:function>

    <xsl:function name="adoc:ref">
        <xsl:param name="id"/>
        <xsl:param name="name"/>
        <xsl:text>&lt;&lt;{adoc:id($id)},{$name}&gt;&gt;</xsl:text>
    </xsl:function>

    <xsl:function name="adoc:refitem">
        <xsl:param name="id"/>
        <xsl:param name="name"/>
        <xsl:text>* {adoc:ref($id, $name)}&#10;</xsl:text>
    </xsl:function>

    <xsl:function name="adoc:anchor">
        <xsl:param name="id"/>
        <xsl:text>[[{adoc:id($id)}]]</xsl:text>
    </xsl:function>

    <xsl:function name="adoc:anchorline">
        <xsl:param name="id"/>
        <xsl:text>&#10;{adoc:anchor($id)}&#10;</xsl:text>
    </xsl:function>

    <xsl:template match="doxygen">
        <xsl:call-template name="groups"/>
        <xsl:choose>
            <xsl:when test="compounddef/@language='Java'">
                <xsl:text>&#10;= Interfaces&#10;</xsl:text>
                <xsl:apply-templates mode="java-class-link" select="compounddef[@kind='interface']"/>
                <xsl:apply-templates mode="java-class" select="compounddef[@kind='interface']"/>
                <xsl:text>&#10;= Classes&#10;</xsl:text>
                <xsl:apply-templates mode="java-class-link" select="compounddef[@kind='class']"/>
                <xsl:apply-templates mode="java-class" select="compounddef[@kind='class']"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates mode="c-dir" select="compounddef[@kind='dir' and not(contains(compoundname, '/'))]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="compounddef" mode="c-dir">
        <xsl:value-of select="adoc:anchorline(@id)"/>
        <xsl:choose>
            <xsl:when test="contains(compoundname, '/')">
                <xsl:text>== {compoundname}/&#10;&#10;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>= Files&#10;&#10;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:variable name="parentlen" select="string-length(compoundname)+2"/>
        <xsl:if test="count(innerdir)>0">
            <xsl:text>.Subdirectories&#10;</xsl:text>
            <xsl:for-each select="innerdir">
                <xsl:value-of select="adoc:refitem(@refid, substring(., $parentlen) || '/')"/>
            </xsl:for-each>
            <xsl:text>&#10;&#10;</xsl:text>
        </xsl:if>
        <xsl:if test="count(innerfile)>0">
            <xsl:text>.Files&#10;</xsl:text>
            <xsl:for-each select="innerfile">
                <xsl:value-of select="adoc:refitem(@refid, .)"/>
            </xsl:for-each>
            <xsl:text>&#10;&#10;</xsl:text>
        </xsl:if>
        <xsl:for-each select="innerdir">
            <xsl:apply-templates mode="c-dir" select="//compounddef[@id=current()/@refid]"/>
        </xsl:for-each>
        <xsl:for-each select="innerfile">
            <xsl:apply-templates mode="c-file" select="//compounddef[@id=current()/@refid]"/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="compounddef" mode="java-class-link">
        <xsl:text>* &lt;&lt;{adoc:id(@id)}, `*{@kind}* </xsl:text>
        <xsl:if test="@kind='interface'">_</xsl:if>
        <xsl:value-of select="substring-after(replace(compoundname, '::', '.'), '.')"/>
        <xsl:if test="@kind='interface'">_</xsl:if>
        <xsl:text>`&gt;&gt;&#10;</xsl:text>
    </xsl:template>

    <xsl:template match="compounddef" mode="java-class">
        <xsl:text>{adoc:anchorline(@id)}== {@kind} </xsl:text>
        <xsl:if test="@kind='interface'">_</xsl:if>
        <xsl:value-of select="substring-after(replace(compoundname, '::', '.'), '.')"/>
        <xsl:if test="@kind='interface'">_</xsl:if>
        <xsl:text>&#10;&#10;</xsl:text>
        <xsl:if test="count(basecompoundref)>0">
            <xsl:text>Inherits from </xsl:text>
            <xsl:for-each select="basecompoundref">
                <xsl:if test="position() > 1">, </xsl:if>
                <xsl:value-of select="if (@refid) then adoc:ref(@refid, substring-after(., '.')) else ."/>
            </xsl:for-each>
            <xsl:text>&#10;&#10;</xsl:text>
        </xsl:if>
        <xsl:if test="count(derivedcompoundref)>0">
            <xsl:text>Inherited by </xsl:text>
            <xsl:for-each select="derivedcompoundref">
                <xsl:if test="position() > 1">, </xsl:if>
                <xsl:value-of select="adoc:ref(@refid, substring-after(., '.'))"/>
            </xsl:for-each>
            <xsl:text>&#10;&#10;</xsl:text>
        </xsl:if>
        <xsl:call-template name="source-file-link"/>
        <xsl:apply-templates select="detaileddescription|briefdescription|inbodydescription"/>
        <xsl:call-template name="member-outline"/>
        <xsl:call-template name="member-descriptions"/>
    </xsl:template>

    <xsl:template name="c-struct">
        <xsl:param name="delimiter"/>
        <xsl:text>{adoc:anchorline(@id)}{$delimiter}&#10;</xsl:text>
        <xsl:call-template name="source-link"/>
        <xsl:value-of select="'`*' || @kind || '* ' || compoundname || '`'"/>
        <xsl:apply-templates select="detaileddescription|briefdescription|inbodydescription"/>
        <xsl:if test="count(*/memberdef[not(contains(type/ref, '::')) and not(starts-with(name, '_'))]) > 0">
            <xsl:text>&#10;.Fields&#10;</xsl:text>
            <!-- hidden fields start with '_' -->
            <xsl:for-each select="*/memberdef[not(contains(type/ref, '::')) and not(starts-with(name, '_'))]">
                <xsl:variable name="item">
                    <xsl:text>`</xsl:text>
                    <xsl:if test="type!=''">
                        <xsl:apply-templates select="type"/>
                        <xsl:text> </xsl:text>
                    </xsl:if>
                    <xsl:value-of select="name"/>
                    <xsl:value-of select="adoc:hl(argsstring)"/>
                    <xsl:text>`</xsl:text>
                    <xsl:apply-templates select="detaileddescription|briefdescription|inbodydescription"/>
                </xsl:variable>
                <xsl:text>* {adoc:anchor(@id)} {adoc:item($item)}</xsl:text>
            </xsl:for-each>
        </xsl:if>
        <xsl:text>&#10;&#10;</xsl:text>
        <xsl:for-each select="innerclass[ends-with(., '::__anonymous__')]">
            <xsl:call-template name="c-nested-struct">
                <xsl:with-param name="delimiter" select="$delimiter"/>
                <xsl:with-param name="nestedname" select="."/>
            </xsl:call-template>
        </xsl:for-each>
        <xsl:for-each select="*/memberdef[contains(type/ref, '::')]">
            <xsl:call-template name="c-nested-struct">
                <xsl:with-param name="delimiter" select="$delimiter"/>
                <xsl:with-param name="nestedname" select="type/ref"/>
            </xsl:call-template>
        </xsl:for-each>
        <xsl:text>{$delimiter}&#10;&#10;</xsl:text>
    </xsl:template>

    <xsl:template name="c-nested-struct">
        <xsl:param name="delimiter"/>
        <xsl:param name="nestedname"/>
        <xsl:for-each select="//compounddef[compoundname=$nestedname]">
            <xsl:call-template name="c-struct">
                <xsl:with-param name="delimiter" select="$delimiter || '='"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="compounddef" mode="c-file">
        <xsl:text>{adoc:anchorline(@id)}== {location/@file}&#10;&#10;</xsl:text>
        <xsl:call-template name="source-file-link"/>
        <xsl:apply-templates select="detaileddescription|briefdescription|inbodydescription"/>
        <xsl:if test="count(includes[@refid])>0">
            <xsl:text>.Includes&#10;</xsl:text>
            <xsl:for-each select="includes[@refid]">
                <xsl:value-of select="adoc:refitem(@refid, .)"/>
            </xsl:for-each>
            <xsl:text>&#10;&#10;</xsl:text>
        </xsl:if>
        <xsl:call-template name="c-member-outline"/>
        <xsl:if test="count(innerclass)>0">
            <xsl:text>*Structs and Unions*&#10;&#10;</xsl:text>
            <xsl:for-each select="innerclass">
                <xsl:for-each select="//compounddef[@id=current()/@refid and not(contains(compoundname, '::'))]">
                    <xsl:call-template name="c-struct">
                        <xsl:with-param name="delimiter" select="'===='"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:if>
        <xsl:call-template name="member-descriptions"/>
    </xsl:template>

    <xsl:template name="c-member-outline">
        <xsl:if test="count(innerclass)>0">
            <xsl:text>.Structs and Unions&#10;</xsl:text>
            <xsl:for-each select="innerclass">
                <xsl:for-each select="//compounddef[@id=current()/@refid and not(contains(compoundname, '::'))]">
                    <xsl:value-of select="adoc:refitem(@id, '`*' || @kind || '* ' || compoundname || '`')"/>
                </xsl:for-each>
            </xsl:for-each>
            <xsl:text>&#10;&#10;</xsl:text>
        </xsl:if>
        <xsl:call-template name="member-outline"/>
    </xsl:template>

    <xsl:template name="groups">
        <xsl:for-each select="compounddef[@kind='group']">
            <xsl:text>&#10;&#10;= {title}&#10;&#10;</xsl:text>
            <xsl:apply-templates select="detaileddescription|briefdescription|inbodydescription"/>
            <xsl:call-template name="c-member-outline"/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="member-descriptions">
        <xsl:for-each select="sectiondef">
            <xsl:choose>
                <xsl:when test="@kind='private-attrib'">*Private Fields*&#10;&#10;</xsl:when>
                <xsl:when test="@kind='public-attrib'">*Public Fields*&#10;&#10;</xsl:when>
                <xsl:when test="@kind='private-func'">*Private Functions*&#10;&#10;</xsl:when>
                <xsl:when test="@kind='public-func'">*Public Functions*&#10;&#10;</xsl:when>
                <xsl:when test="@kind='private-static-attrib'">*Private Static Fields*&#10;&#10;</xsl:when>
                <xsl:when test="@kind='public-static-attrib'">*Public Static Fields*&#10;&#10;</xsl:when>
                <xsl:when test="@kind='private-static-func'">*Private Static Functions*&#10;&#10;</xsl:when>
                <xsl:when test="@kind='public-static-func'">*Public Static Functions*&#10;&#10;</xsl:when>
                <xsl:when test="@kind='package-attrib'">*Package Fields*&#10;&#10;</xsl:when>
                <xsl:when test="@kind='package-func'">*Package Functions*&#10;&#10;</xsl:when>
                <xsl:when test="@kind='package-static-attrib'">*Package Static Fields*&#10;&#10;</xsl:when>
                <xsl:when test="@kind='package-static-func'">*Package Static Functions*&#10;&#10;</xsl:when>
                <xsl:when test="@kind='define'">*Macros*&#10;&#10;</xsl:when>
                <xsl:when test="@kind='enum'">*Enums*&#10;&#10;</xsl:when>
                <xsl:when test="@kind='typedef'">*Typedefs*&#10;&#10;</xsl:when>
                <xsl:when test="@kind='var'">*Variables*&#10;&#10;</xsl:when>
                <xsl:when test="@kind='func'">*Functions*&#10;&#10;</xsl:when>
            </xsl:choose>
            <xsl:apply-templates mode="member" select="memberdef"/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="member-outline">
	<xsl:if test="count(*/memberdef) > 1">
            <xsl:text>&#10;&#10;</xsl:text>
            <xsl:for-each select="sectiondef">
                <xsl:choose>
                    <xsl:when test="@kind='private-attrib'">&#10;.Private Fields&#10;</xsl:when>
                    <xsl:when test="@kind='private-func'">&#10;.Private Functions&#10;</xsl:when>
                    <xsl:when test="@kind='private-static-attrib'">&#10;.Private Static Fields&#10;</xsl:when>
                    <xsl:when test="@kind='private-static-func'">&#10;.Private Static Functions&#10;</xsl:when>
                    <xsl:when test="@kind='public-attrib'">&#10;.Public Fields&#10;</xsl:when>
                    <xsl:when test="@kind='public-func'">&#10;.Public Functions&#10;</xsl:when>
                    <xsl:when test="@kind='public-static-attrib'">&#10;.Public Static Fields&#10;</xsl:when>
                    <xsl:when test="@kind='public-static-func'">&#10;.Public Static Functions&#10;</xsl:when>
                    <xsl:when test="@kind='package-attrib'">&#10;.Package Fields&#10;</xsl:when>
                    <xsl:when test="@kind='package-func'">&#10;.Package Functions&#10;</xsl:when>
                    <xsl:when test="@kind='package-static-attrib'">&#10;.Package Static Fields&#10;</xsl:when>
                    <xsl:when test="@kind='package-static-func'">&#10;.Package Static Functions&#10;</xsl:when>
                    <xsl:when test="@kind='define'">&#10;.Macros&#10;</xsl:when>
                    <xsl:when test="@kind='enum'">&#10;.Enums&#10;</xsl:when>
                    <xsl:when test="@kind='typedef'">&#10;.Typedefs&#10;</xsl:when>
                    <xsl:when test="@kind='var'">&#10;.Variables&#10;</xsl:when>
                    <xsl:when test="@kind='func'">&#10;.Functions&#10;</xsl:when>
                </xsl:choose>
                <xsl:apply-templates mode="member-outline-item" select="memberdef"/>
            </xsl:for-each>
            <xsl:text>&#10;&#10;</xsl:text>
        </xsl:if>
    </xsl:template>

    <xsl:template match="memberdef" mode="member-outline-item">
        <xsl:variable name="item">
            <xsl:text>&lt;&lt;{adoc:id(@id)},`</xsl:text>
            <xsl:if test="type!=''">
                <xsl:text>{adoc:hl(replace(type, 'final ', ''))} </xsl:text>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="@kind='enum' and starts-with(name, '@')">__anonymous__</xsl:when>
                <xsl:otherwise><xsl:value-of select="name"/></xsl:otherwise>
            </xsl:choose>
            <xsl:value-of select="adoc:hl(argsstring)"/>
            <xsl:text>`</xsl:text>
            <xsl:text>&gt;&gt;</xsl:text>
        </xsl:variable>
        <xsl:text>* {adoc:item($item)}</xsl:text>
    </xsl:template>

    <xsl:template match="memberdef" mode="member">
        <xsl:text>{adoc:anchorline(@id)}====&#10;</xsl:text>
        <xsl:call-template name="source-link"/>
        <xsl:text>`</xsl:text>
        <xsl:if test="/doxygen/compounddef[1]/@language='Java'">
            <xsl:choose>
                <xsl:when test="@prot='public'">*public* </xsl:when>
                <xsl:when test="@prot='private'">*private* </xsl:when>
            </xsl:choose>
        </xsl:if>
        <xsl:if test="@static='yes'">*static* </xsl:if>
        <xsl:choose>
            <xsl:when test="@kind='define'">*#define* </xsl:when>
            <xsl:when test="@kind='typedef'">*typedef* </xsl:when>
            <xsl:when test="@kind='enum'">*enum* </xsl:when>
        </xsl:choose>
        <xsl:if test="type!=''">
            <xsl:apply-templates select="type"/>
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="@kind='enum' and starts-with(name, '@')">__anonymous__</xsl:when>
            <xsl:otherwise><xsl:value-of select="name"/></xsl:otherwise>
        </xsl:choose>
        <xsl:choose>
            <xsl:when test="@kind='typedef' or @kind='variable'">
	        <xsl:value-of select="adoc:hl(argsstring)"/>
            </xsl:when>
            <xsl:when test="@kind='define'">
                <xsl:if test="count(param) > 0">
                    <xsl:text>(</xsl:text>
                    <xsl:for-each select="param">
                        <xsl:if test="position() > 1">, </xsl:if>
                        <xsl:value-of select="defname"/>
                    </xsl:for-each>
                    <xsl:text>)</xsl:text>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="argsstring != ''">
                    <xsl:text>(</xsl:text>
                    <xsl:for-each select="param">
                        <xsl:if test="position() > 1">, </xsl:if>
                        <xsl:apply-templates select="type"/>
                        <xsl:if test="declname!=''">
                            <xsl:text> {declname}</xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:text>)</xsl:text>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>`</xsl:text>
        <xsl:apply-templates select="detaileddescription|briefdescription|inbodydescription"/>
        <xsl:if test="@kind='enum'">
            <xsl:text>.Enum values&#10;</xsl:text>
            <xsl:for-each select="enumvalue">
                <xsl:value-of select="'* ' || adoc:anchor(@id) || ' `' || name || '`&#10;'"/>
            </xsl:for-each>
        </xsl:if>
        <xsl:text>====&#10;&#10;</xsl:text>
    </xsl:template>

    <xsl:template match="type">
        <xsl:apply-templates select="*|text()" mode="type"/>
    </xsl:template>
    <xsl:template mode="type" match="ref">
        <xsl:value-of select="adoc:ref(@refid, .)"/>
    </xsl:template>
    <xsl:template mode="type" match="text()">
	<xsl:value-of select="adoc:hl(.)"/>
    </xsl:template>

    <xsl:template match="detaileddescription|briefdescription|inbodydescription">
        <xsl:text>&#10;&#10;</xsl:text>
        <xsl:apply-templates select="*|text()" mode="description"/>
        <xsl:text>&#10;&#10;</xsl:text>
    </xsl:template>
    <xsl:template mode="description" match="linebreak">
        <xsl:text>&#10;</xsl:text>
    </xsl:template>
    <xsl:template mode="description" match="computeroutput">
        <xsl:text>`</xsl:text>
        <xsl:apply-templates mode="description"/>
        <xsl:text>`</xsl:text>
    </xsl:template>
    <xsl:template mode="description" match="bold">
        <xsl:text>*</xsl:text>
        <xsl:apply-templates mode="description"/>
        <xsl:text>*</xsl:text>
    </xsl:template>
    <xsl:template mode="description" match="emphasis">
        <xsl:text>_</xsl:text>
        <xsl:apply-templates mode="description"/>
        <xsl:text>_</xsl:text>
    </xsl:template>
    <xsl:template mode="description" match="para">
        <xsl:text>&#10;</xsl:text>
        <xsl:apply-templates mode="description"/>
        <xsl:text>&#10;</xsl:text>
    </xsl:template>
    <xsl:template mode="description" match="image">
        <xsl:text>image::</xsl:text>
        <xsl:value-of select="@name"/>
        <xsl:text>[]&#10;</xsl:text>
    </xsl:template>
    <xsl:template mode="description" match="verbatim">
        <xsl:text>&#10;&#10;....&#10;{.}&#10;....&#10;&#10;</xsl:text>
    </xsl:template>
    <xsl:template mode="description" match="parameterlist">
        <xsl:text>.Parameters&#10;</xsl:text>
        <xsl:apply-templates mode="description"/>
    </xsl:template>
    <xsl:template mode="description" match="parametername">
        <xsl:text>. </xsl:text>
        <xsl:apply-templates mode="description"/>
        <xsl:text> - </xsl:text>
    </xsl:template>
    <xsl:template mode="description" match="simplesect[@kind='return']">
        <xsl:text>&#10;.Return</xsl:text>
        <xsl:apply-templates mode="description"/>
    </xsl:template>
    <xsl:template mode="description" match="simplesect[@kind='see']">
        <xsl:if test="position()=1">&#10;.See&#10;</xsl:if>
        <xsl:variable name="item"><xsl:apply-templates mode="description"/></xsl:variable>
        <xsl:text>* {adoc:item($item)}</xsl:text>
    </xsl:template>
    <xsl:template mode="description" match="simplesect[@kind='note' or @kind='warning']">
        <xsl:choose>
            <xsl:when test="@kind='note'">[NOTE]&#10;</xsl:when>
            <xsl:when test="@kind='warning'">[WARNING]&#10;</xsl:when>
        </xsl:choose>
        <xsl:variable name="item">
            <xsl:apply-templates mode="description"/>
        </xsl:variable>
        <xsl:value-of select="adoc:item($item)"/>
    </xsl:template>
    <xsl:template mode="description" match="ref">
        <xsl:value-of select="adoc:ref(@refid, .)"/>
    </xsl:template>
    <xsl:template mode="description" match="listitem">
        <xsl:choose>
            <xsl:when test="name(..)='itemizedlist'">* </xsl:when>
            <xsl:otherwise>. </xsl:otherwise>
        </xsl:choose>
        <xsl:variable name="item">
            <xsl:apply-templates mode="description"/>
        </xsl:variable>
        <xsl:value-of select="adoc:item($item)"/>
    </xsl:template>
    <xsl:template mode="description" match="text()">
        <xsl:value-of select="."/>
    </xsl:template>

    <xsl:template name="source-file-link">
        <!--
        <xsl:text>Jump to link:src/{location/@file}.html#line-{location/@line}[source file,window="browse-source"]&#10;&#10;</xsl:text>
        -->
    </xsl:template>

    <xsl:template name="source-link">
        <!--
        <xsl:text>&#10;&#10;</xsl:text>
        <xsl:text>[.right.small]#Jump to </xsl:text>
        <xsl:choose>
            <xsl:when test="not(location/@bodyfile) or (location/@file = location/@bodyfile and location/@line = location/@bodystart)">
                <xsl:text>link:src/{location/@file}.html#line-{location/@line}[definition,window="browse-source"]</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>link:src/{location/@file}.html#line-{location/@line}[declaration,window="browse-source"]</xsl:text>
                <xsl:text> or link:src/{location/@bodyfile}.html#line-{location/@bodystart}[definition,window="browse-source"]</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>#&#10;</xsl:text>
        -->
    </xsl:template>

    <!-- Debugging -->
    <xsl:template match="*">
        <xsl:message terminate="yes">
            Unmatched element {.}
            Child of {..}
        </xsl:message>
    </xsl:template>
</xsl:stylesheet>
