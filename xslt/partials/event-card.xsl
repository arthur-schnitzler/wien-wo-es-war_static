<?xml version="1.0" encoding="UTF-8"?>
<!--
    Ereigniskarte (PLANUNG.md, Abschnitt 6). Eingabe: tei:event aus data/indices/listevent.xml
    (mit den Zusatzattributen wiw:titel, wiw:typ, wiw:gruppe aus pyscripts/prepare_data.py).

    Kernanforderung: jede tei:idno erscheint als Link, auch bei unbekanntem @subtype.
    Reihenfolge der Links: @group in list-of-relevant-uris.xml (quelle, projekt, normdaten),
    innerhalb der Gruppe die Dokumentreihenfolge der Liste; unbekannte Subtypes nach den Projekten.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:wiw="https://wohin-in-wien-damals.acdh.oeaw.ac.at/ns"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    exclude-result-prefixes="#all" version="3.0">

    <xsl:variable name="wiw:indices" select="'../../data/indices/'"/>
    <xsl:variable name="wiw:reg-person" select="doc(concat($wiw:indices, 'listperson.xml'))"/>
    <xsl:variable name="wiw:reg-place" select="doc(concat($wiw:indices, 'listplace.xml'))"/>
    <xsl:variable name="wiw:reg-org" select="doc(concat($wiw:indices, 'listorg.xml'))"/>
    <xsl:variable name="wiw:reg-bibl" select="doc(concat($wiw:indices, 'listbibl.xml'))"/>
    <xsl:variable name="wiw:typen" select="doc(concat($wiw:indices, 'ereignistypen.xml'))"/>
    <xsl:variable name="wiw:uri-liste" select="doc('../list-of-relevant-uris.xml')"/>

    <xsl:key name="wiw:person" match="tei:person" use="@xml:id"/>
    <xsl:key name="wiw:place" match="tei:place" use="@xml:id"/>
    <xsl:key name="wiw:org" match="tei:org" use="@xml:id"/>
    <xsl:key name="wiw:bibl" match="tei:bibl[@xml:id]" use="@xml:id"/>
    <xsl:key name="wiw:gruppe" match="gruppe" use="@id"/>
    <xsl:key name="wiw:uri" match="item" use="abbr"/>

    <!-- Sammlungen, die als „Quelle“ erscheinen (Positivliste, PLANUNG.md Datenhinweise) -->
    <xsl:variable name="wiw:quellen" as="map(xs:string, xs:string)"
        select="map {
            '84': 'Burgtheater',
            '122': 'Spielplan der Wiener Oper',
            '44': 'Schnitzler: Kulturveranstaltungen',
            '28': 'Brahms online',
            '120': 'Max Kalbeck: Tagebücher',
            '5': 'Karl Kraus: Rechtsakten'}"/>

    <!-- Beschriftung der Urheberrollen in listbibl.xml -->
    <xsl:variable name="wiw:rollen" as="map(xs:string, xs:string)"
        select="map {
            'hat-geschaffen': 'Werk',
            'hat-geschaffen-vertonung': 'Musik',
            'hat-geschaffen-textgrundlage-von': 'Textvorlage',
            'hat-ubersetzt': 'Übersetzung',
            'hat-einen-beitrag-geschaffen-zu': 'Mitarbeit',
            'hat-herausgegeben': 'Herausgabe',
            'hat-illustriert': 'Illustration',
            'hat-ein-vorwortnachwort-verfasst-zu': 'Vor-/Nachwort',
            'hat-anonym-veroffentlicht': 'Werk (anonym)',
            'hat-unter-pseudonym-geschrieben': 'Werk (Pseudonym)',
            'hat-unter-einem-kurzel-veroffentlicht': 'Werk (Kürzel)'}"/>

    <!-- Beziehung Ereignis → Werk; „ist Aufführung von“ wird nicht eigens genannt -->
    <xsl:variable name="wiw:beziehungen" as="map(xs:string, xs:string)"
        select="map {
            'ist Aufführung von': '',
            'ist Lesung von': 'Lesung',
            'ist Premiere von': 'Premiere',
            'ist Probe von': 'Probe',
            'ist Generalprobe von': 'Generalprobe',
            'ist Uraufführung von': 'Uraufführung',
            'ist Neueinstudierung von': 'Neueinstudierung',
            'ist Ausstellung von': 'Ausstellung'}"/>

    <xsl:variable name="wiw:rezension" select="'wird rezensiert in'"/>

    <!-- ===== Namen aus den Registern ===== -->

    <xsl:function name="wiw:personenname" as="xs:string">
        <xsl:param name="key" as="xs:string"/>
        <xsl:variable name="p" select="key('wiw:person', $key, $wiw:reg-person)"/>
        <xsl:variable name="pn" select="$p/tei:persName[1]"/>
        <xsl:sequence select="if ($pn) then normalize-space(string-join(($pn/tei:forename[1], $pn/tei:surname[1]), ' ')) else $key"/>
    </xsl:function>

    <xsl:function name="wiw:ortsname" as="xs:string">
        <xsl:param name="key" as="xs:string"/>
        <xsl:variable name="p" select="key('wiw:place', $key, $wiw:reg-place)"/>
        <xsl:sequence select="if ($p) then normalize-space($p/tei:placeName[1]) else $key"/>
    </xsl:function>

    <xsl:function name="wiw:orgname" as="xs:string">
        <xsl:param name="key" as="xs:string"/>
        <xsl:variable name="o" select="key('wiw:org', $key, $wiw:reg-org)"/>
        <xsl:sequence select="if ($o) then normalize-space($o/tei:orgName[1]) else $key"/>
    </xsl:function>

    <xsl:function name="wiw:werktitel" as="xs:string">
        <xsl:param name="key" as="xs:string"/>
        <xsl:variable name="b" select="key('wiw:bibl', $key, $wiw:reg-bibl)"/>
        <xsl:sequence select="if ($b) then normalize-space(($b/tei:title[@type = 'main'], $b/tei:title)[1]) else $key"/>
    </xsl:function>

    <!-- Werktitel, Untertitel nach dem ersten Punkt kleiner -->
    <xsl:template name="wiw:werktitel-gesetzt">
        <xsl:param name="titel" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="contains($titel, '. ')">
                <xsl:value-of select="substring-before($titel, '. ')"/>
                <xsl:text>. </xsl:text>
                <small class="ereignis-untertitel">
                    <xsl:value-of select="substring-after($titel, '. ')"/>
                </small>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$titel"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Ereignisgruppe und ihre Farbe -->
    <xsl:function name="wiw:gruppe" as="element()?">
        <xsl:param name="event" as="element(tei:event)"/>
        <xsl:sequence select="key('wiw:gruppe', $event/@wiw:gruppe, $wiw:typen)"/>
    </xsl:function>

    <!-- Datum, an dem die Karte kanonisch steht -->
    <xsl:function name="wiw:starttag" as="xs:string">
        <xsl:param name="event" as="element(tei:event)"/>
        <xsl:sequence select="string(($event/@when-iso, $event/@from-iso)[1])"/>
    </xsl:function>

    <!-- Ort für die Sortierung innerhalb einer Gruppe -->
    <xsl:function name="wiw:sortierort" as="xs:string">
        <xsl:param name="event" as="element(tei:event)"/>
        <xsl:variable name="key" select="($event/tei:listPlace//tei:placeName/@key)[1]"/>
        <xsl:sequence select="if ($key) then wiw:ortsname($key) else 'zzz'"/>
    </xsl:function>

    <!-- ===== Karte ===== -->

    <!--
        laufend = true(): Karte im Abschnitt „Laufend“ eines späteren Tages. Sie bekommt keine id
        (die steht nur auf dem Starttag), aber data-ereignis für Prüfung und Verlinkung.
    -->
    <xsl:template match="tei:event" mode="karte">
        <xsl:param name="laufend" as="xs:boolean" select="false()"/>
        <xsl:variable name="id" select="string(@xml:id)"/>
        <xsl:variable name="gruppe" select="wiw:gruppe(.)"/>
        <xsl:variable name="starttag" select="wiw:starttag(.)"/>
        <xsl:variable name="werke" select="tei:listBibl/tei:bibl[tei:title/@key][not(normalize-space(tei:note[@type = 'relation-type']) = $wiw:rezension)]"/>
        <xsl:variable name="rezensionen" select="tei:listBibl/tei:bibl[tei:title/@key][normalize-space(tei:note[@type = 'relation-type']) = $wiw:rezension]"/>
        <article class="ereignis card mb-3 gruppe-{@wiw:gruppe}" data-ereignis="{$id}" data-gruppe="{@wiw:gruppe}">
            <xsl:if test="not($laufend)">
                <xsl:attribute name="id" select="$id"/>
            </xsl:if>
            <xsl:if test="$laufend">
                <xsl:attribute name="class" select="concat('ereignis ereignis-laufend card mb-3 gruppe-', @wiw:gruppe)"/>
            </xsl:if>
            <div class="card-body">
                <div class="d-flex flex-wrap gap-2 align-items-baseline mb-1">
                    <span class="badge ereignis-typ">
                        <xsl:value-of select="@wiw:typ"/>
                    </span>
                    <xsl:choose>
                        <xsl:when test="@wiw:unbestimmt = 'true'">
                            <span class="small text-body-secondary">
                                <xsl:value-of select="wiw:monat-jahr(xs:date(@from-iso))"/>
                                <xsl:text>, Tag nicht bekannt</xsl:text>
                            </span>
                        </xsl:when>
                        <xsl:when test="@from-iso and @to-iso and @from-iso != @to-iso">
                            <span class="small text-body-secondary">
                                <xsl:value-of select="wiw:zeitraum(xs:date(@from-iso), xs:date(@to-iso))"/>
                            </span>
                        </xsl:when>
                    </xsl:choose>
                </div>
                <h3 class="h5 card-title ereignis-titel">
                    <xsl:choose>
                        <!-- ein einzelnes Werk: dessen Titel -->
                        <xsl:when test="count($werke) = 1">
                            <a href="{$werke/tei:title/@key}.html">
                                <xsl:call-template name="wiw:werktitel-gesetzt">
                                    <xsl:with-param name="titel" select="wiw:werktitel($werke/tei:title/@key)"/>
                                </xsl:call-template>
                            </a>
                        </xsl:when>
                        <xsl:when test="normalize-space(@wiw:titel)">
                            <xsl:value-of select="@wiw:titel"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="normalize-space(tei:eventName)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </h3>
                <xsl:if test="$laufend">
                    <p class="small mb-2 seit">
                        <xsl:text>Seit </xsl:text>
                        <a href="{$starttag}.html#{$id}">
                            <xsl:value-of select="wiw:datum(xs:date($starttag))"/>
                        </a>
                    </p>
                </xsl:if>
                <dl class="ereignis-details mb-2">
                    <xsl:call-template name="wiw:zeile-orte"/>
                    <xsl:call-template name="wiw:zeile-veranstalter"/>
                    <xsl:call-template name="wiw:zeile-werke">
                        <xsl:with-param name="werke" select="$werke"/>
                    </xsl:call-template>
                    <xsl:call-template name="wiw:zeile-personen">
                        <xsl:with-param name="rolle" select="'hat mitwirkend'"/>
                        <xsl:with-param name="label" select="'Mitwirkende'"/>
                    </xsl:call-template>
                    <xsl:call-template name="wiw:zeile-personen">
                        <xsl:with-param name="rolle" select="'hat teilnehmend'"/>
                        <xsl:with-param name="label" select="'Teilnehmende'"/>
                    </xsl:call-template>
                    <xsl:if test="$rezensionen">
                        <div class="ereignis-zeile">
                            <dt>Rezension</dt>
                            <dd>
                                <xsl:for-each select="$rezensionen">
                                    <a href="{tei:title/@key}.html">
                                        <xsl:value-of select="wiw:werktitel(tei:title/@key)"/>
                                    </a>
                                    <xsl:if test="position() != last()">
                                        <xsl:text>; </xsl:text>
                                    </xsl:if>
                                </xsl:for-each>
                            </dd>
                        </div>
                    </xsl:if>
                    <xsl:call-template name="wiw:zeile-quelle"/>
                </dl>
                <div class="ereignis-links d-flex flex-wrap gap-1" aria-label="Links">
                    <xsl:call-template name="wiw:uri-links"/>
                </div>
                <!-- Permalink und Zitiervorschlag baut js/tag.js aus id, Titel und Datum der Karte -->
                <div class="ereignis-aktionen mt-2">
                    <button type="button" class="btn btn-sm btn-link p-0 me-3 link-kopieren">
                        <i class="bi bi-link-45deg" aria-hidden="true"></i>
                        <xsl:text> Link kopieren</xsl:text>
                    </button>
                    <button type="button" class="btn btn-sm btn-link p-0 zitat-kopieren">
                        <i class="bi bi-quote" aria-hidden="true"></i>
                        <xsl:text> Zitieren</xsl:text>
                    </button>
                </div>
            </div>
        </article>
    </xsl:template>

    <xsl:template name="wiw:zeile-orte">
        <xsl:variable name="orte" select="tei:listPlace//tei:placeName[@key]"/>
        <xsl:if test="$orte">
            <div class="ereignis-zeile">
                <dt>Ort</dt>
                <dd>
                    <xsl:for-each select="$orte">
                        <a href="{@key}.html">
                            <xsl:choose>
                                <!-- 955 Ereignisse haben nur „Wien“ als Ort -->
                                <xsl:when test="@key = 'pmb50'">Wien (Ort nicht näher bestimmt)</xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="wiw:ortsname(@key)"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </a>
                        <xsl:if test="position() != last()">
                            <xsl:text>, </xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                </dd>
            </div>
        </xsl:if>
    </xsl:template>

    <xsl:template name="wiw:zeile-veranstalter">
        <xsl:variable name="orgs" select="tei:note[@type = 'listorg']//tei:orgName[@key]"/>
        <xsl:if test="$orgs">
            <div class="ereignis-zeile">
                <dt>Veranstaltet von</dt>
                <dd>
                    <xsl:for-each select="$orgs">
                        <a href="{@key}.html">
                            <xsl:value-of select="wiw:orgname(@key)"/>
                        </a>
                        <xsl:if test="position() != last()">
                            <xsl:text>, </xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                </dd>
            </div>
        </xsl:if>
    </xsl:template>

    <!--
        Ein Werk: Der Titel steht schon in der Überschrift, die Zeile nennt nur die Urheber:innen.
        Mehrere Werke: Liste mit Titel, Beziehung (Premiere, Lesung …) und Urheber:innen.
    -->
    <xsl:template name="wiw:zeile-werke">
        <xsl:param name="werke" as="element(tei:bibl)*"/>
        <xsl:choose>
            <xsl:when test="count($werke) = 1">
                <xsl:variable name="autoren" select="key('wiw:bibl', string($werke/tei:title/@key), $wiw:reg-bibl)/tei:author[@key]"/>
                <xsl:if test="$autoren">
                    <div class="ereignis-zeile">
                        <dt>Von</dt>
                        <dd>
                            <xsl:call-template name="wiw:urheber">
                                <xsl:with-param name="autoren" select="$autoren"/>
                            </xsl:call-template>
                        </dd>
                    </div>
                </xsl:if>
            </xsl:when>
            <xsl:when test="$werke">
                <div class="ereignis-zeile">
                    <dt>Werke</dt>
                    <dd>
                        <ul class="list-unstyled mb-0">
                            <xsl:for-each select="$werke">
                                <xsl:variable name="key" select="string(tei:title/@key)"/>
                                <xsl:variable name="rel" select="normalize-space(tei:note[@type = 'relation-type'])"/>
                                <xsl:variable name="rel-label" select="if (map:contains($wiw:beziehungen, $rel)) then $wiw:beziehungen($rel) else $rel"/>
                                <xsl:variable name="autoren" select="key('wiw:bibl', $key, $wiw:reg-bibl)/tei:author[@key]"/>
                                <li>
                                    <a href="{$key}.html" class="werktitel">
                                        <xsl:value-of select="wiw:werktitel($key)"/>
                                    </a>
                                    <xsl:if test="$rel-label != ''">
                                        <xsl:text> </xsl:text>
                                        <span class="badge text-bg-light border">
                                            <xsl:value-of select="$rel-label"/>
                                        </span>
                                    </xsl:if>
                                    <xsl:if test="$autoren">
                                        <span class="small">
                                            <xsl:text> von </xsl:text>
                                            <xsl:call-template name="wiw:urheber">
                                                <xsl:with-param name="autoren" select="$autoren"/>
                                            </xsl:call-template>
                                        </span>
                                    </xsl:if>
                                </li>
                            </xsl:for-each>
                        </ul>
                    </dd>
                </div>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <!-- „Gustav Freytag“ · „Richard Wagner · Übersetzung: …“: hat-geschaffen ohne Beschriftung, zuerst -->
    <xsl:template name="wiw:urheber">
        <xsl:param name="autoren" as="element(tei:author)*"/>
        <xsl:for-each-group select="$autoren" group-by="string(@role)">
            <xsl:sort select="if (current-grouping-key() = 'hat-geschaffen') then 0 else 1"/>
            <xsl:variable name="rolle" select="current-grouping-key()"/>
            <xsl:if test="position() gt 1">
                <xsl:text> · </xsl:text>
            </xsl:if>
            <xsl:if test="$rolle != 'hat-geschaffen'">
                <xsl:value-of select="if (map:contains($wiw:rollen, $rolle)) then $wiw:rollen($rolle) else $rolle"/>
                <xsl:text>: </xsl:text>
            </xsl:if>
            <xsl:for-each select="current-group()[not(@key = preceding-sibling::tei:author[@role = $rolle]/@key)]">
                <a href="{@key}.html">
                    <xsl:value-of select="wiw:personenname(@key)"/>
                </a>
                <xsl:if test="position() != last()">
                    <xsl:text>, </xsl:text>
                </xsl:if>
            </xsl:for-each>
        </xsl:for-each-group>
    </xsl:template>

    <xsl:template name="wiw:zeile-personen">
        <xsl:param name="rolle" as="xs:string"/>
        <xsl:param name="label" as="xs:string"/>
        <xsl:variable name="personen" select="tei:listPerson/tei:person[@role = $rolle]/tei:persName[@key]"/>
        <xsl:if test="$personen">
            <div class="ereignis-zeile">
                <dt>
                    <xsl:value-of select="$label"/>
                </dt>
                <dd>
                    <xsl:for-each select="$personen">
                        <a href="{@key}.html">
                            <xsl:value-of select="wiw:personenname(@key)"/>
                        </a>
                        <xsl:if test="position() != last()">
                            <xsl:text>, </xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                </dd>
            </div>
        </xsl:if>
    </xsl:template>

    <xsl:template name="wiw:zeile-quelle">
        <xsl:variable name="quellen" select="tei:listBibl/tei:bibl[@type = 'collections'][map:contains($wiw:quellen, string(@n))]"/>
        <xsl:if test="$quellen">
            <div class="ereignis-zeile">
                <dt>Quelle</dt>
                <dd>
                    <xsl:value-of select="distinct-values(for $q in $quellen return $wiw:quellen(string($q/@n)))" separator=", "/>
                </dd>
            </div>
        </xsl:if>
    </xsl:template>

    <!-- ===== URI-Links ===== -->

    <xsl:function name="wiw:gruppenrang" as="xs:integer">
        <xsl:param name="item" as="element(item)?"/>
        <xsl:sequence select="if (not($item)) then 3
            else if ($item/@group = 'quelle') then 1
            else if ($item/@group = 'normdaten') then 4
            else 2"/>
    </xsl:function>

    <!-- CSS-Klasse mit Farbe, siehe xslt/farben.xsl -->
    <xsl:function name="wiw:uri-klasse" as="xs:string">
        <xsl:param name="subtype" as="xs:string"/>
        <xsl:sequence select="concat('uri-', replace($subtype, '[^A-Za-z0-9_-]', '_'))"/>
    </xsl:function>

    <xsl:function name="wiw:hostname" as="xs:string">
        <xsl:param name="url" as="xs:string"/>
        <xsl:sequence select="replace($url, '^[a-z]+://(www\.)?([^/?#]+).*$', '$2')"/>
    </xsl:function>

    <xsl:template name="wiw:uri-links">
        <xsl:variable name="event" select="."/>
        <xsl:variable name="idnos" select="tei:idno[normalize-space()]"/>
        <xsl:for-each select="$idnos">
            <xsl:sort select="wiw:gruppenrang(key('wiw:uri', string(@subtype), $wiw:uri-liste)[1])" data-type="number"/>
            <xsl:sort select="count(key('wiw:uri', string(@subtype), $wiw:uri-liste)[1]/preceding-sibling::item)" data-type="number"/>
            <xsl:variable name="subtype" select="string(@subtype)"/>
            <xsl:variable name="url" select="normalize-space(.)"/>
            <xsl:variable name="item" select="key('wiw:uri', $subtype, $wiw:uri-liste)[1]"/>
            <xsl:variable name="gleiche" select="$idnos[string(@subtype) = $subtype]"/>
            <xsl:variable name="nr" select="count(preceding-sibling::tei:idno[normalize-space()][string(@subtype) = $subtype]) + 1"/>
            <xsl:variable name="label">
                <xsl:choose>
                    <xsl:when test="$item">
                        <xsl:value-of select="$item/caption"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="wiw:hostname($url)"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="count($gleiche) gt 1">
                    <xsl:value-of select="concat(' ', $nr)"/>
                </xsl:if>
            </xsl:variable>
            <a href="{$url}" target="_blank" rel="noopener" title="{$url}" aria-describedby="extern"
                class="uri-pill {if ($item/color) then wiw:uri-klasse($subtype) else 'uri-neutral'}">
                <xsl:value-of select="$label"/>
            </a>
        </xsl:for-each>
        <!-- Theaterzettel des Tages für Burgtheater-Vorstellungen, wenn kein ANNO-Link vorhanden ist -->
        <xsl:if test="not($idnos[@subtype = 'anno'])
            and tei:listPlace//tei:placeName/@key = ('pmb14', 'pmb185621')
            and not(contains(@wiw:typ, 'robe'))">
            <xsl:variable name="tag" select="wiw:starttag($event)"/>
            <xsl:variable name="aid" select="if (xs:integer(substring($tag, 1, 4)) lt 1899) then 'wtz' else 'bth'"/>
            <xsl:variable name="url" select="concat('https://anno.onb.ac.at/cgi-content/anno?aid=', $aid, '&amp;datum=', replace($tag, '-', ''))"/>
            <a href="{$url}" target="_blank" rel="noopener" aria-describedby="extern"
                class="uri-pill uri-generiert {wiw:uri-klasse('anno')}"
                title="Theaterzettel des Tages in ANNO (nicht direkt verknüpft): {$url}">
                <xsl:text>Theaterzettel des Tages</xsl:text>
            </a>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>
