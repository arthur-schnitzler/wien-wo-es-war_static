#!/bin/bash
# Lädt das Impressum vom ACDH-Impressumsdienst.
# Die Redmine-ID des Projekts ist noch offen (PLANUNG.md, Abschnitt 13).
# Sie wird über die Umgebungsvariable REDMINE_ID gesetzt; ohne sie entsteht ein Platzhalter.
set -euo pipefail

REDMINE_ID="${REDMINE_ID:-}"
IMPRINT_XML=./data/imprint.xml
mkdir -p ./data

if [ -z "${REDMINE_ID}" ]; then
    echo "REDMINE_ID nicht gesetzt, schreibe Platzhalter-Impressum"
    cat > "${IMPRINT_XML}" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<root>
<div lang="de"><p>Das Impressum folgt.</p></div>
<div lang="en"><p>Imprint to follow.</p></div>
</root>
EOF
    exit 0
fi

{
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo "<root>"
    echo '<div lang="de">'
    curl -fsS "https://imprint.acdh.oeaw.ac.at/${REDMINE_ID}?format=xhtml&locale=de"
    echo "</div>"
    echo '<div lang="en">'
    curl -fsS "https://imprint.acdh.oeaw.ac.at/${REDMINE_ID}?format=xhtml&locale=en"
    echo "</div>"
    echo "</root>"
} > "${IMPRINT_XML}"
