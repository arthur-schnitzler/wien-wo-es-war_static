<?xml version="1.0" encoding="UTF-8"?>
<!-- Institutionenregister und Institutionsseiten -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:mam="whatever" exclude-result-prefixes="#all" version="3.0">
    <xsl:import href="./partials/html_head.xsl"/>
    <xsl:import href="./partials/html_navbar.xsl"/>
    <xsl:import href="./partials/html_footer.xsl"/>
    <xsl:import href="./partials/entities-local.xsl"/>
    <xsl:import href="./partials/register.xsl"/>
    <xsl:output encoding="UTF-8" media-type="text/html" method="html" version="5.0" indent="no" omit-xml-declaration="yes"/>

    <xsl:template match="/">
        <xsl:variable name="orgs" select="//tei:listOrg/tei:org[@xml:id]"/>
        <xsl:call-template name="registerseite">
            <xsl:with-param name="titel" select="'Institutionen'"/>
            <xsl:with-param name="einleitung">
                <p>
                    <xsl:value-of select="count($orgs)"/>
                    <xsl:text> Institutionen, die Ereignisse veranstaltet haben.</xsl:text>
                </p>
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
                        <xsl:for-each select="$orgs">
                            <tr>
                                <td>
                                    <span hidden="hidden">
                                        <xsl:value-of select="normalize-space(tei:orgName[1])"/>
                                    </span>
                                    <a href="{@xml:id}.html">
                                        <xsl:value-of select="normalize-space(tei:orgName[1])"/>
                                    </a>
                                </td>
                                <td>
                                    <xsl:value-of select="normalize-space(tei:desc[@type = 'entity_type'][1])"/>
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
        <xsl:for-each select="$orgs">
            <xsl:call-template name="entitaetsseite">
                <xsl:with-param name="name" select="normalize-space(tei:orgName[1])"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>
