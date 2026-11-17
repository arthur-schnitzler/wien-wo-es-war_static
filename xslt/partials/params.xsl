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
    <xsl:param name="current-colour" select="'#7A1C1C'"/>
    <!-- Lizenz der Daten auf der Website -->
    <xsl:param name="lizenz-name" select="'CC BY 4.0'"/>
    <xsl:param name="lizenz-url" select="'https://creativecommons.org/licenses/by/4.0/deed.de'"/>
    <!-- für Zitiervorschlag (Fließtext) und Zotero (citation_editors: Nachname, Vorname; …) -->
    <xsl:param name="herausgeber" select="'Peter Andorfer, Martin Anton Müller und Henrike Rost'"/>
    <xsl:param name="herausgeber-meta" select="'Andorfer, Peter; Müller, Martin Anton; Rost, Henrike'"/>
    <xsl:param name="publikationsjahr" select="'2026'"/>
    <!-- bis zum Start nicht indexieren (PLANUNG.md, Abschnitt 10: avoid_google_indexing); zum Start auf false() -->
    <xsl:param name="noindex" select="true()"/>
    <!-- Zeitraum der Daten -->
    <xsl:param name="start-year" select="1860"/>
    <xsl:param name="end-year" select="1939"/>
</xsl:stylesheet>
