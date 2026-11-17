<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
    <xsl:param name="directory_name">wohin-in-wien-damals_static</xsl:param>
    <xsl:param name="project_title">Wohin in Wien damals. Kulturelle Ereignisse in Wien 1860–1939</xsl:param>
    <!-- offen (PLANUNG.md, Abschnitt 13) -->
    <xsl:param name="redmine_id"/>
    <xsl:param name="project_short_title">Wohin in Wien damals</xsl:param>
    <xsl:param name="default_lang">de</xsl:param>
    <xsl:param name="github_url">https://github.com/arthur-schnitzler/wohin-in-wien-damals_static</xsl:param>
    <xsl:param name="html_title">Wohin in Wien damals</xsl:param>
    <xsl:param name="project_logo">images/logo.png</xsl:param>
    <xsl:param name="DATAHASH" select="''"/>
    <!-- vorläufig, Domain offen (PLANUNG.md, Abschnitt 13) -->
    <xsl:param name="base_url">https://wohin-in-wien-damals.acdh.oeaw.ac.at</xsl:param>
    <xsl:param name="data_repo">https://github.com/arthur-schnitzler/wohin-in-wien-damals_data</xsl:param>
    <xsl:param name="current-edition" select="'wohin-in-wien-damals'"/>
    <!-- vorläufig, Projektfarbe offen (PLANUNG.md, Abschnitt 13) -->
    <xsl:param name="current-colour" select="'#8C2F39'"/>
    <!-- für Zitiervorschlag und Zotero; Herausgeber:innen noch offen -->
    <xsl:param name="herausgeber" select="''"/>
    <xsl:param name="publikationsjahr" select="'2026'"/>
    <!-- bis zum Start nicht indexieren (PLANUNG.md, Abschnitt 10: avoid_google_indexing); zum Start auf false() -->
    <xsl:param name="noindex" select="true()"/>
    <!-- Zeitraum der Daten -->
    <xsl:param name="start-year" select="1860"/>
    <xsl:param name="end-year" select="1939"/>
</xsl:stylesheet>
