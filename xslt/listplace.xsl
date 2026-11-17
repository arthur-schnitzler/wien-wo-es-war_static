<?xml version="1.0" encoding="UTF-8"?>
<!-- Ortsregister mit Karte der Spielstätten, Ortsseiten -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:mam="whatever" exclude-result-prefixes="#all" version="3.0">
    <xsl:import href="./partials/html_head.xsl"/>
    <xsl:import href="./partials/html_navbar.xsl"/>
    <xsl:import href="./partials/html_footer.xsl"/>
    <xsl:import href="./partials/entities-local.xsl"/>
    <xsl:import href="./partials/register.xsl"/>
    <xsl:output encoding="UTF-8" media-type="text/html" method="html" version="5.0" indent="no" omit-xml-declaration="yes"/>

    <!-- eigene Koordinaten, sonst die des übergeordneten Ortes; als (lat, lng) -->
    <xsl:function name="mam:koordinaten" as="xs:double*">
        <xsl:param name="p" as="element(tei:place)"/>
        <xsl:variable name="geo" select="normalize-space((($p/tei:location[@type = 'coords']/tei:geo), $p/tei:location/tei:geo)[1])"/>
        <xsl:sequence select="
                if (matches($geo, '^-?\d+(,\d+)? -?\d+(,\d+)?$')) then
                    for $t in tokenize($geo, ' ') return xs:double(replace($t, ',', '.'))
                else
                    ()"/>
    </xsl:function>

    <xsl:template match="/">
        <xsl:variable name="orte" select="//tei:listPlace/tei:place[@xml:id]"/>
        <xsl:call-template name="registerseite">
            <xsl:with-param name="titel" select="'Orte'"/>
            <xsl:with-param name="einleitung">
                <p>
                    <xsl:value-of select="count($orte)"/>
                    <xsl:text> Orte, an denen Ereignisse stattgefunden haben. Die Karte zeigt die Spielstätten, die Größe der Punkte die Anzahl der Ereignisse.</xsl:text>
                </p>
            </xsl:with-param>
            <xsl:with-param name="vorher">
                <div id="spielstaetten-karte" class="mb-4" style="height: 60vh; min-height: 320px;"
                    role="region" aria-label="Karte der Spielstätten"></div>
                <script id="spielstaetten-daten" type="application/json">
                    <xsl:text>[</xsl:text>
                    <xsl:for-each select="$orte[tei:ereignisse(.) gt 0][count(mam:koordinaten(.)) = 2]">
                        <xsl:variable name="k" select="mam:koordinaten(.)"/>
                        <xsl:if test="position() gt 1">,</xsl:if>
                        <xsl:value-of select="concat('[', $k[1], ',', $k[2], ',&quot;', replace(normalize-space(tei:placeName[1]), '&quot;', '\\&quot;'), '&quot;,&quot;', @xml:id, '&quot;,', tei:ereignisse(.), ']')"/>
                    </xsl:for-each>
                    <xsl:text>]</xsl:text>
                </script>
            </xsl:with-param>
            <xsl:with-param name="tabelle">
                <table id="register" class="table table-sm" data-sortierung="ereignisse">
                    <thead>
                        <tr>
                            <th tabulator-field="name" tabulator-formatter="html" tabulator-headerFilter="input" tabulator-minWidth="250">Name</th>
                            <th tabulator-field="art" tabulator-headerFilter="input">Art</th>
                            <th tabulator-field="ereignisse" tabulator-sorter="number" tabulator-hozAlign="right" tabulator-width="120">Ereignisse</th>
                        </tr>
                    </thead>
                    <tbody>
                        <xsl:for-each select="$orte">
                            <tr>
                                <td>
                                    <span hidden="hidden">
                                        <xsl:value-of select="normalize-space(tei:placeName[1])"/>
                                    </span>
                                    <a href="{@xml:id}.html">
                                        <xsl:value-of select="normalize-space(tei:placeName[1])"/>
                                    </a>
                                </td>
                                <td>
                                    <xsl:value-of select="replace(normalize-space(tei:desc[@type = 'entity_type'][1]), '\s*\([^)]*\)$', '')"/>
                                </td>
                                <td>
                                    <xsl:value-of select="tei:ereignisse(.)"/>
                                </td>
                            </tr>
                        </xsl:for-each>
                    </tbody>
                </table>
            </xsl:with-param>
            <xsl:with-param name="skripte" as="element()*">
                <link rel="stylesheet" href="vendor/leaflet/leaflet.css"/>
                <script src="vendor/leaflet/leaflet.js"></script>
                <script src="js/spielstaetten.js"></script>
            </xsl:with-param>
        </xsl:call-template>
        <xsl:for-each select="$orte">
            <xsl:call-template name="entitaetsseite">
                <xsl:with-param name="name" select="normalize-space(tei:placeName[1])"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>
