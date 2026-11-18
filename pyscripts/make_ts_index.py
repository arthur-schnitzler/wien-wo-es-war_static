"""Typesense-Index der Ereignisse (PLANUNG.md, Abschnitt 8).

Ein Dokument pro Ereignis, gelesen aus html/js-data/kalender/JJJJ.json (pyscripts/prepare_data.py).
Felder: id, tag (JJJJ-MM-TT), datum (int JJJJMMTT, sortierbar), jahr (Facette), typ, gruppe, titel,
werke, urheber, personen, orte, institutionen, quellen (Facetten); refs und links werden nur
gespeichert (Verweise auf Entitätsseiten bzw. alle URIs in der Reihenfolge der Ereigniskarten).

Der Index wird als neue Collection angelegt und danach über den Alias COLLECTION umgehängt, damit
die Suche während des Imports weiterläuft; ältere Collections mit demselben Präfix werden gelöscht.

Aufruf:
  uv run pyscripts/make_ts_index.py                    # Import (TYPESENSE_* aus der Umgebung)
  uv run pyscripts/make_ts_index.py --jsonl ereignisse.jsonl   # nur Dokumente schreiben, ohne Server
"""

import argparse
import json
import os
import re
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
JS_DATA = ROOT / "html" / "js-data"
COLLECTION = "wien-wo-es-war"  # Alias, auf den html/js/search.js zugreift
REZENSION = "wird rezensiert in"

SCHEMA_FELDER = [
    {"name": "tag", "type": "string", "index": False, "optional": True},
    {"name": "datum", "type": "int32", "sort": True},
    {"name": "jahr", "type": "int32", "facet": True},
    {"name": "typ", "type": "string", "facet": True},
    {"name": "gruppe", "type": "string", "facet": True},
    {"name": "titel", "type": "string"},
    {"name": "werke", "type": "string[]", "facet": True, "optional": True},
    {"name": "urheber", "type": "string[]", "facet": True, "optional": True},
    {"name": "personen", "type": "string[]", "facet": True, "optional": True},
    {"name": "orte", "type": "string[]", "facet": True, "optional": True},
    {"name": "institutionen", "type": "string[]", "facet": True, "optional": True},
    {"name": "quellen", "type": "string[]", "facet": True, "optional": True},
    {"name": "refs", "type": "string[]", "index": False, "optional": True},
    {"name": "links", "type": "string[]", "index": False, "optional": True},
]


def namensliste(keys, namen):
    return [namen.get(k, k) for k in keys]


def dokumente():
    typen = json.loads((JS_DATA / "ereignistypen.json").read_text(encoding="utf-8"))
    gruppen = {g["id"]: g["label"] for g in typen["gruppen"]}
    uris = json.loads((JS_DATA / "uris.json").read_text(encoding="utf-8"))
    dateien = sorted((JS_DATA / "kalender").glob("[0-9][0-9][0-9][0-9].json"))
    if not dateien:
        raise SystemExit(
            "keine Kalenderdaten: zuerst pyscripts/prepare_data.py ausführen"
        )
    for datei in dateien:
        jd = json.loads(datei.read_text(encoding="utf-8"))
        namen = jd["namen"]
        for e in jd["ereignisse"]:
            werke = [
                w
                for w in e.get("werke", [])
                if (w[1] if len(w) > 1 else "") != REZENSION
            ]
            urheber = []
            for w in werke:
                for a, _ in jd["urheber"].get(w[0], []):
                    if a not in urheber:
                        urheber.append(a)
            if len(werke) == 1:
                titel = namen.get(werke[0][0], e.get("titel", e["typ"]))
            else:
                titel = (
                    e.get("titel")
                    or (namen.get(werke[0][0]) if werke else "")
                    or e["typ"]
                )

            # alle URIs, sortiert wie auf den Ereigniskarten, mit Beschriftung und CSS-Klasse
            eintraege = []
            for i, (sub, wert) in enumerate(e.get("uris", [])):
                url = (
                    wert
                    if re.match(r"^https?:", wert)
                    else jd["praefixe"].get(sub, "") + wert
                )
                bekannt = uris.get(sub)
                rang = bekannt[1] if bekannt else 3000
                label = (
                    bekannt[0]
                    if bekannt
                    else re.sub(r"^[a-z]+://(www\.)?([^/?#]+).*$", r"\2", url)
                )
                klasse = (
                    "uri-" + re.sub(r"[^A-Za-z0-9_-]", "_", sub)
                    if bekannt and bekannt[2]
                    else "uri-neutral"
                )
                eintraege.append((rang, i, sub, label, url, klasse))
            eintraege.sort()
            anzahl = {}
            for x in eintraege:
                anzahl[x[2]] = anzahl.get(x[2], 0) + 1
            nr = {}
            links = []
            for _, _, sub, label, url, klasse in eintraege:
                nr[sub] = nr.get(sub, 0) + 1
                if anzahl[sub] > 1:
                    label = f"{label} {nr[sub]}"
                links.append(f"{label}|{url}|{klasse}")

            refs = (
                [f"ort|{k}|{namen.get(k, k)}" for k in e.get("orte", [])]
                + [f"werk|{w[0]}|{namen.get(w[0], w[0])}" for w in werke]
                + [f"urheber|{k}|{namen.get(k, k)}" for k in urheber]
            )
            yield {
                "id": e["id"],
                "tag": e["datum"],
                "datum": int(e["datum"].replace("-", "")),
                "jahr": int(e["datum"][:4]),
                "typ": e["typ"],
                "gruppe": gruppen.get(
                    typen["typen"].get(e["typ"], "sonstiges"), "Sonstiges"
                ),
                "titel": titel,
                "werke": namensliste((w[0] for w in werke), namen),
                "urheber": namensliste(urheber, namen),
                "personen": namensliste((p[0] for p in e.get("personen", [])), namen),
                "orte": namensliste(e.get("orte", []), namen),
                "institutionen": namensliste(e.get("institutionen", []), namen),
                "quellen": e.get("quellen", []),
                "refs": refs,
                "links": links,
            }


def importieren(docs):
    import typesense

    client = typesense.Client(
        {
            "nodes": [
                {
                    "host": os.environ.get("TYPESENSE_HOST", "localhost"),
                    "port": os.environ.get("TYPESENSE_PORT", "8108"),
                    "protocol": os.environ.get("TYPESENSE_PROTOCOL", "http"),
                }
            ],
            "api_key": os.environ["TYPESENSE_API_KEY"],
            "connection_timeout_seconds": int(
                os.environ.get("TYPESENSE_TIMEOUT", "120")
            ),
        }
    )
    name = f"{COLLECTION}-{int(time.time())}"
    client.collections.create(
        {
            "name": name,
            "fields": SCHEMA_FELDER,
            "default_sorting_field": "datum",
            "metadata": {
                "description": "https://github.com/arthur-schnitzler/wien-wo-es-war_static"
            },
        }
    )
    fehler = 0
    for i in range(0, len(docs), 5000):
        antwort = client.collections[name].documents.import_(
            docs[i : i + 5000], {"action": "create"}
        )
        fehler += sum(1 for r in antwort if not r.get("success"))
    if fehler:
        client.collections[name].delete()
        raise SystemExit(
            f"{fehler} Dokumente nicht importiert; Collection {name} verworfen, Alias unverändert"
        )
    client.aliases.upsert(COLLECTION, {"collection_name": name})
    for c in client.collections.retrieve():
        if c["name"].startswith(COLLECTION + "-") and c["name"] != name:
            client.collections[c["name"]].delete()
    print(f"{len(docs)} Dokumente in {name}, Alias {COLLECTION} umgehängt")


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--jsonl",
        type=Path,
        help="Dokumente in diese Datei schreiben statt importieren",
    )
    args = parser.parse_args()
    docs = list(dokumente())
    if args.jsonl:
        with args.jsonl.open("w", encoding="utf-8") as f:
            for d in docs:
                f.write(json.dumps(d, ensure_ascii=False) + "\n")
        print(f"{len(docs)} Dokumente → {args.jsonl}")
    else:
        importieren(docs)


if __name__ == "__main__":
    main()
