<?xml version="1.0" encoding="UTF-8"?>
<!--
    Tages-, Jahres- und Weiterleitungsseiten (PLANUNG.md, Abschnitte 4 und 6).

    Eingabe: data/indices/tage.xml (alle Tage mit Ereignissen, aus pyscripts/prepare_data.py)
    Hauptausgabe: jahre.html (Übersicht aller Jahre)
    Nebenausgaben (xsl:result-document):
      JJJJ.html        Jahresseite mit 12 Monatsrastern
      JJJJ-MM-TT.html  Tagesseite mit allen Ereigniskarten
      pmbNNNN.html     Weiterleitung Ereignis → JJJJ-MM-TT.html#pmbNNNN

    Ein einziger Durchlauf statt einer Transformation pro Jahresdatei, damit Register und
    listevent.xml nur einmal geladen werden.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:wiw="https://wohin-in-wien-damals.acdh.oeaw.ac.at/ns"
    exclude-result-prefixes="#all" version="3.0">

    <xsl:import href="./partials/html_head.xsl"/>
    <xsl:import href="./partials/html_navbar.xsl"/>
    <xsl:import href="./partials/html_footer.xsl"/>
    <xsl:import href="./partials/datum.xsl"/>
    <xsl:import href="./partials/event-card.xsl"/>
    <xsl:output encoding="UTF-8" media-type="text/html" method="html" version="5.0" indent="no" omit-xml-declaration="yes"/>

    <!-- Querverweis auf die Schnitzler-Chronik (offene Frage 7 in PLANUNG.md) -->
    <xsl:param name="chronik-links" select="true()"/>
    <xsl:variable name="chronik-von" select="xs:date('1862-05-15')"/>
    <xsl:variable name="chronik-bis" select="xs:date('1931-10-21')"/>

    <xsl:variable name="listevent" select="doc('../data/indices/listevent.xml')"/>
    <xsl:variable name="mehrtaegig" select="doc('../data/indices/mehrtaegig.xml')/mehrtaegig/ereignis[@art = 'zeitraum']"/>
    <xsl:variable name="alle-tage" select="/tage/tag"/>

    <xsl:key name="ereignisse-am" match="tei:event" use="(@when-iso, @from-iso)[1]"/>
    <xsl:key name="ereignis" match="tei:event" use="@xml:id"/>
    <xsl:key name="tag" match="tag" use="@when"/>
    <xsl:key name="tage-im-jahr" match="tag" use="substring(@when, 1, 4)"/>

    <!-- ===== Hauptausgabe: Jahresübersicht ===== -->
    <xsl:template match="/">
        <xsl:variable name="jahre" select="distinct-values($alle-tage/substring(@when, 1, 4))"/>
        <xsl:call-template name="seite">
            <xsl:with-param name="titel" select="'Alle Jahre'"/>
            <xsl:with-param name="krumen" as="element()*"/>
            <xsl:with-param name="inhalt">
                <h1>Alle Jahre</h1>
                <p>
                    <xsl:text>Ereignisse pro Jahr, </xsl:text>
                    <xsl:value-of select="$start-year"/>
                    <xsl:text>–</xsl:text>
                    <xsl:value-of select="$end-year"/>
                    <xsl:text>. Ein Klick führt zur Jahresseite mit allen Tagen.</xsl:text>
                </p>
                <ul class="jahresliste list-unstyled">
                    <xsl:for-each select="$jahre">
                        <xsl:variable name="jahr" select="."/>
                        <li>
                            <a href="{$jahr}.html">
                                <xsl:value-of select="$jahr"/>
                            </a>
                            <span class="text-body-secondary small">
                                <xsl:text> </xsl:text>
                                <xsl:value-of select="format-number(sum(key('tage-im-jahr', $jahr, root($alle-tage[1]))/@n), '#.###', 'de')"/>
                            </span>
                        </li>
                    </xsl:for-each>
                </ul>
            </xsl:with-param>
        </xsl:call-template>

        <xsl:for-each select="$jahre">
            <xsl:call-template name="jahresseite">
                <xsl:with-param name="jahr" select="xs:integer(.)"/>
            </xsl:call-template>
        </xsl:for-each>

        <xsl:for-each select="$alle-tage">
            <xsl:call-template name="tagesseite"/>
        </xsl:for-each>

        <xsl:for-each select="$listevent//tei:event">
            <xsl:call-template name="weiterleitung"/>
        </xsl:for-each>
    </xsl:template>

    <xsl:decimal-format name="de" decimal-separator="," grouping-separator="."/>

    <!-- ===== Seitengerüst ===== -->
    <xsl:template name="seite">
        <xsl:param name="titel" as="xs:string"/>
        <xsl:param name="krumen" as="element()*"/>
        <xsl:param name="inhalt"/>
        <xsl:param name="skripte" as="element()*"/>
        <html class="h-100" lang="{$default_lang}">
            <head>
                <xsl:call-template name="html_head">
                    <xsl:with-param name="html_title" select="concat($titel, ' – ', $project_short_title)"/>
                </xsl:call-template>
            </head>
            <body class="d-flex flex-column h-100">
                <xsl:call-template name="nav_bar"/>
                <main id="main" tabindex="-1" class="flex-shrink-0 flex-grow-1">
                    <nav style="--bs-breadcrumb-divider: '›';" aria-label="Brotkrumen" class="container pt-3">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">
                                <a href="index.html">
                                    <xsl:value-of select="$project_short_title"/>
                                </a>
                            </li>
                            <xsl:for-each select="$krumen">
                                <li class="breadcrumb-item">
                                    <xsl:copy-of select="."/>
                                </li>
                            </xsl:for-each>
                            <li class="breadcrumb-item active" aria-current="page">
                                <xsl:value-of select="$titel"/>
                            </li>
                        </ol>
                    </nav>
                    <div class="container pb-4">
                        <xsl:copy-of select="$inhalt"/>
                    </div>
                </main>
                <xsl:call-template name="html_footer"/>
                <xsl:copy-of select="$skripte"/>
            </body>
        </html>
    </xsl:template>

    <!-- ===== Jahresseite ===== -->
    <xsl:template name="jahresseite">
        <xsl:param name="jahr" as="xs:integer"/>
        <xsl:variable name="tage" select="key('tage-im-jahr', string($jahr), root($alle-tage[1]))"/>
        <xsl:result-document href="{$jahr}.html">
            <xsl:call-template name="seite">
                <xsl:with-param name="titel" select="string($jahr)"/>
                <xsl:with-param name="krumen" as="element()*">
                    <a href="jahre.html">Alle Jahre</a>
                </xsl:with-param>
                <xsl:with-param name="inhalt">
                    <div class="d-flex flex-wrap align-items-center gap-3 mb-3">
                        <h1 class="mb-0">
                            <xsl:value-of select="$jahr"/>
                        </h1>
                        <nav aria-label="Jahre" class="d-flex gap-2">
                            <xsl:if test="$jahr gt $start-year">
                                <a class="btn btn-sm btn-outline-secondary" href="{$jahr - 1}.html" rel="prev">
                                    <xsl:text>← </xsl:text>
                                    <xsl:value-of select="$jahr - 1"/>
                                </a>
                            </xsl:if>
                            <xsl:if test="$jahr lt $end-year">
                                <a class="btn btn-sm btn-outline-secondary" href="{$jahr + 1}.html" rel="next">
                                    <xsl:value-of select="$jahr + 1"/>
                                    <xsl:text> →</xsl:text>
                                </a>
                            </xsl:if>
                        </nav>
                    </div>
                    <p>
                        <xsl:value-of select="format-number(sum($tage/@n), '#.###', 'de')"/>
                        <xsl:text> Ereignisse an </xsl:text>
                        <xsl:value-of select="format-number(count($tage), '#.###', 'de')"/>
                        <xsl:text> Tagen.</xsl:text>
                    </p>
                    <div class="row g-4">
                        <xsl:for-each select="1 to 12">
                            <div class="col-sm-6 col-lg-4 col-xl-3">
                                <xsl:call-template name="monatsraster">
                                    <xsl:with-param name="jahr" select="$jahr"/>
                                    <xsl:with-param name="monat" select="."/>
                                </xsl:call-template>
                            </div>
                        </xsl:for-each>
                    </div>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:result-document>
    </xsl:template>

    <xsl:template name="monatsraster">
        <xsl:param name="jahr" as="xs:integer"/>
        <xsl:param name="monat" as="xs:integer"/>
        <xsl:variable name="erster" select="xs:date(concat($jahr, '-', format-number($monat, '00'), '-01'))"/>
        <xsl:variable name="tage-im-monat" select="day-from-date($erster + xs:yearMonthDuration('P1M') - xs:dayTimeDuration('P1D'))"/>
        <xsl:variable name="leer" select="wiw:wochentag-nr($erster) - 1"/>
        <xsl:variable name="zellen" as="xs:integer*" select="(for $i in 1 to $leer return 0, 1 to $tage-im-monat)"/>
        <table class="monatsraster table table-sm table-borderless text-center mb-0" id="m{format-number($monat, '00')}">
            <caption class="caption-top fw-semibold text-body">
                <a href="kalender.html?ansicht=monat&amp;datum={$jahr}-{format-number($monat, '00')}">
                    <xsl:value-of select="wiw:monat($monat)"/>
                </a>
            </caption>
            <thead>
                <tr>
                    <xsl:for-each select="('Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So')">
                        <th scope="col" class="small text-body-secondary fw-normal">
                            <xsl:value-of select="."/>
                        </th>
                    </xsl:for-each>
                </tr>
            </thead>
            <tbody>
                <xsl:for-each select="0 to (count($zellen) - 1) idiv 7">
                    <xsl:variable name="woche" select="."/>
                    <tr>
                        <xsl:for-each select="subsequence($zellen, $woche * 7 + 1, 7)">
                            <xsl:variable name="d" select="."/>
                            <td>
                                <xsl:if test="$d gt 0">
                                    <xsl:variable name="iso" select="concat($jahr, '-', format-number($monat, '00'), '-', format-number($d, '00'))"/>
                                    <xsl:variable name="tag" select="key('tag', $iso, root($alle-tage[1]))"/>
                                    <xsl:choose>
                                        <xsl:when test="$tag">
                                            <xsl:variable name="n" select="xs:integer($tag/@n)"/>
                                            <a href="{$iso}.html" class="tag-link stufe-{min((($n + 1) idiv 2, 4))}"
                                                title="{wiw:anzahl($n, $tag/@laufend)}">
                                                <xsl:attribute name="aria-label" select="concat(wiw:anzahl($n, $tag/@laufend), ' am ', wiw:datum(xs:date($iso)))"/>
                                                <xsl:value-of select="$d"/>
                                            </a>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <span class="text-body-tertiary">
                                                <xsl:value-of select="$d"/>
                                            </span>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:if>
                            </td>
                        </xsl:for-each>
                    </tr>
                </xsl:for-each>
            </tbody>
        </table>
    </xsl:template>

    <xsl:function name="wiw:anzahl" as="xs:string">
        <xsl:param name="n" as="xs:integer"/>
        <xsl:param name="laufend" as="attribute()?"/>
        <xsl:variable name="haupt" select="if ($n = 1) then '1 Ereignis' else concat($n, ' Ereignisse')"/>
        <xsl:sequence select="if ($laufend and $n = 0) then 'laufende Ereignisse'
            else if ($laufend) then concat($haupt, ' und laufende')
            else $haupt"/>
    </xsl:function>

    <!-- ===== Tagesseite ===== -->
    <xsl:template name="tagesseite">
        <xsl:variable name="iso" select="string(@when)"/>
        <xsl:variable name="datum" select="xs:date($iso)"/>
        <xsl:variable name="jahr" select="year-from-date($datum)"/>
        <xsl:variable name="monat" select="format-number(month-from-date($datum), '00')"/>
        <xsl:variable name="vorher" select="preceding-sibling::tag[1]/@when"/>
        <xsl:variable name="nachher" select="following-sibling::tag[1]/@when"/>
        <xsl:variable name="ereignisse" select="key('ereignisse-am', $iso, $listevent)"/>
        <xsl:variable name="laufend-ids" select="$mehrtaegig[xs:date(@von) lt $datum and xs:date(@bis) ge $datum]/@ref"/>
        <xsl:result-document href="{$iso}.html">
            <xsl:call-template name="seite">
                <xsl:with-param name="titel" select="wiw:datum($datum)"/>
                <xsl:with-param name="krumen" as="element()*">
                    <a href="{$jahr}.html">
                        <xsl:value-of select="$jahr"/>
                    </a>
                    <a href="{$jahr}.html#m{$monat}">
                        <xsl:value-of select="wiw:monat(month-from-date($datum))"/>
                    </a>
                </xsl:with-param>
                <xsl:with-param name="inhalt">
                    <h1>
                        <xsl:value-of select="wiw:datum-lang($datum)"/>
                    </h1>
                    <nav aria-label="Tage" class="tag-navigation d-flex flex-wrap align-items-center gap-2 mb-3">
                        <xsl:choose>
                            <xsl:when test="$vorher">
                                <a class="btn btn-sm btn-outline-secondary" href="{$vorher}.html" rel="prev"
                                    title="vorheriger Tag mit Ereignissen">
                                    <xsl:text>← </xsl:text>
                                    <xsl:value-of select="wiw:datum(xs:date($vorher))"/>
                                </a>
                            </xsl:when>
                        </xsl:choose>
                        <a class="btn btn-sm btn-outline-secondary" href="kalender.html?ansicht=monat&amp;datum={$jahr}-{$monat}">
                            <i class="bi bi-calendar3" aria-hidden="true"></i>
                            <xsl:text> </xsl:text>
                            <xsl:value-of select="wiw:monat-jahr($datum)"/>
                        </a>
                        <a class="btn btn-sm btn-outline-secondary" href="{$jahr}.html">
                            <xsl:text>Jahr </xsl:text>
                            <xsl:value-of select="$jahr"/>
                        </a>
                        <xsl:if test="$nachher">
                            <a class="btn btn-sm btn-outline-secondary" href="{$nachher}.html" rel="next"
                                title="nächster Tag mit Ereignissen">
                                <xsl:value-of select="wiw:datum(xs:date($nachher))"/>
                                <xsl:text> →</xsl:text>
                            </a>
                        </xsl:if>
                        <form class="datum-sprung d-flex align-items-center gap-1 ms-md-auto" role="search">
                            <label for="datum-sprung" class="visually-hidden">Zu Datum springen</label>
                            <input type="date" id="datum-sprung" name="datum" class="form-control form-control-sm"
                                min="{$start-year}-01-01" max="{$end-year}-12-31" value="{$iso}"/>
                            <button type="submit" class="btn btn-sm btn-secondary">Los</button>
                        </form>
                    </nav>

                    <xsl:call-template name="tageslinks">
                        <xsl:with-param name="datum" select="$datum"/>
                    </xsl:call-template>
                    <!-- Beschreibung für alle externen Links der Karten (aria-describedby) -->
                    <span id="extern" hidden="hidden">öffnet eine externe Seite in einem neuen Tab</span>

                    <p class="text-body-secondary">
                        <xsl:value-of select="wiw:anzahl(count($ereignisse), if ($laufend-ids) then $laufend-ids[1] else ())"/>
                    </p>

                    <xsl:for-each-group select="$ereignisse" group-by="string(@wiw:gruppe)">
                        <xsl:sort select="xs:integer((wiw:gruppe(current-group()[1])/@reihenfolge, 99)[1])"/>
                        <xsl:variable name="gruppe" select="wiw:gruppe(current-group()[1])"/>
                        <section class="ereignisgruppe mb-4" aria-labelledby="gruppe-{current-grouping-key()}">
                            <h2 class="h4 gruppen-titel gruppe-{current-grouping-key()}" id="gruppe-{current-grouping-key()}">
                                <xsl:value-of select="($gruppe/label, 'Sonstiges')[1]"/>
                                <span class="badge text-bg-light border ms-2 fw-normal">
                                    <xsl:value-of select="count(current-group())"/>
                                </span>
                            </h2>
                            <xsl:for-each select="current-group()">
                                <xsl:sort select="wiw:sortierort(.)"/>
                                <xsl:sort select="string(@wiw:titel)"/>
                                <xsl:apply-templates select="." mode="karte"/>
                            </xsl:for-each>
                        </section>
                    </xsl:for-each-group>

                    <xsl:if test="$laufend-ids">
                        <section class="ereignisgruppe mb-4" aria-labelledby="gruppe-laufend">
                            <h2 class="h4 gruppen-titel" id="gruppe-laufend">
                                <xsl:text>Laufend</xsl:text>
                                <span class="badge text-bg-light border ms-2 fw-normal">
                                    <xsl:value-of select="count($laufend-ids)"/>
                                </span>
                            </h2>
                            <xsl:for-each select="key('ereignis', $laufend-ids, $listevent)">
                                <xsl:sort select="string(@from-iso)"/>
                                <xsl:apply-templates select="." mode="karte">
                                    <xsl:with-param name="laufend" select="true()"/>
                                </xsl:apply-templates>
                            </xsl:for-each>
                        </section>
                    </xsl:if>
                </xsl:with-param>
                <xsl:with-param name="skripte" as="element()*">
                    <script src="js/tag.js"></script>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:result-document>
    </xsl:template>

    <!-- Links, die für den ganzen Tag gelten: Zeitungen, Schnitzler-Chronik -->
    <xsl:template name="tageslinks">
        <xsl:param name="datum" as="xs:date"/>
        <xsl:variable name="kompakt" select="replace(string($datum), '-', '')"/>
        <div class="tageslinks small mb-3">
            <span class="text-body-secondary">Zeitungen vom Tag: </span>
            <a href="https://anno.onb.ac.at/cgi-content/anno?datum={$kompakt}" target="_blank" rel="noopener">ANNO</a>
            <xsl:text> · </xsl:text>
            <a href="https://www.deutsche-digitale-bibliothek.de/newspaper/select/month?day={day-from-date($datum)}&amp;month={month-from-date($datum)}&amp;year={year-from-date($datum)}"
                target="_blank" rel="noopener">Deutsche Digitale Bibliothek</a>
            <xsl:if test="$chronik-links and $datum ge $chronik-von and $datum le $chronik-bis">
                <span class="text-body-secondary"> · Arthur Schnitzler an diesem Tag: </span>
                <a href="https://schnitzler-chronik.acdh.oeaw.ac.at/{$datum}.html" target="_blank" rel="noopener">Schnitzler-Chronik</a>
            </xsl:if>
        </div>
    </xsl:template>

    <!-- ===== Weiterleitung Ereignis → Tagesseite ===== -->
    <xsl:template name="weiterleitung">
        <xsl:variable name="id" select="string(@xml:id)"/>
        <xsl:variable name="ziel" select="concat(wiw:starttag(.), '.html#', $id)"/>
        <xsl:result-document href="{$id}.html">
            <html lang="{$default_lang}">
                <head>
                    <meta charset="utf-8"/>
                    <title>
                        <xsl:value-of select="(@wiw:titel[normalize-space()], normalize-space(tei:eventName))[1]"/>
                    </title>
                    <meta name="robots" content="noindex"/>
                    <link rel="canonical" href="{$base_url}/{$ziel}"/>
                    <meta http-equiv="refresh" content="0; url={$ziel}"/>
                    <script>location.replace('<xsl:value-of select="$ziel"/>' + location.search);</script>
                </head>
                <body>
                    <p>
                        <a href="{$ziel}">Weiter zum Ereignis</a>
                    </p>
                </body>
            </html>
        </xsl:result-document>
    </xsl:template>
</xsl:stylesheet>
