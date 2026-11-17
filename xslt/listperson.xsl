<?xml version="1.0" encoding="UTF-8"?>
<!-- Personenregister und Personenseiten (Layout: entities.xsl über partials/entities-local.xsl) -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:mam="whatever" exclude-result-prefixes="#all" version="3.0">
    <xsl:import href="./partials/html_head.xsl"/>
    <xsl:import href="./partials/html_navbar.xsl"/>
    <xsl:import href="./partials/html_footer.xsl"/>
    <xsl:import href="./partials/entities-local.xsl"/>
    <xsl:import href="./partials/register.xsl"/>
    <xsl:output encoding="UTF-8" media-type="text/html" method="html" version="5.0" indent="no" omit-xml-declaration="yes"/>

    <xsl:function name="mam:personenname" as="xs:string">
        <xsl:param name="p" as="element(tei:person)"/>
        <xsl:variable name="n" select="$p/tei:persName[1]"/>
        <xsl:sequence select="normalize-space(string-join(($n/tei:forename[1], $n/tei:surname[1]), ' '))"/>
    </xsl:function>

    <xsl:template match="/">
        <xsl:variable name="personen" select="//tei:listPerson/tei:person[@xml:id]"/>
        <xsl:call-template name="registerseite">
            <xsl:with-param name="titel" select="'Personen'"/>
            <xsl:with-param name="einleitung">
                <p>
                    <xsl:value-of select="format-number(count($personen), '#.###', 'de')"/>
                    <xsl:text> Personen, die an den Ereignissen mitgewirkt oder teilgenommen haben, sowie die Urheber:innen der aufgeführten Werke.</xsl:text>
                </p>
            </xsl:with-param>
            <xsl:with-param name="tabelle">
                <table id="register" class="table table-sm" data-sortierung="ereignisse">
                    <thead>
                        <tr>
                            <th tabulator-field="name" tabulator-formatter="html" tabulator-headerFilter="input" tabulator-minWidth="200">Name</th>
                            <th tabulator-field="lebensdaten" tabulator-headerFilter="input">Lebensdaten</th>
                            <th tabulator-field="berufe" tabulator-headerFilter="input">Berufe</th>
                            <th tabulator-field="ereignisse" tabulator-sorter="number" tabulator-hozAlign="right" tabulator-width="120">Ereignisse</th>
                        </tr>
                    </thead>
                    <tbody>
                        <xsl:for-each select="$personen">
                            <xsl:variable name="n" select="tei:persName[1]"/>
                            <tr>
                                <td>
                                    <span hidden="hidden">
                                        <xsl:value-of select="string-join(($n/tei:surname[1], $n/tei:forename[1]), ' ')"/>
                                    </span>
                                    <a href="{@xml:id}.html">
                                        <xsl:value-of select="normalize-space(string-join(($n/tei:surname[1][normalize-space()], $n/tei:forename[1][normalize-space()]), ', '))"/>
                                    </a>
                                </td>
                                <td>
                                    <xsl:value-of select="mam:lebensdaten(.)"/>
                                </td>
                                <td>
                                    <xsl:value-of select="distinct-values(tei:occupation/replace(normalize-space(.), '/.*$', ''))" separator=", "/>
                                </td>
                                <td>
                                    <xsl:value-of select="tei:ereignisse(.)"/>
                                </td>
                            </tr>
                        </xsl:for-each>
                    </tbody>
                </table>
            </xsl:with-param>
        </xsl:call-template>
        <xsl:for-each select="$personen">
            <xsl:call-template name="entitaetsseite">
                <xsl:with-param name="name" select="mam:personenname(.)"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>
    <xsl:decimal-format name="de" decimal-separator="," grouping-separator="."/>
</xsl:stylesheet>
