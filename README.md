# Wien, wo es war. Kulturelle Ereignisse in Wien 1860–1939

Statische Website, die kulturelle Ereignisse in Wien 1860–1939 über einen Kalender und eine Suche zugänglich macht.

* Daten: https://github.com/arthur-schnitzler/wien-wo-es-war_data
* gebaut mit dem [DSE-Static-Cookiecutter](https://github.com/acdh-oeaw/dse-static-cookiecutter)
* Planung und Stand der Umsetzung: [PLANUNG.md](PLANUNG.md)

## Lokal bauen

Voraussetzungen: Java, Ant, [uv](https://docs.astral.sh/uv/).

```bash
./shellscripts/fetch_data.sh        # Daten klonen nach data/, datahash.txt, Impressum
uv run pyscripts/prepare_data.py    # listevent.xml, tage.xml, mehrtaegig.xml, Kalender-JSON
ant                                 # alle Seiten nach html/
uv run pyscripts/make_sitemap.py    # html/sitemap.xml
uv run pyscripts/check_output.py    # Prüfung: jede URI auf ihrer Tagesseite verlinkt u. a.
```

Suche: `uv run pyscripts/make_ts_index.py` importiert die Ereignisse nach Typesense (Umgebungsvariablen `TYPESENSE_HOST`, `TYPESENSE_PORT`, `TYPESENSE_PROTOCOL`, `TYPESENSE_API_KEY` mit Admin-Rechten); mit `--jsonl datei.jsonl` nur die Dokumente schreiben. Host und Search-only-Key für die Oberfläche stehen oben in `html/js/search.js`.

Bis zum Start setzt `noindex` in `xslt/partials/params.xsl` auf allen Seiten `<meta name="robots" content="noindex, nofollow">`.

Teilbuilds: `ant seiten`, `ant tage`, `ant register`, `ant entitaeten` (siehe `build.xml`).

Das Impressum wird über die Umgebungsvariable `REDMINE_ID` geladen (`REDMINE_ID=… ./shellscripts/dl_imprint.sh`); ohne sie entsteht ein Platzhalter. Auf GitHub kommt die ID aus der Repository-Variable `REDMINE_ID`.

## Dev-Server

```bash
cd html/
uv run -m http.server
```

dann http://localhost:8000/

## Aufbau

* `config/ereignisgruppen.csv`, `config/ereignistypen.csv` – Ereignisgruppen (Reihenfolge, Farbe) und Zuordnung jedes Ereignistyps (`eventName/@n`) zu einer Gruppe. Taucht in den Daten ein Typ ohne Zuordnung auf, bricht `prepare_data.py` mit einer Meldung ab.
* `html/img/` – Logos, Favicons und `site.webmanifest`; `html/favicon.ico` im Wurzelverzeichnis. Originale des Logos (JPG, SVG mit Schriftzug als Text in „Kolo LP Std“) in `vorlagen/`, nicht ausgeliefert
* `meta/` – vorläufige Projekttexte (Über das Projekt, Quellen). Liegen im Daten-Repo Dateien unter `meta/`, haben diese Vorrang.
* `pyscripts/prepare_data.py` – bereitet die Daten für XSLT und Kalender auf:
  * `data/indices/listevent.xml` – alle Jahresdateien in einer Datei
  * `data/indices/tage.xml` – alle Tage mit Ereignissen
  * `data/indices/mehrtaegig.xml` – Ereignisse mit Zeitraum
  * `html/js-data/kalender/uebersicht.json` (Tag → Gruppe → Anzahl, Zeiträume), `html/js-data/kalender/JJJJ.json` (Ereignisse eines Jahres, Kompaktformat), `html/js-data/kalender/filter.json` (Spielstätten, Institutionen, Quellen), `html/js-data/ereignistypen.json`, `html/js-data/uris.json`
* `xslt/` – Stylesheets (XSLT 3.0, Saxon HE 9.9)
  * `tage.xsl` – Jahresübersicht, Jahres- und Tagesseiten, Weiterleitungen `pmbNNNN.html` → `JJJJ-MM-TT.html#pmbNNNN` (ein Durchlauf)
  * `partials/event-card.xsl` – Ereigniskarte; jede `idno` als Link
  * `list-of-relevant-uris.xml` – Beschriftung, Farbe und Gruppe der URI-Links (Projektkopie, Abweichungen von `schnitzler-chronik-static` stehen im Kopfkommentar)
  * `farben.xsl` – erzeugt `html/css/farben.css` (URI- und Gruppenfarben)
* Register und Entitätsseiten (`listperson.xsl`, `listplace.xsl`, `listbibl.xsl`, `listorg.xsl`): Tabulator-Tabellen mit Spalte „Ereignisse“, Karte der Spielstätten; eine Seite `pmbNNNN.html` pro Entität mit dem Layout aus `schnitzler-chronik-static/xslt/export/entities.xsl`
  * `prepare_data.py` schreibt die Ereignisse jeder Entität als `note[@type='mentions']` in die Registerkopien unter `data/indices/`; `entities.xsl` zeigt sie im Normalmodus an
  * `xslt/partials/entities-local.xsl` setzt die Parameter dafür (Zeitraum 1860–1939, ab 2.500 Ereignissen nur Jahresblöcke mit Link in den Kalender, Tab „Ereignisse“) und ergänzt „Im Kalender zeigen“
  * `entities.xsl`, `entities-setup.xsl`, `relations.json`, `html/css/entities.css`, `html/js/entity-tabs.js` kommen aus `schnitzler-chronik-static`; `check_entities_xsl.py` synchronisiert sie. Der Workflow führt es vor jedem Build aus.
* `html/js/calendar.js` + `html/css/kalender.css` – Kalender (`kalender.html`): Ansichten Zeitraum, Jahr, Monat, Tag; Filter nach Ereignisgruppe, Quelle, Spielstätte und per URL nach `ort`, `werk`, `person`, `institution`; Zustand in der URL, z. B. `kalender.html?ansicht=monat&datum=1900-05&gruppen=oper&ort=pmb15`
* `html/js/tag.js` – Datumssprung, „Heute vor 100 Jahren“, „Link kopieren“, „Zitieren“; `html/js/404.js` – Tage ohne Ereignisse

Die Daten-Repo-Struktur (`editions/`, `indices/` im Wurzelverzeichnis) wird von `fetch_data.sh` nach `data/` umgelegt.

## Veröffentlichen

Der Workflow [build.yml](.github/workflows/build.yml) baut die Seite und veröffentlicht sie auf GitHub Pages. Er startet manuell (*Actions → Deploy static content to Pages → Run workflow*) oder per `repository_dispatch` (`update-data`) aus dem Daten-Repo.

## Docker

* Image bauen: `docker build -f docker/Dockerfile -t wien-wo-es-war_static .`
* Container starten: `docker run -p 80:80 --rm --name wien-wo-es-war_static wien-wo-es-war_static`

## Lizenzen

Der Code steht unter der [MIT-Lizenz](LICENSE). Die Daten auf der Website stehen unter [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.de) (Parameter `lizenz-name`, `lizenz-url` in `xslt/partials/params.xsl`).

Die JavaScript-Bibliotheken liegen unter `html/vendor`; ihre Lizenzen stehen jeweils in einer `LICENSE`-Datei oder im Kopf der `.js`-Datei.

Saxon-HE steht unter der Mozilla Public License 2.0, siehe [LICENSE.txt](saxon/notices/LICENSE.txt).
