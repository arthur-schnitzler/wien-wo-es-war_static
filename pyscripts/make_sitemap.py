"""Schreibt html/sitemap.xml (PLANUNG.md, Abschnitt 4).

Aufgenommen werden alle HTML-Seiten außer den Weiterleitungen der Ereignisse (pmbNNNN.html mit
meta refresh, noindex) und 404.html. Die Basis-URL kommt aus xslt/partials/params.xsl.
"""

import re
from datetime import date
from pathlib import Path
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parent.parent
HTML = ROOT / "html"
PARAMS = ROOT / "xslt" / "partials" / "params.xsl"
MAX_URLS = 50000  # Grenze einer Sitemap-Datei


def base_url():
    m = re.search(
        r'<xsl:param name="base_url">([^<]+)</xsl:param>',
        PARAMS.read_text(encoding="utf-8"),
    )
    return m.group(1).rstrip("/")


def main():
    basis = base_url()
    heute = date.today().isoformat()
    seiten = []
    for p in sorted(HTML.glob("*.html")):
        if p.name == "404.html":
            continue
        with p.open(encoding="utf-8") as f:
            kopf = f.read(600)
        if 'http-equiv="refresh"' in kopf:
            continue
        seiten.append(p.name)
    if len(seiten) > MAX_URLS:
        raise SystemExit(
            f"{len(seiten)} Seiten: mehr als {MAX_URLS}, Sitemap aufteilen"
        )
    prio = {"index.html": "1.0", "kalender.html": "0.9", "jahre.html": "0.8"}
    zeilen = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">',
    ]
    for name in seiten:
        loc = basis + "/" + ("" if name == "index.html" else name)
        zeilen.append(
            f"<url><loc>{escape(loc)}</loc><lastmod>{heute}</lastmod>"
            + (f"<priority>{prio[name]}</priority>" if name in prio else "")
            + "</url>"
        )
    zeilen.append("</urlset>")
    (HTML / "sitemap.xml").write_text("\n".join(zeilen) + "\n", encoding="utf-8")
    print(f"sitemap.xml: {len(seiten)} Seiten")


if __name__ == "__main__":
    main()
