<?xml version="1.0" encoding="UTF-8"?>
<!--
    Projektschicht über entities.xsl (aus schnitzler-chronik-static, synchronisiert mit
    check_entities_xsl.py). Hier stehen nur Einstellungen und Überschreibungen für
    Wien, wo es war; entities.xsl selbst bleibt unverändert.

    Die Ereignisse einer Entität stehen als note[@type='mentions'] in den Registerkopien
    (pyscripts/prepare_data.py), entities.xsl zeigt sie im Normalmodus an.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:mam="whatever" exclude-result-prefixes="#all" version="3.0">

    <xsl:import href="./entities.xsl"/>

    <xsl:param name="mentions-start-year" as="xs:integer" select="$start-year"/>
    <xsl:param name="mentions-end-year" as="xs:integer" select="$end-year"/>
    <!-- darüber nur Jahresblöcke mit Link in den gefilterten Kalender (Seiten bleiben unter 1 MB) -->
    <xsl:param name="mentions-max-inline" as="xs:integer" select="2500"/>
    <xsl:param name="mentions-tab-label" as="xs:string" select="'Ereignisse'"/>

    <!-- Filterparameter des Kalenders je Entitätstyp -->
    <xsl:function name="mam:kalender-param" as="xs:string">
        <xsl:param name="entity" as="element()"/>
        <xsl:sequence select="
                if ($entity/self::tei:person) then 'person'
                else if ($entity/self::tei:place) then 'ort'
                else if ($entity/self::tei:org) then 'institution'
                else 'werk'"/>
    </xsl:function>

    <xsl:template name="mentions-year-overflow">
        <xsl:param name="entity"/>
        <xsl:param name="year" as="xs:integer"/>
        <xsl:param name="year-count" as="xs:integer"/>
        <p class="mentions-overflow">
            <a href="kalender.html?ansicht=jahr&amp;datum={$year}&amp;{mam:kalender-param($entity)}={$entity/@xml:id}">
                <xsl:value-of select="$year-count"/>
                <xsl:text> Ereignisse </xsl:text>
                <xsl:value-of select="$year"/>
                <xsl:text> im Kalender zeigen</xsl:text>
            </a>
        </p>
    </xsl:template>

    <!-- „Im Kalender zeigen“ über dem Steckbrief -->
    <xsl:template name="kalender-knopf">
        <xsl:param name="entity" as="element()"/>
        <xsl:variable name="n" select="count($entity/tei:noteGrp[@type = 'ereignisse']/tei:note)"/>
        <xsl:if test="$n gt 0">
            <div class="entity-kalender d-flex justify-content-end">
                <a class="btn btn-sm btn-outline-secondary"
                    href="kalender.html?ansicht=zeitraum&amp;{mam:kalender-param($entity)}={$entity/@xml:id}">
                    <i class="bi bi-calendar3" aria-hidden="true"></i>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="if ($n = 1) then '1 Ereignis' else concat($n, ' Ereignisse')"/>
                    <xsl:text> im Kalender zeigen</xsl:text>
                </a>
            </div>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>
