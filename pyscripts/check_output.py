"""Prüft die gebaute Website (PLANUNG.md, Abschnitt 12).

Fehler (Exit-Code 1):
- Für jedes Ereignis: Die Tagesseite des Starttags existiert, enthält eine Karte mit
  id="pmbNNNN", und in dieser Karte steht jede idno-URL als href.
- Die Weiterleitung pmbNNNN.html existiert und zeigt auf den richtigen Tag.
- Ereignisse mit Zeitraum erscheinen an jedem Tag ihrer Dauer (data-ereignis).
- Die Summen in den Kalender-JSONs stimmen mit der Anzahl der Ereignisse pro Jahr überein.
- Die Kalenderdaten beim ersten Aufruf bleiben unter 150 KB gzip.

Warnungen (mit --streng ebenfalls Fehler):
- interne Links auf nicht vorhandene Dateien
- Größe der Site ab 800 MB, HTML-Seiten über 1 MB

Aufruf: uv run pyscripts/check_output.py [--streng]
"""

import gzip
import json
import re
import sys
from collections import Counter, defaultdict
from datetime import date, timedelta
from pathlib import Path

from lxml import etree, html

ROOT = Path(__file__).resolve().parent.parent
HTML = ROOT / "html"
INDICES = ROOT / "data" / "indices"
NS = {"tei": "http://www.tei-c.org/ns/1.0"}
XML_ID = "{http://www.w3.org/XML/1998/namespace}id"
WARNGRENZE_MB = 800

# Interne Ziele, die erst in späteren Phasen entstehen; fehlen sie, ist das nur ein Hinweis
SPAETER = {}
# Kalenderdaten beim ersten Aufruf (Übersicht, Typen, Filter, URIs und das größte Jahr), gzip
KALENDER_BUDGET_KB = 150


def lies_ereignisse():
    tree = etree.parse(str(INDICES / "listevent.xml"))
    ereignisse = []
    for ev in tree.iterfind(".//tei:event", NS):
        von = ev.get("when-iso") or ev.get("from-iso")
        bis = ev.get("to-iso") or von
        ereignisse.append(
            {
                "id": ev.get(XML_ID),
                "von": von,
                "bis": bis,
                "unbestimmt": ev.get(
                    "{https://wien-wo-es-war.acdh.oeaw.ac.at/ns}unbestimmt"
                )
                == "true",
                "urls": [
                    " ".join("".join(i.itertext()).split())
                    for i in ev.iterfind("tei:idno", NS)
                ],
            }
        )
    return ereignisse


def tage_zwischen(von, bis):
    d, ende = date.fromisoformat(von), date.fromisoformat(bis)
    while d <= ende:
        yield d.isoformat()
        d += timedelta(days=1)


def main():
    streng = "--streng" in sys.argv
    fehler = []
    warnungen = []

    ereignisse = lies_ereignisse()
    nach_tag = defaultdict(list)
    laufend_nach_tag = defaultdict(list)
    for e in ereignisse:
        nach_tag[e["von"]].append(e)
        if e["bis"] != e["von"] and not e["unbestimmt"]:
            for t in tage_zwischen(e["von"], e["bis"]):
                if t != e["von"]:
                    laufend_nach_tag[t].append(e["id"])

    # 1. Tagesseiten: Karte mit id, alle URIs als href in der Karte; laufende Ereignisse
    geprueft_urls = 0
    for tag in sorted(set(nach_tag) | set(laufend_nach_tag)):
        pfad = HTML / f"{tag}.html"
        if not pfad.exists():
            fehler.append(f"Tagesseite fehlt: {pfad.name}")
            continue
        doc = html.parse(str(pfad))
        karten = {a.get("id"): a for a in doc.iterfind(".//article[@id]")}
        for e in nach_tag.get(tag, []):
            karte = karten.get(e["id"])
            if karte is None:
                fehler.append(f"{tag}.html: Karte {e['id']} fehlt")
                continue
            hrefs = {a.get("href") for a in karte.iterfind(".//a[@href]")}
            for url in e["urls"]:
                geprueft_urls += 1
                if url not in hrefs:
                    fehler.append(f"{tag}.html#{e['id']}: URI nicht verlinkt: {url}")
        laufend_auf_seite = {
            a.get("data-ereignis") for a in doc.iterfind(".//article[@data-ereignis]")
        }
        for eid in laufend_nach_tag.get(tag, []):
            if eid not in laufend_auf_seite:
                fehler.append(f"{tag}.html: laufendes Ereignis {eid} fehlt")

    # 2. Weiterleitungen
    for e in ereignisse:
        pfad = HTML / f"{e['id']}.html"
        if not pfad.exists():
            fehler.append(f"Weiterleitung fehlt: {pfad.name}")
            continue
        ziel = f"url={e['von']}.html#{e['id']}"
        if ziel not in pfad.read_text(encoding="utf-8"):
            fehler.append(
                f"{pfad.name}: Weiterleitung zeigt nicht auf {e['von']}.html#{e['id']}"
            )

    # 3. Kalender-JSON: Summen pro Jahr
    pro_jahr = Counter(e["von"][:4] for e in ereignisse)
    uebersicht = json.loads(
        (HTML / "js-data" / "kalender" / "uebersicht.json").read_text(encoding="utf-8")
    )
    for jahr, anzahl in sorted(pro_jahr.items()):
        summe_ueb = sum(
            sum(eintrag[2::2])
            for monat in uebersicht["tage"].get(jahr, {}).values()
            for eintrag in monat
        )
        jahresdatei = HTML / "js-data" / "kalender" / f"{jahr}.json"
        summe_jahr = (
            len(json.loads(jahresdatei.read_text(encoding="utf-8"))["ereignisse"])
            if jahresdatei.exists()
            else -1
        )
        if summe_ueb != anzahl:
            fehler.append(f"uebersicht.json {jahr}: {summe_ueb} statt {anzahl}")
        if summe_jahr != anzahl:
            fehler.append(f"{jahr}.json: {summe_jahr} statt {anzahl}")

    # 3b. Ladebudget des Kalenders
    js = HTML / "js-data"
    basis = [
        js / "kalender" / "uebersicht.json",
        js / "ereignistypen.json",
        js / "kalender" / "filter.json",
        js / "uris.json",
    ]
    jahre_gz = [
        len(gzip.compress(p.read_bytes(), 9))
        for p in (js / "kalender").glob("[0-9][0-9][0-9][0-9].json")
    ]
    erster_aufruf = (
        sum(len(gzip.compress(p.read_bytes(), 9)) for p in basis) + max(jahre_gz)
    ) / 1024
    print(f"Kalender, erster Aufruf: höchstens {erster_aufruf:.0f} KB gzip")
    if erster_aufruf > KALENDER_BUDGET_KB:
        fehler.append(
            f"Kalenderdaten beim ersten Aufruf {erster_aufruf:.0f} KB > {KALENDER_BUDGET_KB} KB gzip"
        )

    # 4. Interne Links (alle Seiten außer den Weiterleitungen)
    ereignis_ids = {e["id"] for e in ereignisse}
    vorhanden = {p.name for p in HTML.iterdir()}
    fehlende_ziele = Counter()
    spaeter = Counter()
    for pfad in HTML.glob("*.html"):
        if pfad.stem in ereignis_ids:
            continue
        for href in re.findall(
            r'(?:href|src)="([^"]+)"', pfad.read_text(encoding="utf-8")
        ):
            if re.match(r"^(?:[a-z]+:|//|#)", href):
                continue
            ziel = href.split("#")[0].split("?")[0]
            if not ziel or "/" in ziel:
                if ziel and not (HTML / ziel).exists():
                    fehlende_ziele[ziel] += 1
                continue
            if ziel not in vorhanden:
                if ziel in SPAETER:
                    spaeter[ziel] += 1
                else:
                    fehlende_ziele[ziel] += 1
    if fehlende_ziele:
        beispiele = ", ".join(f"{z} ({n}×)" for z, n in fehlende_ziele.most_common(8))
        warnungen.append(
            f"{len(fehlende_ziele)} interne Linkziele fehlen, z. B. {beispiele}"
        )
    for ziel, n in spaeter.items():
        print(f"Hinweis: {ziel} fehlt noch ({SPAETER[ziel]}), {n} Verweise")

    # 5. Größenbericht
    dateien = [p for p in HTML.rglob("*") if p.is_file()]
    groesse = sum(p.stat().st_size for p in dateien)
    print(f"Größe: {groesse / 1e6:.0f} MB in {len(dateien)} Dateien")
    for p in sorted(dateien, key=lambda p: p.stat().st_size, reverse=True)[:5]:
        print(f"  {p.stat().st_size / 1024:8.0f} KB  {p.relative_to(HTML)}")
    zu_gross = [
        p.name
        for p in dateien
        if p.suffix == ".html" and p.stat().st_size > 1024 * 1024
    ]
    if zu_gross:
        warnungen.append(
            f"{len(zu_gross)} Seiten größer als 1 MB: {', '.join(zu_gross[:5])}"
        )
    if groesse / 1e6 > WARNGRENZE_MB:
        warnungen.append(f"Site größer als {WARNGRENZE_MB} MB")

    print(f"{len(ereignisse)} Ereignisse, {geprueft_urls} URIs geprüft")
    for w in warnungen:
        print(f"WARNUNG: {w}")
    for f in fehler[:50]:
        print(f"FEHLER: {f}")
    if len(fehler) > 50:
        print(f"… und {len(fehler) - 50} weitere Fehler")
    if fehler or (streng and warnungen):
        sys.exit(1)
    print("OK")


if __name__ == "__main__":
    main()
