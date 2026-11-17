<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="#all"
    version="2.0">
    <xsl:template name="html_footer">
        <footer class="py-3 bg-body-tertiary">
            <p class="text-center small mb-2">
                <xsl:text>Daten: </xsl:text>
                <a href="{$lizenz-url}" rel="license"><xsl:value-of select="$lizenz-name"/></a>
                <xsl:text> · </xsl:text>
                <a href="ueber-das-projekt.html#lizenz">Lizenz und Nachnutzung</a>
                <xsl:text> · </xsl:text>
                <a href="imprint.html">Impressum</a>
            </p>
            <div class="text-center">
                <a href="{$github_url}">
                    <i aria-hidden="true" class="bi bi-github fs-2"></i>
                    <span class="visually-hidden">GitHub repo</span>
                </a>
                <xsl:if test="$DATAHASH">
                    <span class="fs-2"><xsl:text> | </xsl:text></span>
                    <a href="{$data_repo||'/tree/'||$DATAHASH}">
                        <i class="bi bi-filetype-xml fs-2"></i>
                        <span class="visually-hidden">GitHub data repo</span>
                    </a>
                </xsl:if>
            </div>
        </footer>
        <script src="vendor/jquery/jquery-3.7.1.min.js"></script>
        <script src="vendor/bootstrap-5.3.5-dist/js/bootstrap.bundle.min.js"></script>
        
    </xsl:template>
</xsl:stylesheet>