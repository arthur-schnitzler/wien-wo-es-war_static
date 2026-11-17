<?xml version="1.0" encoding="UTF-8"?>
<!-- Startseite. Eingabe: data/indices/tage.xml (von pyscripts/prepare_data.py) -->
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    version="2.0"
    exclude-result-prefixes="#all">

    <xsl:import href="./partials/html_head.xsl"/>
    <xsl:import href="./partials/html_navbar.xsl"/>
    <xsl:import href="./partials/html_footer.xsl"/>
    <xsl:import href="./partials/one_time_alert.xsl"/>
    <xsl:import href="./partials/zotero.xsl"/>
    <xsl:output encoding="UTF-8" media-type="text/html" method="html" version="5.0" indent="yes" omit-xml-declaration="yes"/>

    <xsl:variable name="indices" select="'../data/indices/'"/>

    <xsl:template name="zahl">
        <xsl:param name="wert" as="xs:integer"/>
        <xsl:param name="label"/>
        <xsl:param name="href" select="()"/>
        <div class="col-6 col-md">
            <div class="border rounded p-3 h-100 text-center">
                <div class="fs-3 fw-semibold">
                    <xsl:value-of select="format-number($wert, '#.###', 'de')"/>
                </div>
                <div>
                    <xsl:choose>
                        <xsl:when test="$href">
                            <a href="{$href}"><xsl:value-of select="$label"/></a>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$label"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </div>
            </div>
        </div>
    </xsl:template>

    <xsl:decimal-format name="de" decimal-separator="," grouping-separator="."/>

    <xsl:template match="/">
        <xsl:variable name="doc_title" select="'Wohin in Wien damals?'"/>
        <html class="h-100" lang="{$default_lang}">
            <head>
                <xsl:call-template name="html_head">
                    <xsl:with-param name="html_title" select="$project_title"/>
                </xsl:call-template>
                <xsl:call-template name="zoterMetaTags"/>
            </head>
            <body class="d-flex flex-column h-100">
                <xsl:call-template name="nav_bar"/>
                <main id="main" tabindex="-1" class="flex-shrink-0 flex-grow-1">
                    <div class="container py-4">
                        <xsl:call-template name="one_time_alert"/>
                        <h1><xsl:value-of select="$doc_title"/></h1>
                        <p class="lead">
                            <xsl:text>Kulturelle Ereignisse in Wien </xsl:text>
                            <xsl:value-of select="$start-year"/>
                            <xsl:text>–</xsl:text>
                            <xsl:value-of select="$end-year"/>
                            <xsl:text>: Theater, Oper, Konzerte, Lesungen, Bälle, Kino und mehr, Tag für Tag.</xsl:text>
                        </p>

                        <h2 class="visually-hidden">Bestand</h2>
                        <div class="row g-3 my-3">
                            <xsl:call-template name="zahl">
                                <xsl:with-param name="wert" select="xs:integer(sum(/tage/tag/@n))"/>
                                <xsl:with-param name="label" select="'Ereignisse'"/>
                                <xsl:with-param name="href" select="'kalender.html'"/>
                            </xsl:call-template>
                            <xsl:call-template name="zahl">
                                <xsl:with-param name="wert" select="count(/tage/tag)"/>
                                <xsl:with-param name="label" select="'Tage'"/>
                                <xsl:with-param name="href" select="'kalender.html'"/>
                            </xsl:call-template>
                            <xsl:call-template name="zahl">
                                <xsl:with-param name="wert" select="count(doc(concat($indices, 'listplace.xml'))//tei:place[@xml:id])"/>
                                <xsl:with-param name="label" select="'Orte'"/>
                                <xsl:with-param name="href" select="'listplace.html'"/>
                            </xsl:call-template>
                            <xsl:call-template name="zahl">
                                <xsl:with-param name="wert" select="count(doc(concat($indices, 'listbibl.xml'))//tei:bibl[@xml:id])"/>
                                <xsl:with-param name="label" select="'Werke'"/>
                                <xsl:with-param name="href" select="'listbibl.html'"/>
                            </xsl:call-template>
                            <xsl:call-template name="zahl">
                                <xsl:with-param name="wert" select="count(doc(concat($indices, 'listperson.xml'))//tei:person[@xml:id])"/>
                                <xsl:with-param name="label" select="'Personen'"/>
                                <xsl:with-param name="href" select="'listperson.html'"/>
                            </xsl:call-template>
                            <xsl:call-template name="zahl">
                                <xsl:with-param name="wert" select="count(doc(concat($indices, 'listorg.xml'))//tei:org[@xml:id])"/>
                                <xsl:with-param name="label" select="'Institutionen'"/>
                                <xsl:with-param name="href" select="'listorg.html'"/>
                            </xsl:call-template>
                        </div>

                        <h2 class="fs-4 mt-4">Einstiege</h2>
                        <ul>
                            <li><a href="kalender.html">Kalender</a> – jeder Tag von <xsl:value-of select="$start-year"/> bis <xsl:value-of select="$end-year"/></li>
                            <li><a href="search.html">Suche</a> nach Werken, Personen, Orten und Ereignistypen</li>
                            <li>Register: <a href="listperson.html">Personen</a>, <a href="listplace.html">Orte</a>, <a href="listbibl.html">Werke</a>, <a href="listorg.html">Institutionen</a></li>
                        </ul>

                        <h2 class="fs-4 mt-4">Quellen</h2>
                        <p>
                            <xsl:text>Die Daten stammen aus dem </xsl:text>
                            <a href="https://kulturerbe.burgtheater.at">Burgtheater (Kulturerbe digital)</a>
                            <xsl:text>, dem </xsl:text>
                            <a href="https://www.mdw.ac.at/imi/operapolitics/spielplan-wiener-oper/web/">Spielplan der Wiener Oper</a>
                            <xsl:text>, </xsl:text>
                            <a href="https://schnitzler-kultur.acdh.oeaw.ac.at">Schnitzler: Kulturveranstaltungen</a>
                            <xsl:text>, </xsl:text>
                            <a href="https://brahms-online.oeaw.ac.at">Brahms online</a>
                            <xsl:text> und weiteren Projekten. Zusammengeführt werden sie in der </xsl:text>
                            <a href="https://pmb.acdh.oeaw.ac.at">PMB – Personen der Moderne Basis</a>
                            <xsl:text>. Mehr unter </xsl:text>
                            <a href="quellen.html">Quellen</a>
                            <xsl:text>.</xsl:text>
                        </p>
                    </div>
                </main>
                <xsl:call-template name="html_footer"/>
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
