<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="#all"
    version="2.0">
    <xsl:include href="./params.xsl"/>
    <xsl:template name="html_head">
        <xsl:param name="html_title" select="$project_short_title"></xsl:param>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="icon" href="images/symbol-32.png" sizes="32x32" type="image/png" />
        <link rel="icon" href="images/symbol-64.png" sizes="64x64" type="image/png" />
        <link rel="apple-touch-icon" href="images/symbol-180.png" />
        <title><xsl:value-of select="$html_title"/></title>
        <xsl:if test="$noindex">
            <meta name="robots" content="noindex, nofollow"/>
        </xsl:if>

        <!-- <link rel="canonical" href="{$base_url}" /> -->
        <meta name="description" content="{$project_title}" />
        
        <meta property="og:type" content="website" />
        <meta property="og:title" content="{$project_short_title}" />
        <meta property="og:description" content="{$project_title}" />
        <!-- <meta property="og:url" content="{$base_url}" /> -->
        <meta property="og:site_name" content="{$project_short_title}" />
        <meta property="og:image" content="{$base_url}/{$project_logo}" />
        <meta property="og:image:width" content="1260" />
        <meta property="og:image:height" content="664" />
        <meta property="og:image:alt" content="Logo: die Wiener Secession, daneben der Schriftzug Wohin in Wien damals, 1860–1939" />

        <link href="vendor/bootstrap-5.3.5-dist/css/bootstrap.min.css" rel="stylesheet"/>
        <link rel="stylesheet" href="vendor/bootstrap-icons/font/bootstrap-icons.min.css" />
        <link rel="stylesheet" href="css/style.css" type="text/css"></link>
        <link rel="stylesheet" href="css/farben.css" type="text/css"></link>
        
        
    </xsl:template>
</xsl:stylesheet>