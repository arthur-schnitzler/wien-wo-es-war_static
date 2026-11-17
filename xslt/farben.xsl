<?xml version="1.0" encoding="UTF-8"?>
<!-- Erzeugt html/css/farben.css: eine Klasse pro URI-Subtype (xslt/list-of-relevant-uris.xml)
     und pro Ereignisgruppe (data/indices/ereignistypen.xml aus config/ereignisgruppen.csv) -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="#all" version="3.0">
    <xsl:output method="text" encoding="UTF-8"/>
    <xsl:template match="/">
        <xsl:text>/* erzeugt von xslt/farben.xsl, nicht bearbeiten */&#10;</xsl:text>
        <xsl:for-each select="/list/item[color]">
            <xsl:text>.uri-</xsl:text>
            <xsl:value-of select="replace(abbr, '[^A-Za-z0-9_-]', '_')"/>
            <xsl:text> { background-color: </xsl:text>
            <xsl:value-of select="normalize-space(color)"/>
            <xsl:text>; color: </xsl:text>
            <xsl:value-of select="(textcolor/normalize-space(), '#ffffff')[1]"/>
            <xsl:text>; }&#10;</xsl:text>
        </xsl:for-each>
        <xsl:for-each select="doc('../data/indices/ereignistypen.xml')/ereignistypen/gruppe">
            <xsl:text>.gruppe-</xsl:text>
            <xsl:value-of select="@id"/>
            <xsl:text> { --gruppe-farbe: </xsl:text>
            <xsl:value-of select="@farbe"/>
            <xsl:text>; }&#10;</xsl:text>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>
