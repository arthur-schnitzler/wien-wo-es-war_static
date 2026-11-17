<?xml version="1.0" encoding="UTF-8"?>
<!-- Gemeinsames Gerüst der Register (Tabulator-Tabelle) und der Entitätsseiten -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="#all" version="3.0">

    <!-- Anzahl der Ereignisse einer Entität -->
    <xsl:function name="tei:ereignisse" as="xs:integer">
        <xsl:param name="entity" as="element()"/>
        <xsl:sequence select="count($entity/tei:noteGrp[@type = 'ereignisse']/tei:note)"/>
    </xsl:function>

    <xsl:template name="registerseite">
        <xsl:param name="titel" as="xs:string"/>
        <xsl:param name="einleitung"/>
        <xsl:param name="tabelle"/>
        <xsl:param name="vorher"/>
        <xsl:param name="skripte" as="element()*"/>
        <html class="h-100" lang="{$default_lang}">
            <head>
                <xsl:call-template name="html_head">
                    <xsl:with-param name="html_title" select="concat($titel, ' – ', $project_short_title)"/>
                </xsl:call-template>
                <link rel="stylesheet" href="vendor/tabulator-tables/css/tabulator_bootstrap5.min.css"/>
            </head>
            <body class="d-flex flex-column h-100">
                <xsl:call-template name="nav_bar"/>
                <main id="main" tabindex="-1" class="flex-shrink-0 flex-grow-1">
                    <div class="container-xxl py-3">
                        <h1>
                            <xsl:value-of select="$titel"/>
                        </h1>
                        <xsl:copy-of select="$einleitung"/>
                        <xsl:copy-of select="$vorher"/>
                        <xsl:copy-of select="$tabelle"/>
                    </div>
                </main>
                <xsl:call-template name="html_footer"/>
                <script src="vendor/tabulator-tables/js/tabulator.min.js"></script>
                <script src="js/register.js"></script>
                <xsl:copy-of select="$skripte"/>
            </body>
        </html>
    </xsl:template>

    <!-- Entitätsseite pmbNNNN.html: Layout aus entities.xsl, dazu „Im Kalender zeigen“ -->
    <xsl:template name="entitaetsseite">
        <xsl:param name="name" as="xs:string"/>
        <xsl:variable name="entity" select="."/>
        <xsl:result-document href="{@xml:id}.html">
            <html class="h-100" lang="{$default_lang}">
                <head>
                    <xsl:call-template name="html_head">
                        <xsl:with-param name="html_title" select="concat($name, ' – ', $project_short_title)"/>
                    </xsl:call-template>
                    <link rel="stylesheet" href="css/entities.css"/>
                    <script src="js/entity-tabs.js" defer="defer"></script>
                </head>
                <body class="d-flex flex-column h-100">
                    <xsl:call-template name="nav_bar"/>
                    <main id="main" tabindex="-1" class="flex-shrink-0 flex-grow-1">
                        <div class="container-xxl py-3">
                            <xsl:call-template name="kalender-knopf">
                                <xsl:with-param name="entity" select="$entity"/>
                            </xsl:call-template>
                            <xsl:apply-templates select="$entity"/>
                        </div>
                    </main>
                    <xsl:call-template name="html_footer"/>
                </body>
            </html>
        </xsl:result-document>
    </xsl:template>
</xsl:stylesheet>
