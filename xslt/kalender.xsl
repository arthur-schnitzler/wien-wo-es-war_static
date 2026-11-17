<?xml version="1.0" encoding="UTF-8"?>
<!-- Kalender (PLANUNG.md, Abschnitt 5). Die Seite ist ein Gerüst, js/calendar.js baut den Kalender. -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="#all" version="3.0">

    <xsl:import href="./partials/html_head.xsl"/>
    <xsl:import href="./partials/html_navbar.xsl"/>
    <xsl:import href="./partials/html_footer.xsl"/>
    <xsl:output encoding="UTF-8" media-type="text/html" method="html" version="5.0" indent="yes" omit-xml-declaration="yes"/>

    <xsl:template match="/">
        <html class="h-100" lang="{$default_lang}">
            <head>
                <xsl:call-template name="html_head">
                    <xsl:with-param name="html_title" select="concat('Kalender – ', $project_short_title)"/>
                </xsl:call-template>
                <link rel="stylesheet" href="css/kalender.css"/>
            </head>
            <body class="d-flex flex-column h-100">
                <xsl:call-template name="nav_bar"/>
                <main id="main" tabindex="-1" class="flex-shrink-0 flex-grow-1">
                    <div class="container-xxl py-3">
                        <h1 class="visually-hidden">Kalender</h1>
                        <div id="kalender">
                            <p class="text-body-secondary">Der Kalender wird geladen …</p>
                            <noscript>
                                <p>Der Kalender braucht JavaScript. Ohne JavaScript führt die
                                    <a href="jahre.html">Übersicht aller Jahre</a> zu jedem Tag.</p>
                            </noscript>
                        </div>
                    </div>
                </main>
                <xsl:call-template name="html_footer"/>
                <script src="js/calendar.js"></script>
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
