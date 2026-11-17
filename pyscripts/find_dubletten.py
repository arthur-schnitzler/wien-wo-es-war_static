"""Liste mutmaßlicher Aufführungsdubletten zur Bereinigung in der PMB.

Grundlage: data/indices/listevent.xml (pyscripts/prepare_data.py) und die Register.
Ausgabe: berichte/auffuehrungsdubletten.csv (Semikolon, UTF-8 mit BOM für Excel),
eine Zeile pro Ereignis, Ereignisse einer Gruppe stehen untereinander.

Kategorien (nach Wahrscheinlichkeit einer echten Dublette):
1  quellenübergreifend, gleiches Werk – gleicher Tag, Ort und Werk, die Einträge stammen aus
   verschiedenen Quellen (z. B. Burgtheater und Schnitzler-Kultur): Ereignisse nicht zusammengeführt
2  quellenübergreifend, anderer Werkeintrag – gleicher Tag und Ort, Schnitzler-Kultur/-Briefe und
   Burgtheater/Oper verweisen auf verschiedene Werkeinträge mit ähnlichem Titel (Ähnlichkeit ab 0,6);
   nur Aufführungen (Gruppen Theater, Oper, Ballett), keine Proben oder Lesungen:
   vermutlich Ereignis- und Werkdublette
3  gleiches Werk, verschiedene Orte – gleicher Tag und Werk, aber unterschiedlicher Ort:
   Dublette mit abweichender Ortsangabe oder zwei Aufführungen
4  gleiche Quelle – gleicher Tag, Ort und Werk aus derselben Quelle: Mehrfachvorstellung
   (Nachmittag/Abend) oder Dublette in der Quelle selbst
5  abweichendes Stück – wie 2, aber die Titel sind kaum ähnlich (unter 0,6): Schnitzler-Quelle
   und Haus-Quelle nennen für Tag und Ort verschiedene Stücke; Datum, Ort oder Werk prüfen

Zusätzlich berichte/auffuehrungsdubletten_pmb.csv: pro Gruppe eine Zeile mit der niedrigsten
PMB-Nummer und den Entity-URLs aller Einträge, sortiert nach Kategorie wie oben.

Aufruf: uv run pyscripts/find_dubletten.py
"""

import csv
import re
from collections import Counter, defaultdict
from difflib import SequenceMatcher
from pathlib import Path

from lxml import etree

ROOT = Path(__file__).resolve().parent.parent
INDICES = ROOT / "data" / "indices"
AUSGABE = ROOT / "berichte" / "auffuehrungsdubletten.csv"
# Kurzfassung für die PMB: pro Gruppe eine Zeile, zuerst die niedrigste PMB-Nummer,
# dann die URLs aller Einträge der Gruppe (aufsteigend); ohne Kopfzeile
AUSGABE_PMB = ROOT / "berichte" / "auffuehrungsdubletten_pmb.csv"
PMB_ENTITY = "https://pmb.acdh.oeaw.ac.at/entity/"
SITE = "https://arthur-schnitzler.github.io/wohin-in-wien-damals_static"

NS = {"tei": "http://www.tei-c.org/ns/1.0"}
XML_ID = "{http://www.w3.org/XML/1998/namespace}id"
WIW = "{https://wohin-in-wien-damals.acdh.oeaw.ac.at/ns}"
REZENSION = "wird rezensiert in"

# Quelle eines Ereignisses: der erste vorhandene dieser Subtypes
QUELLEN = [
    ("burgtheater", "Burgtheater"),
    ("spielplan-oper_18691945", "Spielplan Oper"),
    ("brahms-online", "Brahms online"),
    ("schnitzler-kultur", "Schnitzler-Kultur"),
    ("schnitzler-briefe", "Schnitzler-Briefe"),
]
HAUSQUELLEN = {"burgtheater", "spielplan-oper_18691945"}
# Für die Kategorien 2 und 5 zählen nur Aufführungen; Proben und Lesungen finden neben Vorstellungen statt
AUFFUEHRUNGSGRUPPEN = {"theater", "oper", "ballett"}
SCHNITZLER = {"schnitzler-kultur", "schnitzler-briefe"}

KATEGORIEN = {
    1: "quellenübergreifend, gleiches Werk",
    2: "quellenübergreifend, anderer Werkeintrag",
    3: "gleiches Werk, verschiedene Orte",
    4: "gleiche Quelle",
    5: "abweichendes Stück",
}
AEHNLICH = 0.6


def text(el):
    return " ".join("".join(el.itertext()).split()) if el is not None else ""


def namen():
    n = {}
    for datei, pfad, name in [
        ("listplace.xml", ".//tei:place", "tei:placeName"),
        ("listbibl.xml", ".//tei:bibl", "tei:title"),
    ]:
        for el in etree.parse(str(INDICES / datei)).iterfind(pfad, NS):
            if el.get(XML_ID):
                n[el.get(XML_ID)] = text(el.find(name, NS))
    return n


def kern(titel):
    """Titel für den Vergleich: ohne Untertitel, Klammerzusatz, Satzzeichen; ß → ss."""
    t = titel.split(". ")[0]
    t = re.sub(r"\(.*?\)", "", t).lower().replace("ß", "ss")
    t = re.sub(r"[^\wäöü ]", " ", t)
    return " ".join(t.split())


def aehnlichkeit(a, b):
    ka, kb = kern(a), kern(b)
    if not ka or not kb:
        return 0.0
    if ka in kb or kb in ka:
        return 1.0
    return SequenceMatcher(None, ka, kb).ratio()


def lies_ereignisse():
    ereignisse = []
    for ev in etree.parse(str(INDICES / "listevent.xml")).iterfind(".//tei:event", NS):
        idnos = [(i.get("subtype", ""), text(i)) for i in ev.iterfind("tei:idno", NS)]
        subtypes = {s for s, _ in idnos}
        quelle = next((q for q, _ in QUELLEN if q in subtypes), "")
        werke = sorted(
            b.find("tei:title", NS).get("key")
            for b in ev.xpath("tei:listBibl/tei:bibl[tei:title/@key]", namespaces=NS)
            if text(b.find("tei:note[@type='relation-type']", NS)) != REZENSION
        )
        ereignisse.append(
            {
                "id": ev.get(XML_ID),
                "tag": ev.get("when-iso") or ev.get("from-iso"),
                "typ": ev.get(f"{WIW}typ", ""),
                "gruppe": ev.get(f"{WIW}gruppe", ""),
                "titel": text(ev.find("tei:eventName", NS)),
                "werke": tuple(werke),
                "orte": tuple(
                    sorted(
                        p.get("key")
                        for p in ev.iterfind("tei:listPlace//tei:placeName[@key]", NS)
                    )
                ),
                "quelle": quelle,
                "quell_url": next((u for s, u in idnos if s == quelle), ""),
                "pmb_urls": [u for s, u in idnos if s == "pmb"],
            }
        )
    return ereignisse


def main():
    n = namen()
    ereignisse = [e for e in lies_ereignisse() if e["werke"]]
    gruppen = []  # (kategorie, [ereignisse], aehnlichkeit)
    vergeben = set()  # Ereignisse, die schon in einer stärkeren Kategorie stehen

    nach_tag_ort_werk = defaultdict(list)
    nach_tag_werk = defaultdict(list)
    nach_tag_ort = defaultdict(list)
    for e in ereignisse:
        nach_tag_ort_werk[(e["tag"], e["orte"], e["werke"])].append(e)
        nach_tag_werk[(e["tag"], e["werke"])].append(e)
        nach_tag_ort[(e["tag"], e["orte"])].append(e)

    # 1 und 4: gleicher Tag, Ort, Werk
    for v in nach_tag_ort_werk.values():
        if len(v) > 1:
            kat = 1 if len({e["quelle"] for e in v}) > 1 else 4
            gruppen.append((kat, v, None))
            vergeben.update(e["id"] for e in v)

    # 2: gleicher Tag und Ort, Schnitzler-Quelle vs. Burgtheater/Oper, kein gemeinsames Werk
    for v in nach_tag_ort.values():
        schn = [
            e
            for e in v
            if e["quelle"] in SCHNITZLER
            and e["id"] not in vergeben
            and e["gruppe"] in AUFFUEHRUNGSGRUPPEN
        ]
        haus = [
            e
            for e in v
            if e["quelle"] in HAUSQUELLEN and e["gruppe"] in AUFFUEHRUNGSGRUPPEN
        ]
        for s in schn:
            if any(set(s["werke"]) & set(h["werke"]) for h in haus):
                continue
            kandidaten = []
            for h in haus:
                score = max(
                    aehnlichkeit(n.get(a, ""), n.get(b, ""))
                    for a in s["werke"]
                    for b in h["werke"]
                )
                kandidaten.append((score, h))
            if kandidaten:
                score, bester = max(kandidaten, key=lambda k: k[0])
                gruppen.append(
                    (2 if score >= AEHNLICH else 5, [s, bester], round(score, 2))
                )
                vergeben.add(s["id"])

    # 3: gleicher Tag und Werk, verschiedene Orte
    for v in nach_tag_werk.values():
        if len({e["orte"] for e in v}) > 1:
            rest = [e for e in v if e["id"] not in vergeben]
            if rest:
                gruppen.append((3, v, None))

    gruppen.sort(key=lambda g: (g[0], -(g[2] or 0), g[1][0]["tag"]))
    quellname = dict(QUELLEN)

    AUSGABE.parent.mkdir(exist_ok=True)
    with open(AUSGABE, "w", newline="", encoding="utf-8-sig") as f:
        w = csv.writer(f, delimiter=";")
        w.writerow(
            [
                "gruppe",
                "kategorie",
                "kategorie_text",
                "titel_aehnlichkeit",
                "datum",
                "pmb_id",
                "pmb_url",
                "typ",
                "eventName",
                "werke",
                "werk_ids",
                "orte",
                "ort_ids",
                "quelle",
                "quell_url",
                "tagesseite",
            ]
        )
        for nr, (kat, v, score) in enumerate(gruppen, start=1):
            for e in v:
                w.writerow(
                    [
                        nr,
                        kat,
                        KATEGORIEN[kat],
                        "" if score is None else str(score).replace(".", ","),
                        e["tag"],
                        e["id"],
                        " ".join(e["pmb_urls"]),
                        e["typ"],
                        e["titel"],
                        " | ".join(n.get(k, k) for k in e["werke"]),
                        " ".join(e["werke"]),
                        " | ".join(n.get(k, k) for k in e["orte"]),
                        " ".join(e["orte"]),
                        quellname.get(e["quelle"], ""),
                        e["quell_url"],
                        f"{SITE}/{e['tag']}.html#{e['id']}",
                    ]
                )

    with open(AUSGABE_PMB, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        for _, v, _ in gruppen:
            nummern = sorted({int(e["id"].removeprefix("pmb")) for e in v})
            w.writerow([nummern[0]] + [f"{PMB_ENTITY}{n}" for n in nummern])

    zaehler = Counter(k for k, _, _ in gruppen)
    ereignisse_je = Counter()
    for k, v, _ in gruppen:
        ereignisse_je[k] += len(v)
    for k in sorted(KATEGORIEN):
        print(
            f"{k} {KATEGORIEN[k]}: {zaehler[k]} Gruppen, {ereignisse_je[k]} Ereignisse"
        )
    print(f"→ {AUSGABE.relative_to(ROOT)}")
    print(f"→ {AUSGABE_PMB.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
