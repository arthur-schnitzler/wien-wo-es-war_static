<?xml version="1.0" encoding="UTF-8"?>
<!-- GND-BEACON: https://de.wikipedia.org/wiki/Wikipedia:BEACON -->
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="#all"
    version="2.0">
    <xsl:import href="./partials/params.xsl"/>
    <xsl:output method="text" media-type="text/plain" encoding="UTF-8"/>
    <xsl:template match="/">
        <xsl:text>#FORMAT: BEACON&#xa;</xsl:text>
        <xsl:text>#PREFIX: https://d-nb.info/gnd/&#xa;</xsl:text>
        <xsl:text>#TARGET: </xsl:text>
        <xsl:value-of select="$base_url"/>
        <xsl:text>/{ID}&#xa;</xsl:text>
        <xsl:text>#NAME: </xsl:text>
        <xsl:value-of select="$project_title"/>
        <xsl:text>&#xa;</xsl:text>
        <xsl:for-each select="//tei:person[@xml:id][tei:idno[@subtype = 'gnd']]">
            <xsl:value-of select="replace(normalize-space(tei:idno[@subtype = 'gnd'][1]), '^https?://d-nb\.info/gnd/([^/]+).*$', '$1')"/>
            <xsl:text>||</xsl:text>
            <xsl:value-of select="@xml:id"/>
            <xsl:text>.html&#xa;</xsl:text>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>
