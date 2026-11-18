<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    version="2.0"
    exclude-result-prefixes="#all">
    
    <xsl:import href="./partials/html_navbar.xsl"/>
    <xsl:import href="./partials/html_head.xsl"/>
    <xsl:import href="./partials/html_footer.xsl"/>
    <xsl:import href="./partials/blockquote.xsl"/>
    <xsl:import href="./partials/zotero.xsl"/>
    <xsl:output encoding="UTF-8" media-type="text/html" method="html" version="5.0" indent="yes" omit-xml-declaration="yes"/>


    <xsl:template match="/">
        <xsl:variable name="doc_title">
            <xsl:value-of select="normalize-space((//tei:titleStmt/tei:title[@type = 'main'], //tei:titleStmt/tei:title[@level = 'a'], //tei:titleStmt/tei:title)[1])"/>
        </xsl:variable>
        <xsl:variable name="teiSource">
            <xsl:value-of select="(tei:TEI/@xml:id, tokenize(document-uri(/), '/')[last()])[1]"/>
        </xsl:variable>
        <xsl:variable name="link">
            <xsl:value-of select="replace($teiSource, '.xml', '.html')"/>
        </xsl:variable>
        <html class="h-100" lang="{$default_lang}">
            <head>
                <xsl:call-template name="html_head">
                    <xsl:with-param name="html_title" select="$doc_title"></xsl:with-param>
                </xsl:call-template>
                <xsl:call-template name="zoterMetaTags">
                    <xsl:with-param name="pageId" select="$link"></xsl:with-param>
                    <xsl:with-param name="zoteroTitle" select="$doc_title"></xsl:with-param>
                </xsl:call-template>
            </head>
            
            <body class="d-flex flex-column h-100">
            <xsl:call-template name="nav_bar"/>
                <main id="main" tabindex="-1" class="flex-shrink-0 flex-grow-1">
                    <nav style="--bs-breadcrumb-divider: '>';" aria-label="breadcrumb" class="ps-5 p-3">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">
                                <a href="index.html">
                                    <xsl:value-of select="$project_short_title"/>
                                </a>
                            </li>
                            <li class="breadcrumb-item active" aria-current="page">
                                <xsl:value-of select="$doc_title"/>
                            </li>
                        </ol>
                    </nav>
                    <div class="container">                        
                        <h1><xsl:value-of select="$doc_title"/></h1>    
                        <xsl:apply-templates select=".//tei:body" />
                        <div class="text-center p-4">
                            <xsl:call-template name="blockquote">
                                <xsl:with-param name="pageId" select="$link"/>
                            </xsl:call-template>
                        </div>

                    </div>
                </main>
                <xsl:call-template name="html_footer"/>
            </body>
        </html>
    </xsl:template>

    <xsl:template match="tei:p">
        <p id="{generate-id()}"><xsl:apply-templates/></p>
    </xsl:template>
    <xsl:template match="tei:div">
        <div id="{(@xml:id, generate-id())[1]}"><xsl:apply-templates/></div>
    </xsl:template>
    <xsl:template match="tei:head">
        <xsl:variable name="ebene" select="min((count(ancestor::tei:div) + 1, 6))"/>
        <xsl:element name="h{$ebene}">
            <xsl:attribute name="class" select="if ($ebene = 2) then 'fs-4 mt-4' else 'fs-5 mt-3'"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tei:ref[@target]">
        <a href="{@target}"><xsl:apply-templates/></a>
    </xsl:template>
    <!-- Anzahl der Ereignisse je Datengeber (data/indices/datengeber.xml, pyscripts/prepare_data.py) -->
    <xsl:variable name="datengeber-datei" select="'../data/indices/datengeber.xml'"/>
    <xsl:variable name="datengeber" select="if (doc-available($datengeber-datei)) then doc($datengeber-datei)/datengeber/datengeber else ()"/>
    <xsl:decimal-format name="de" decimal-separator="," grouping-separator="."/>
    <xsl:template match="tei:div[@type = 'datengeber'][@xml:id]" priority="2">
        <xsl:variable name="eintrag" select="$datengeber[@subtype = current()/@xml:id]"/>
        <div id="{@xml:id}">
            <xsl:apply-templates/>
            <xsl:if test="$eintrag">
                <p class="text-body-secondary">
                    <xsl:value-of select="format-number(xs:integer($eintrag/@n), '#.###', 'de')"/>
                    <xsl:text> Ereignisse in „Wien, wo es war“</xsl:text>
                </p>
            </xsl:if>
        </div>
    </xsl:template>
    <xsl:template match="tei:list">
        <ul><xsl:apply-templates/></ul>
    </xsl:template>
    <xsl:template match="tei:item">
        <li><xsl:if test="@xml:id"><xsl:attribute name="id" select="@xml:id"/></xsl:if><xsl:apply-templates/></li>
    </xsl:template>
    <xsl:template match="tei:title">
        <em><xsl:apply-templates/></em>
    </xsl:template>
    <xsl:template match="tei:lb">
        <br/>
    </xsl:template>
    <xsl:template match="tei:unclear">
        <abbr title="unclear"><xsl:apply-templates/></abbr>
    </xsl:template>
    <xsl:template match="tei:del">
        <del><xsl:apply-templates/></del>
    </xsl:template>    
</xsl:stylesheet>