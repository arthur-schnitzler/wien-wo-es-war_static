<?xml version="1.0" encoding="UTF-8"?>
<!-- Datumsformatierung auf Deutsch (österreichisch: „Jänner“), unabhängig von der Lokalisierung in Saxon HE -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:wiw="https://wohin-in-wien-damals.acdh.oeaw.ac.at/ns"
    exclude-result-prefixes="#all" version="3.0">

    <xsl:variable name="wiw:monate" as="xs:string+"
        select="('Jänner', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember')"/>
    <xsl:variable name="wiw:wochentage" as="xs:string+"
        select="('Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag')"/>

    <xsl:function name="wiw:monat" as="xs:string">
        <xsl:param name="m" as="xs:integer"/>
        <xsl:sequence select="$wiw:monate[$m]"/>
    </xsl:function>

    <!-- 1 = Montag … 7 = Sonntag; 1.1.1900 war ein Montag -->
    <xsl:function name="wiw:wochentag-nr" as="xs:integer">
        <xsl:param name="d" as="xs:date"/>
        <xsl:variable name="tage" select="xs:integer(($d - xs:date('1900-01-01')) div xs:dayTimeDuration('P1D'))"/>
        <xsl:sequence select="(($tage mod 7) + 7) mod 7 + 1"/>
    </xsl:function>

    <xsl:function name="wiw:wochentag" as="xs:string">
        <xsl:param name="d" as="xs:date"/>
        <xsl:sequence select="$wiw:wochentage[wiw:wochentag-nr($d)]"/>
    </xsl:function>

    <!-- 1. Jänner 1900 -->
    <xsl:function name="wiw:datum" as="xs:string">
        <xsl:param name="d" as="xs:date"/>
        <xsl:sequence select="concat(day-from-date($d), '. ', wiw:monat(month-from-date($d)), ' ', year-from-date($d))"/>
    </xsl:function>

    <!-- Montag, 1. Jänner 1900 -->
    <xsl:function name="wiw:datum-lang" as="xs:string">
        <xsl:param name="d" as="xs:date"/>
        <xsl:sequence select="concat(wiw:wochentag($d), ', ', wiw:datum($d))"/>
    </xsl:function>

    <!-- Jänner 1900 -->
    <xsl:function name="wiw:monat-jahr" as="xs:string">
        <xsl:param name="d" as="xs:date"/>
        <xsl:sequence select="concat(wiw:monat(month-from-date($d)), ' ', year-from-date($d))"/>
    </xsl:function>

    <!-- 3.–6. Oktober 1926 · 13. Mai – 25. Juni 1922 · 11. Dezember 1927 – 15. Jänner 1928 -->
    <xsl:function name="wiw:zeitraum" as="xs:string">
        <xsl:param name="von" as="xs:date"/>
        <xsl:param name="bis" as="xs:date"/>
        <xsl:choose>
            <xsl:when test="$von = $bis">
                <xsl:sequence select="wiw:datum($von)"/>
            </xsl:when>
            <xsl:when test="year-from-date($von) != year-from-date($bis)">
                <xsl:sequence select="concat(wiw:datum($von), ' – ', wiw:datum($bis))"/>
            </xsl:when>
            <xsl:when test="month-from-date($von) != month-from-date($bis)">
                <xsl:sequence select="concat(day-from-date($von), '. ', wiw:monat(month-from-date($von)), ' – ', wiw:datum($bis))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="concat(day-from-date($von), '.–', wiw:datum($bis))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- 1900-01-01 -->
    <xsl:function name="wiw:iso" as="xs:string">
        <xsl:param name="d" as="xs:date"/>
        <xsl:sequence select="format-date($d, '[Y0001]-[M01]-[D01]')"/>
    </xsl:function>
</xsl:stylesheet>
