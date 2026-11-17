<?xml version="1.0" encoding="UTF-8"?>
<!-- Facettensuche (PLANUNG.md, Abschnitt 8); js/search.js baut die Oberfläche -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="#all" version="3.0">
    <xsl:import href="./partials/html_head.xsl"/>
    <xsl:import href="./partials/html_navbar.xsl"/>
    <xsl:import href="./partials/html_footer.xsl"/>
    <xsl:import href="./partials/typesense_libs.xsl"/>
    <xsl:output encoding="UTF-8" media-type="text/html" method="html" version="5.0" indent="yes" omit-xml-declaration="yes"/>

    <xsl:template match="/">
        <html class="h-100" lang="{$default_lang}">
            <head>
                <xsl:call-template name="html_head">
                    <xsl:with-param name="html_title" select="concat('Suche – ', $project_short_title)"/>
                </xsl:call-template>
                <link rel="stylesheet" href="css/kalender.css"/>
                <link rel="stylesheet" href="css/search.css"/>
            </head>
            <body class="d-flex flex-column h-100">
                <xsl:call-template name="nav_bar"/>
                <main id="main" tabindex="-1" class="flex-shrink-0 flex-grow-1">
                    <div class="container-xxl py-3">
                        <h1>Suche</h1>
                        <p class="text-body-secondary">Alle Ereignisse <xsl:value-of select="$start-year"/>–<xsl:value-of select="$end-year"/>, durchsuchbar nach Werk, Person, Ort und Institution. Für den Einstieg über ein Datum gibt es den <a href="kalender.html">Kalender</a>.</p>
                        <div id="suche-fehler" class="alert alert-warning" hidden="hidden">Die Suche ist gerade nicht erreichbar. Der <a href="kalender.html">Kalender</a> und die <a href="jahre.html">Jahresübersicht</a> funktionieren ohne sie.</div>
                        <noscript><p>Die Suche braucht JavaScript. Ohne JavaScript führt die <a href="jahre.html">Jahresübersicht</a> zu jedem Tag.</p></noscript>
                        <div class="d-flex flex-wrap gap-2 align-items-center mb-2">
                            <div id="searchbox" class="flex-grow-1"></div>
                            <div id="sort-by"></div>
                        </div>
                        <div class="d-flex flex-wrap gap-2 align-items-center mb-3">
                            <div id="stats-container" class="fw-semibold"></div>
                            <div id="current-refinements"></div>
                            <div id="clear-refinements"></div>
                        </div>
                        <div class="row g-4">
                            <aside class="col-md-4 col-lg-3 suche-facetten" aria-label="Filter">
                                <div id="rf-jahr"></div>
                                <div id="rf-gruppe"></div>
                                <div id="rf-orte"></div>
                                <div id="rf-werke"></div>
                                <div id="rf-urheber"></div>
                                <div id="rf-personen"></div>
                                <div id="rf-institutionen"></div>
                                <div id="rf-typ"></div>
                                <div id="rf-quellen"></div>
                            </aside>
                            <section class="col-md-8 col-lg-9" aria-label="Treffer">
                                <div id="hits"></div>
                                <div id="pagination" class="mt-3"></div>
                            </section>
                        </div>
                    </div>
                </main>
                <xsl:call-template name="html_footer"/>
                <xsl:call-template name="typesense_libs"/>
                <script src="js/search.js"></script>
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
