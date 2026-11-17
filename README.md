# Wohin in Wien damals. Kulturelle Ereignisse in Wien 1860–1939

Statische Website, die kulturelle Ereignisse in Wien 1860–1939 über einen Kalender und eine Suche zugänglich macht.

* Daten: https://github.com/arthur-schnitzler/wohin-in-wien-damals_data
* gebaut mit dem [DSE-Static-Cookiecutter](https://github.com/acdh-oeaw/dse-static-cookiecutter)
* Planung und Stand der Umsetzung: [PLANUNG.md](PLANUNG.md)

## Lokal bauen

Voraussetzungen: Java, Ant, [uv](https://docs.astral.sh/uv/).

```bash
./shellscripts/fetch_data.sh        # Daten klonen nach data/, datahash.txt, Impressum
uv run pyscripts/prepare_data.py    # listevent.xml, tage.xml, mehrtaegig.xml, Kalender-JSON
ant                                 # alle Seiten nach html/
uv run pyscripts/check_output.py    # Prüfung: jede URI auf ihrer Tagesseite verlinkt u. a.
```

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
* `meta/` – vorläufige Projekttexte (Über das Projekt, Quellen). Liegen im Daten-Repo Dateien unter `meta/`, haben diese Vorrang.
* `pyscripts/prepare_data.py` – bereitet die Daten für XSLT und Kalender auf:
  * `data/indices/listevent.xml` – alle Jahresdateien in einer Datei
  * `data/indices/tage.xml` – alle Tage mit Ereignissen
  * `data/indices/mehrtaegig.xml` – Ereignisse mit Zeitraum
  * `html/js-data/kalender/uebersicht.json`, `html/js-data/kalender/JJJJ.json`, `html/js-data/ereignistypen.json`
* `xslt/` – Stylesheets (XSLT 3.0, Saxon HE 9.9)
  * `tage.xsl` – Jahresübersicht, Jahres- und Tagesseiten, Weiterleitungen `pmbNNNN.html` → `JJJJ-MM-TT.html#pmbNNNN` (ein Durchlauf)
  * `partials/event-card.xsl` – Ereigniskarte; jede `idno` als Link
  * `list-of-relevant-uris.xml` – Beschriftung, Farbe und Gruppe der URI-Links (Projektkopie, Abweichungen von `schnitzler-chronik-static` stehen im Kopfkommentar)
  * `farben.xsl` – erzeugt `html/css/farben.css` (URI- und Gruppenfarben)
* `html/js/tag.js` – Datumssprung, „Link kopieren“, „Zitieren“; `html/js/404.js` – Tage ohne Ereignisse

Die Daten-Repo-Struktur (`editions/`, `indices/` im Wurzelverzeichnis) wird von `fetch_data.sh` nach `data/` umgelegt.

## Veröffentlichen

Der Workflow [build.yml](.github/workflows/build.yml) baut die Seite und veröffentlicht sie auf GitHub Pages. Er startet manuell (*Actions → Deploy static content to Pages → Run workflow*) oder per `repository_dispatch` (`update-data`) aus dem Daten-Repo.

## Docker

* Image bauen: `docker build -f docker/Dockerfile -t wohin-in-wien-damals_static .`
* Container starten: `docker run -p 80:80 --rm --name wohin-in-wien-damals_static wohin-in-wien-damals_static`

## Lizenzen

Der Code steht unter der [MIT-Lizenz](LICENSE).

Die JavaScript-Bibliotheken liegen unter `html/vendor`; ihre Lizenzen stehen jeweils in einer `LICENSE`-Datei oder im Kopf der `.js`-Datei.

Saxon-HE steht unter der Mozilla Public License 2.0, siehe [LICENSE.txt](saxon/notices/LICENSE.txt).
