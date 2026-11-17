"""Bereitet die Daten aus dem Daten-Repo für den Build vor.

Siehe PLANUNG.md, Abschnitt 10 (Build-Ablauf, Schritt 2). Erzeugt:

- data/indices/listevent.xml   alle Jahresdateien in einer Datei (für entities.xsl)
- data/indices/tage.xml        alle Tage mit Ereignissen (für vor/zurück über Jahresgrenzen)
- data/indices/mehrtaegig.xml  Ereignisse mit Zeitraum (@from-iso/@to-iso)
- html/js-data/kalender/uebersicht.json  Tag -> Ereignisgruppe -> Anzahl
- html/js-data/kalender/JJJJ.json        Ereignisse eines Jahres für den Kalender
- html/js-data/ereignistypen.json        Ereignisgruppen und Zuordnung der Typen

Bricht ab, wenn ein Ereignistyp keiner Gruppe zugeordnet ist (config/ereignistypen.csv).
"""

import csv
import gzip
import json
import re
import sys
from collections import Counter, defaultdict
from datetime import date, timedelta
from pathlib import Path

from lxml import etree

ROOT = Path(__file__).resolve().parent.parent
EDITIONS = ROOT / "data" / "editions"
INDICES = ROOT / "data" / "indices"
CONFIG = ROOT / "config"
JS_DATA = ROOT / "html" / "js-data"

TEI_NS = "http://www.tei-c.org/ns/1.0"
XML_ID = "{http://www.w3.org/XML/1998/namespace}id"
NS = {"tei": TEI_NS, "xml": "http://www.w3.org/XML/1998/namespace"}
# Namensraum für projekteigene Zusatzattribute in data/indices/listevent.xml
WIW_NS = "https://wohin-in-wien-damals.acdh.oeaw.ac.at/ns"

# Typ für Ereignisse ohne eventName/@n (PLANUNG.md, Datenhinweise)
TYP_OHNE_ANGABE = "Veranstaltung"

# Positivliste der Sammlungen, die als „Quelle“ gezeigt werden (PLANUNG.md, Datenhinweise).
# Schlüssel ist bibl[@type='collections']/@n, Wert die Kurzbezeichnung.
QUELLEN = {
    "84": "Burgtheater",
    "122": "Spielplan Oper",
    "44": "Schnitzler-Kultur",
    "28": "Brahms online",
    "120": "Kalbeck-Tagebücher",
    "5": "Kraus-Rechtsakten",
}

# Datum am Ende von eventName, z. B. „, 1.1.1900“, „ 11.4.1891“, „, [4.?]10.1886“,
# „, 13.5.–25.6.1922“, „, 5.3.1926–11.4.1926“, „, 3.–6.10.1926“, „, Februar 1886“
MONATE = "Jänner|Januar|Februar|März|April|Mai|Juni|Juli|August|September|Oktober|November|Dezember"
_TAG = r"\[?\d{1,2}(?:\[\?\])?\.?\??\]?\.?"
_DATUM_ZAHL = rf"{_TAG}\s*(?:\d{{1,2}}\.\s*)?(?:\d{{4}})?\??"
_DATUM = rf"(?:{_DATUM_ZAHL}|(?:{MONATE})(?:\s*\d{{4}})?\??)"
# Ein Monatsname zählt nur nach einem Komma als Datum („Premiere von Dritter November 1918“ bleibt)
DATUM_AM_ENDE = re.compile(
    rf"(?:,\s*{_DATUM}|\s+{_DATUM_ZAHL})(?:\s*(?:–|-|bis)\s*{_DATUM})?\s*$"
)


def tei(tag):
    return f"{{{TEI_NS}}}{tag}"


def text(el):
    return " ".join("".join(el.itertext()).split()) if el is not None else ""


def titel_ohne_datum(titel):
    """Entfernt das Datum am Ende von eventName („Aufführung von X, 1.1.1900“ -> „Aufführung von X“)."""
    ohne = DATUM_AM_ENDE.sub("", titel).rstrip(" ,")
    # Nur übernehmen, wenn tatsächlich eine Jahreszahl oder ein Monat entfernt wurde
    entfernt = titel[len(ohne) :]
    if ohne and re.search(rf"\d{{4}}|{MONATE}|\d{{1,2}}\.\d{{1,2}}\.", entfernt):
        return ohne
    return titel


def lies_konfiguration():
    gruppen = []
    with open(CONFIG / "ereignisgruppen.csv", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            gruppen.append(
                {
                    "id": row["id"],
                    "label": row["label"],
                    "reihenfolge": int(row["reihenfolge"]),
                    "farbe": row["farbe"],
                }
            )
    gruppen.sort(key=lambda g: g["reihenfolge"])
    gruppen_ids = {g["id"] for g in gruppen}
    typen = {}
    with open(CONFIG / "ereignistypen.csv", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            if row["gruppe"] not in gruppen_ids:
                sys.exit(
                    f"config/ereignistypen.csv: unbekannte Gruppe „{row['gruppe']}“ bei Typ „{row['typ']}“"
                )
            typen[row["typ"]] = row["gruppe"]
    return gruppen, typen


def lies_register():
    """Namen aller Entitäten und Urheber:innen der Werke."""
    namen = {}
    tree = etree.parse(str(INDICES / "listperson.xml"))
    for p in tree.iterfind(".//tei:person[@xml:id]", NS):
        pn = p.find("tei:persName", NS)
        vor = text(pn.find("tei:forename", NS)) if pn is not None else ""
        nach = text(pn.find("tei:surname", NS)) if pn is not None else ""
        name = " ".join(x for x in (vor, nach) if x) or text(pn)
        namen[p.get(XML_ID)] = name
    tree = etree.parse(str(INDICES / "listplace.xml"))
    for p in tree.iterfind(".//tei:place[@xml:id]", NS):
        namen[p.get(XML_ID)] = text(p.find("tei:placeName", NS))
    tree = etree.parse(str(INDICES / "listorg.xml"))
    for o in tree.iterfind(".//tei:org[@xml:id]", NS):
        namen[o.get(XML_ID)] = text(o.find("tei:orgName", NS))
    urheber = {}
    tree = etree.parse(str(INDICES / "listbibl.xml"))
    for b in tree.iterfind(".//tei:bibl[@xml:id]", NS):
        titel = b.find("tei:title[@type='main']", NS)
        if titel is None:
            titel = b.find("tei:title", NS)
        namen[b.get(XML_ID)] = text(titel)
        urheber[b.get(XML_ID)] = [
            [a.get("key"), a.get("role", "")]
            for a in b.iterfind("tei:author[@key]", NS)
        ]
    return namen, urheber


def tage_zwischen(von, bis):
    d = date.fromisoformat(von)
    ende = date.fromisoformat(bis)
    while d <= ende:
        yield d.isoformat()
        d += timedelta(days=1)


def ist_unbestimmter_monat(von, bis):
    """„Februar 1886“ steht als 1.–28.2.1886 in den Daten: ein Tag in diesem Monat, kein Zeitraum."""
    v, b = date.fromisoformat(von), date.fromisoformat(bis)
    return v.day == 1 and (v.year, v.month) == (b.year, b.month) and b.day >= 28


def ereignis_daten(ev, typen, urheber_von, fehlende_typen):
    eid = ev.get(XML_ID)
    when = ev.get("when-iso")
    von = ev.get("from-iso") or when
    bis = ev.get("to-iso") or von
    if not von:
        sys.exit(f"{eid}: Ereignis ohne Datum")
    en = ev.find("tei:eventName", NS)
    typ = (en.get("n") if en is not None else None) or TYP_OHNE_ANGABE
    if typ not in typen:
        fehlende_typen[typ] += 1
    werke = []
    urheber = []
    for b in ev.xpath("tei:listBibl/tei:bibl[tei:title/@key]", namespaces=NS):
        key = b.find("tei:title", NS).get("key")
        werke.append([key, text(b.find("tei:note[@type='relation-type']", NS))])
        for a in urheber_von.get(key, []):
            if a not in urheber:
                urheber.append(a)
    daten = {
        "id": eid,
        "datum": von,
        "typ": typ,
        "titel": titel_ohne_datum(text(en)),
        "orte": [
            p.get("key") for p in ev.iterfind("tei:listPlace//tei:placeName[@key]", NS)
        ],
        "institutionen": [
            o.get("key") for o in ev.iterfind(".//tei:listOrg//tei:orgName[@key]", NS)
        ],
        "werke": werke,
        "urheber": urheber,
        "personen": [
            [pn.get("key"), pn.getparent().get("role", "")]
            for pn in ev.iterfind("tei:listPerson/tei:person/tei:persName[@key]", NS)
        ],
        "quellen": [
            QUELLEN[b.get("n")]
            for b in ev.iterfind("tei:listBibl/tei:bibl[@type='collections']", NS)
            if b.get("n") in QUELLEN
        ],
        "uris": [[i.get("subtype", ""), text(i)] for i in ev.iterfind("tei:idno", NS)],
    }
    if bis != von:
        daten["ende"] = bis
        if ist_unbestimmter_monat(von, bis):
            daten["unbestimmt"] = True
    # leere Listen weglassen, das spart Platz in den Jahresdateien
    return {k: v for k, v in daten.items() if v not in ([], "")}


# Kompaktformat der Jahresdateien (html/js-data/kalender/JJJJ.json):
# - uris: [subtype, url]; beginnt url nicht mit „http“, ist praefixe[subtype] voranzustellen
# - werke: [key] oder [key, beziehung]; ohne Beziehung gilt STANDARD_BEZIEHUNG
# - urheber: auf oberster Ebene je Werk statt je Ereignis
# - titel: fehlt, wenn er „Aufführung von <Werktitel>“ lautet (Anzeige dann aus dem Werktitel)
URI_PRAEFIXE = {
    "pmb": "https://pmb.acdh.oeaw.ac.at/entity/",
    "burgtheater": "https://kulturerbe.burgtheater.at/event/",
    "spielplan-oper_18691945": "https://www.mdw.ac.at/imi/operapolitics/spielplan-wiener-oper/web/opus/",
    "anno": "https://anno.onb.ac.at/cgi-content/anno?",
    "schnitzler-kultur": "https://schnitzler-kultur.acdh.oeaw.ac.at/",
    "schnitzler-briefe": "https://schnitzler-briefe.acdh.oeaw.ac.at/",
    "brahms-online": "https://brahms-online.oeaw.ac.at/",
}
STANDARD_BEZIEHUNG = "ist Aufführung von"


def kompakt(d, namen):
    k = {
        key: v
        for key, v in d.items()
        if key not in ("urheber", "uris", "werke", "titel")
    }
    werke = d.get("werke", [])
    if werke:
        k["werke"] = [
            [w] if rel == STANDARD_BEZIEHUNG else [w, rel] for w, rel in werke
        ]
    titel = d.get("titel", "")
    ableitbar = len(werke) == 1 and titel in (
        f"Aufführung von {namen.get(werke[0][0], '')}",
        f"Aufführung von {namen.get(werke[0][0], '').split('. ')[0]}",
    )
    if titel and not ableitbar:
        k["titel"] = titel
    uris = []
    for subtype, url in d.get("uris", []):
        praefix = URI_PRAEFIXE.get(subtype)
        if praefix and url.startswith(praefix):
            url = url[len(praefix) :]
        uris.append([subtype, url])
    if uris:
        k["uris"] = uris
    return k


def schreibe_json(pfad, daten):
    pfad.parent.mkdir(parents=True, exist_ok=True)
    roh = json.dumps(daten, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    pfad.write_bytes(roh)
    return len(roh), len(gzip.compress(roh))


def schreibe_xml(pfad, root):
    etree.ElementTree(root).write(
        str(pfad), encoding="UTF-8", xml_declaration=True, pretty_print=True
    )


def tei_kopf(titel):
    root = etree.Element(tei("TEI"), nsmap={None: TEI_NS, "wiw": WIW_NS})
    header = etree.SubElement(root, tei("teiHeader"))
    fd = etree.SubElement(header, tei("fileDesc"))
    ts = etree.SubElement(fd, tei("titleStmt"))
    etree.SubElement(ts, tei("title"), level="s").text = "Wohin in Wien damals"
    etree.SubElement(ts, tei("title"), type="main").text = titel
    etree.SubElement(
        etree.SubElement(fd, tei("publicationStmt")), tei("p")
    ).text = "Wohin in Wien damals, automatisch erzeugte Daten"
    etree.SubElement(
        etree.SubElement(fd, tei("sourceDesc")), tei("p")
    ).text = "Zusammengeführt aus den Jahresdateien editions/listevent_JJJJ.xml durch pyscripts/prepare_data.py"
    return root


def lies_uri_liste():
    """xslt/list-of-relevant-uris.xml als {subtype: [Beschriftung, Rang]}; Rang wie auf den Karten."""
    rang_gruppe = {"quelle": 1, "projekt": 2, "normdaten": 4}
    liste = {}
    root = etree.parse(str(ROOT / "xslt" / "list-of-relevant-uris.xml")).getroot()
    for i, item in enumerate(root.iterfind("item")):
        abbr = item.findtext("abbr", "").strip()
        if abbr and abbr not in liste:
            rang = rang_gruppe.get(item.get("group"), 2) * 1000 + i
            liste[abbr] = [
                item.findtext("caption", "").strip(),
                rang,
                item.find("color") is not None,
            ]
    return liste


def main():
    gruppen, typen = lies_konfiguration()
    namen, urheber_von = lies_register()
    parser = etree.XMLParser(remove_blank_text=True)

    gesamt = tei_kopf("Ereignisse in Wien 1860–1939")
    gesamt_list = etree.SubElement(
        etree.SubElement(etree.SubElement(gesamt, tei("text")), tei("body")),
        tei("listEvent"),
    )

    fehlende_typen = Counter()
    pro_tag = defaultdict(
        Counter
    )  # Tag -> Gruppe -> Anzahl der an diesem Tag beginnenden Ereignisse
    laufend = defaultdict(
        list
    )  # Tag -> Ereignisse mit Zeitraum, die an diesem Tag laufen (ohne Starttag)
    mehrtaegig = []
    jahre = {}
    gzip_groessen = {}

    dateien = sorted(EDITIONS.glob("listevent_*.xml"))
    if not dateien:
        sys.exit(
            f"keine Jahresdateien in {EDITIONS}; zuerst shellscripts/fetch_data.sh ausführen"
        )

    for datei in dateien:
        jahr = int(re.search(r"(\d{4})", datei.name).group(1))
        tree = etree.parse(str(datei), parser)
        ereignisse = []
        for ev in tree.iterfind(".//tei:listEvent/tei:event", NS):
            d = ereignis_daten(ev, typen, urheber_von, fehlende_typen)
            # Kopie für listevent.xml, ergänzt um Anzeigetitel (ohne Datum), Typ und Gruppe,
            # damit die Stylesheets diese Logik nicht wiederholen müssen
            kopie = etree.fromstring(etree.tostring(ev))
            kopie.set(f"{{{WIW_NS}}}titel", d.get("titel", ""))
            kopie.set(f"{{{WIW_NS}}}typ", d["typ"])
            kopie.set(f"{{{WIW_NS}}}gruppe", typen.get(d["typ"], ""))
            if d.get("unbestimmt"):
                kopie.set(f"{{{WIW_NS}}}unbestimmt", "true")
            gesamt_list.append(kopie)
            ereignisse.append(d)
            if d["typ"] in typen:
                pro_tag[d["datum"]][typen[d["typ"]]] += 1
            if "ende" in d:
                mehrtaegig.append(d)
                if not d.get("unbestimmt"):
                    for tag in tage_zwischen(d["datum"], d["ende"]):
                        if tag != d["datum"]:
                            laufend[tag].append(d["id"])
        jahre[jahr] = ereignisse

    if fehlende_typen:
        liste = "\n".join(f"  {t} ({n}×)" for t, n in fehlende_typen.most_common())
        sys.exit(
            "Ereignistypen ohne Gruppe – bitte in config/ereignistypen.csv ergänzen:\n"
            + liste
        )

    # Jahresdateien für den Kalender, jeweils mit den Namen der vorkommenden Entitäten
    for jahr, ereignisse in jahre.items():
        keys = set()
        werke = set()
        for d in ereignisse:
            keys.update(d.get("orte", []))
            keys.update(d.get("institutionen", []))
            werke.update(k for k, _ in d.get("werke", []))
            keys.update(k for k, _ in d.get("urheber", []))
            keys.update(k for k, _ in d.get("personen", []))
        keys |= werke
        _, gz = schreibe_json(
            JS_DATA / "kalender" / f"{jahr}.json",
            {
                "jahr": jahr,
                "praefixe": URI_PRAEFIXE,
                "standard_beziehung": STANDARD_BEZIEHUNG,
                "ereignisse": [kompakt(d, namen) for d in ereignisse],
                "urheber": {
                    w: urheber_von[w] for w in sorted(werke) if urheber_von.get(w)
                },
                "namen": {k: namen.get(k, k) for k in sorted(keys)},
            },
        )
        gzip_groessen[jahr] = gz

    # uebersicht.json, kompakt: tage[JJJJ][MM] = [[Tag, Gruppenindex, Anzahl, Gruppenindex, Anzahl, …], …]
    # Gruppenindex bezieht sich auf die Liste „gruppen“.
    gruppen_ids = [g["id"] for g in gruppen]
    tage_kompakt = defaultdict(lambda: defaultdict(list))
    for tag, c in sorted(pro_tag.items()):
        j, m, t = tag.split("-")
        eintrag = [int(t)]
        for i, g in enumerate(gruppen_ids):
            if c[g]:
                eintrag += [i, c[g]]
        tage_kompakt[j][m].append(eintrag)
    uebersicht = {
        "gruppen": gruppen_ids,
        "tage": tage_kompakt,
        "laufend": {tag: ids for tag, ids in sorted(laufend.items())},
        # Ereignisse mit Zeitraum: id -> [von, bis]; damit findet der Kalender das Jahr eines
        # laufenden Ereignisses, das in einem früheren Jahr begonnen hat
        "zeitraeume": {
            d["id"]: [d["datum"], d["ende"]]
            for d in mehrtaegig
            if not d.get("unbestimmt")
        },
    }
    _, gz_uebersicht = schreibe_json(
        JS_DATA / "kalender" / "uebersicht.json", uebersicht
    )
    schreibe_json(JS_DATA / "ereignistypen.json", {"gruppen": gruppen, "typen": typen})

    # Auswahllisten für die Kalenderfilter: Spielstätten, Institutionen, Quellen mit Anzahl
    alle = [d for e in jahre.values() for d in e]
    zaehle = lambda feld: Counter(k for d in alle for k in d.get(feld, []))
    schreibe_json(
        JS_DATA / "kalender" / "filter.json",
        {
            "orte": [[k, namen.get(k, k), n] for k, n in zaehle("orte").most_common()],
            "institutionen": [
                [k, namen.get(k, k), n]
                for k, n in zaehle("institutionen").most_common()
            ],
            "quellen": [[q, n] for q, n in zaehle("quellen").most_common()],
        },
    )

    # Beschriftung, Gruppe und Reihenfolge der URI-Links (Farben: css/farben.css)
    schreibe_json(JS_DATA / "uris.json", lies_uri_liste())

    # dieselbe Zuordnung als XML für die Stylesheets
    et_root = etree.Element("ereignistypen")
    for g in gruppen:
        g_el = etree.SubElement(
            et_root,
            "gruppe",
            id=g["id"],
            reihenfolge=str(g["reihenfolge"]),
            farbe=g["farbe"],
        )
        etree.SubElement(g_el, "label").text = g["label"]
        for typ, gid in typen.items():
            if gid == g["id"]:
                etree.SubElement(g_el, "typ").text = typ
    schreibe_xml(INDICES / "ereignistypen.xml", et_root)

    schreibe_xml(INDICES / "listevent.xml", gesamt)

    # tage.xml: jeder Tag, an dem ein Ereignis beginnt oder ein Ereignis mit Zeitraum läuft
    tage_root = etree.Element("tage")
    for tag in sorted(set(pro_tag) | set(laufend)):
        el = etree.SubElement(
            tage_root, "tag", when=tag, n=str(sum(pro_tag[tag].values()))
        )
        if tag in laufend:
            el.set("laufend", str(len(laufend[tag])))
    schreibe_xml(INDICES / "tage.xml", tage_root)

    mt_root = etree.Element("mehrtaegig")
    for d in mehrtaegig:
        etree.SubElement(
            mt_root,
            "ereignis",
            ref=d["id"],
            von=d["datum"],
            bis=d["ende"],
            art="unbestimmt" if d.get("unbestimmt") else "zeitraum",
        )
    schreibe_xml(INDICES / "mehrtaegig.xml", mt_root)

    # Kontrolle und Bericht
    anzahl = sum(len(e) for e in jahre.values())
    summe_uebersicht = sum(sum(c.values()) for c in pro_tag.values())
    if anzahl != summe_uebersicht:
        sys.exit(
            f"Summe in uebersicht.json ({summe_uebersicht}) ≠ Anzahl der Ereignisse ({anzahl})"
        )
    groesstes = max(gzip_groessen, key=gzip_groessen.get)
    print(f"{anzahl} Ereignisse in {len(jahre)} Jahresdateien")
    print(
        f"{len(pro_tag)} Tage mit Ereignissen, {len(set(laufend) - set(pro_tag))} weitere nur mit laufenden"
    )
    print(
        f"{len(mehrtaegig)} Ereignisse mit Zeitraum, davon {sum(1 for d in mehrtaegig if d.get('unbestimmt'))} mit unbestimmtem Tag im Monat"
    )
    print(f"uebersicht.json: {gz_uebersicht / 1024:.0f} KB gzip")
    print(
        f"Jahresdateien: zusammen {sum(gzip_groessen.values()) / 1024:.0f} KB gzip, größte {groesstes} mit {gzip_groessen[groesstes] / 1024:.0f} KB"
    )


if __name__ == "__main__":
    main()
