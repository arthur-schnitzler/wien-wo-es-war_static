# Wien, wo es war – Planung der Website

Stand: 17. November 2026 · Code: `wien-wo-es-war_static` · Daten: [`arthur-schnitzler/wien-wo-es-war_data`](https://github.com/arthur-schnitzler/wien-wo-es-war_data)

## Kurzfassung

- Statische Site mit dem **dse-static-cookiecutter** (XSLT 2.0/Saxon, Ant, Bootstrap 5), Daten werden beim Build aus dem Daten-Repo geholt.
- **Die Tagesseite ist das Herzstück**: `1900-01-01.html` zeigt alle Ereignisse des Tages als Karten, jede mit **allen URIs als Links**. `pmbNNNN.html` leitet bei Ereignissen auf `TAG.html#pmbNNNN` weiter.
- **Kalender** als Einstieg: Sprung zu jedem Datum, Ansichten Zeitraum/Jahr/Monat/Woche/Tag, Filter nach Ereignisgruppe, Quelle, Spielstätte, Person, Werk. Daten werden pro Jahr nachgeladen (max. 46 KB gzip).
- **Entitätsseiten** für Personen, Orte, Werke und Institutionen mit `entities.xsl` aus `schnitzler-chronik-static/xslt/export`; dafür sind einige rückwärtskompatible Änderungen upstream nötig (Abschnitt 7).
- **Typesense-Suche** ergänzt den Kalender. Kalender und Tagesseiten funktionieren ohne Server.
- Geschätzt ~100.000 Dateien, ~450 MB, damit passt die Site auf GitHub Pages.

## 1. Ziel

Eine Website, die kulturelle Ereignisse in Wien 1860–1938 durchsuchbar macht.

**Muss**
1. **Einfache Suche über einen Kalender:** jeder Tag 1860–1938 ist in höchstens zwei Schritten erreichbar, filterbar nach Art des Ereignisses und Ort.
2. **Alle URIs eines Ereignisses als Links:** Jede `idno` erscheint als anklickbarer Link: Burgtheater-Archiv, Spielplan Oper, ANNO-Theaterzettel, Brahms online, Schnitzler-Projekte, PMB, Wikidata, Wikipedia. Kein URI wird verschluckt, auch keiner mit unbekanntem Typ.

**Soll:** Register und Entitätsseiten mit der Entitäts-Anzeige der Schnitzler-Chronik, facettierte Suche, Startseite mit Einstieg über ein Datum.

**Nicht-Ziele (vorerst):** Datenpflege in diesem Repo (passiert in PMB und Daten-Repo), NoSketch-Suche, OAI-PMH, Übersetzungen.

## 2. Ausgangslage: die Daten

Erzeugt von `python-scripts/build-data.py` im Daten-Repo aus PMB-`listevent.xml`. Ausgewählt ist der Zeitraum 1.1.1860–31.12.1938 (das Daten-Repo liefert bis 1939, `prepare_data.py` filtert), räumlich die heutige Wiener Stadtgrenze.

| | Anzahl |
|---|---|
| Ereignisse (`editions/listevent_JJJJ.xml`, 80 Jahresdateien) | 64.477 |
| Tage mit Ereignissen (von 29.219 Kalendertagen) | 25.296 (3.923 Tage ohne) |
| Ereignisse pro Jahr | 357 (1939) – 1.424 (1924) |
| Ereignisse pro Tag | meist 1–4, max. 15 (31.12.1922) |
| mehrtägige Ereignisse (`@from-iso`/`@to-iso`) | 29 (Ausstellungen, Bälle; bis 155 Tage) |
| Ereignistypen (`eventName/@n`) | 109, ein Ereignis ohne Typ |
| Personen / Orte / Werke / Institutionen | 5.411 / 414 / 4.049 / 206 |

Alle `@key`-Verweise lösen in den Registern auf. Die `xml:id`s sind über Ereignisse und Register hinweg eindeutig (74.557), `pmbNNNN.html` taugt also als gemeinsames Dateimuster.

### Aufbau eines Ereignisses

```xml
<event xml:id="pmb556520" when-iso="1900-01-01">
  <eventName n="Opernaufführung">Aufführung von Lohengrin, 1.1.1900</eventName>
  <note type="listorg"><listOrg><org role="veranstaltet von">
    <orgName key="pmb36689">K.K. Hof-Oper</orgName></org></listOrg></note>
  <idno type="URL" subtype="pmb">https://pmb.acdh.oeaw.ac.at/entity/556520/</idno>
  <idno type="URL" subtype="spielplan-oper">https://www.mdw.ac.at/imi/operapolitics/…#op_1900-01-01_139</idno>
  <listBibl><bibl type="collections" n="122">Spielplan Oper 1850–1945</bibl></listBibl>
  <listBibl><bibl><title key="pmb30823">Lohengrin</title>
    <note type="relation-type">ist Aufführung von</note></bibl></listBibl>
  <listPerson><person role="hat mitwirkend"><persName key="pmb…">…</persName></person></listPerson>
  <listPlace><place><placeName role="veranstaltet in" key="pmb15">Oper</placeName>
    <location><geo>48,203 16,3691</geo></location></place></listPlace>
</event>
```

Rollen: Personen `hat mitwirkend` (6.949) / `hat teilnehmend` (7.495). Werkbeziehung meist `ist Aufführung von` (62.407), außerdem Lesung, Premiere, Probe, Generalprobe, Uraufführung, Rezension, Neueinstudierung.

### URIs in den Ereignissen (Kernanforderung 2)

Insgesamt 135.487 `idno`, 1–6 pro Ereignis, alle `http(s)`, keine Leerzeichen.

| `@subtype` | Anzahl | Ziel |
|---|---|---|
| `pmb` | 64.550 | PMB-Eintrag; 73 Ereignisse haben nach Zusammenführungen zwei |
| `burgtheater` | 31.524 | Kulturerbe digital des Burgtheaters |
| `spielplan-oper` | 26.180 | Spielplan der Wiener Oper (mdw) |
| `anno` | 5.800 | Theaterzettel in ANNO, mit Anker auf die Vorstellung |
| `schnitzler-kultur` | 5.393 | Schnitzler: Kulturveranstaltungen |
| `brahms-online` | 1.733 | Brahms online |
| `schnitzler-briefe` | 305 | Schnitzler: Briefe |
| `wikidata`, `wikipedia` | je 1 | |

Bisher zeigt keine Vorlage alle davon: `schnitzler-kultur/xslt/partials/event.xsl` verlinkt nur PMB und Schnitzler-Briefe, und `mam:idnosToLinks` lässt Subtypes ohne Eintrag in `list-of-relevant-uris.xml` stillschweigend weg.

### Spitzenwerte (wichtig für Entitätsseiten)

| Entität | Ereignisse |
|---|---|
| Oper (`pmb15`) | 26.118 |
| K.K. Hof-Oper (`pmb36689`) | 18.183 |
| Burgtheater (`pmb14`) / Altes Burgtheater (`pmb185621`) | 16.695 / 10.255 |
| Arthur Schnitzler (teilnehmend) | 5.397 |
| Richard Wagner (über aufgeführte Werke) | 3.408 |
| Die Puppenfee (häufigstes Werk) | 684 |

Daraus folgt: Auf Entitätsseiten werden Ereignislisten nur bis zu einer Obergrenze vollständig ausgegeben (Abschnitt 7).

### Datenhinweise (in der Anzeige abfangen, ggf. im Daten-Repo beheben)

- `note[@type='references']` enthält in 29 Ereignissen nur „None“ → ignorieren.
- Sammlungen (`bibl[@type='collections']`) enthalten PMB-interne Etiketten: „manually created entity“ (1.579×) und „No german Wikipedia-Site found“ → als „Quelle“ nur eine Positivliste zeigen (Burgtheater, Spielplan Oper, Schnitzler-Kultur, Brahms online, Kalbeck-Tagebücher, Kraus-Rechtsakten).
- `eventName` endet fast immer auf „, T.M.JJJJ“ → auf Tagesseiten ohne Datum anzeigen.
- 955 Ereignisse haben als Ort nur „Wien“ (`pmb50`) → als „Wien (Ort nicht näher bestimmt)“ zeigen.
- `pmb181900` hat keinen Typ → „Veranstaltung“.
- In den Registern: `idno[@subtype='tmp-burgtheater']` (1.385 Werke) ist keine URL, `insel` zeigt auf eine Platzhalter-Domain, `brahms-online`-Werk-URLs enthalten Leerzeichen → filtern bzw. kodieren.
- `person/listEvent` im Personenregister enthält auch Ereignisse außerhalb der Auswahl (8.858 Schlüssel, davon 7.623 im Bestand) → die Ereignisse einer Person immer aus `editions/` berechnen.

## 3. Grundentscheidungen

1. **Die Tagesseite ist die kanonische Anzeige eines Ereignisses.** Die Leitfrage der Seite ist „Wohin am …?“, der Tageskontext ist also der Mehrwert. Vollseiten pro Ereignis nach dem Muster von `schnitzler-kultur` (~20 KB je Seite) ergäben allein ~1,3 GB.
2. **`pmbNNNN.html` gibt es für jede Entität.** Bei Ereignissen ist das eine ~0,5 KB große Weiterleitung auf `TAG.html#pmbNNNN` (canonical, `meta refresh`, `noindex`, nicht in der Sitemap). Damit funktionieren Links aus der PMB und den Schwesterprojekten im gewohnten Muster. Personen, Orte, Werke und Institutionen bekommen volle Entitätsseiten.
3. **Der Kalender lädt seine Daten pro Jahr nach.** Die Chronik lädt dagegen 15,6 MB `calendarData.js` auf einmal. Gemessen mit einem Prototyp: Übersichtsdatei 97 KB gzip, größte Jahresdatei 46 KB gzip (1924), alle 80 Jahre zusammen 2,1 MB gzip.
4. **Kalender und Tagesseiten brauchen keinen Server.** Typesense ist eine Ergänzung für die Facettensuche.
5. **Wiederverwenden statt neu bauen:**
   - Entitätsseiten: `entities.xsl`, synchronisiert über `check_entities_xsl.py` wie in `schnitzler-kultur`.
   - Kalender: Fork des `SimpleCalendar` aus `schnitzler-chronik-static/html/js/calendar.js`.
   - Link-Pills: `LOD-idnos.xsl` mit `list-of-relevant-uris.xml`.
   - Ereigniskarten: Gestaltung nach `schnitzler-kultur/xslt/partials/event.xsl`.

### Größenbudget

| Teil | Dateien | geschätzt |
|---|---|---|
| Tagesseiten (à ~10 KB) | 25.296 | ~250 MB |
| Ereignis-Weiterleitungen | 64.477 | ~32 MB |
| Entitätsseiten (mit Obergrenze) | 10.080 | ~120 MB |
| Jahresseiten, Register, Kalender-JSON, Assets | ~400 | ~50 MB |
| **Summe** | **~100.000** | **~450 MB** |

GitHub Pages erlaubt laut Doku 1 GB pro Site (vor dem ersten Deploy prüfen). Kommen die geplanten Quellen dazu (Konzerthaus, Musikverein, Volksoper …), wächst die Site etwa linear. Wird es eng, bleibt das Docker/nginx-Image aus dem Cookiecutter (ghcr.io) als Ausweg.

## 4. Seiten und URLs

| URL | Inhalt | erzeugt von |
|---|---|---|
| `index.html` | Einstieg: Datumsfeld, „Heute vor 100 Jahren“, Zahlen, Quellen | `index.xsl` |
| `kalender.html` | interaktiver Kalender mit Filtern | `kalender.xsl` + `js/calendar.js` |
| `1900.html` | Jahresseite: 12 Monatsraster, Tage verlinkt (Fallback ohne JS, Crawl-Pfad) | `tage.xsl` (Hauptausgabe) |
| `1900-01-01.html` | Tagesseite mit allen Ereigniskarten | `tage.xsl` (`xsl:result-document`) |
| `pmbNNNN.html` (Ereignis) | Weiterleitung auf Tagesseite + Anker | `tage.xsl` |
| `pmbNNNN.html` (Person/Ort/Werk/Institution) | Entitätsseite | Register-XSLTs mit `entities.xsl` |
| `listperson.html`, `listplace.html`, `listbibl.html`, `listorg.html` | Register (Tabulator) mit Spalte „Ereignisse“ | Register-XSLTs |
| `search.html` | Facettensuche | `search.xsl` + `js/search.js` |
| `ueber-das-projekt.html`, `quellen.html`, `imprint.html` | Projekt, Quellen und Lizenzen, Impressum | `meta.xsl`, `imprint.xsl` |
| `404.html` | erkennt `JJJJ-MM-TT.html` ohne Ereignisse und öffnet den Kalender an diesem Datum mit Hinweis und den nächsten Tagen | `404.xsl` |
| `js-data/kalender/uebersicht.json`, `js-data/kalender/JJJJ.json`, `js-data/ereignistypen.json` | Kalenderdaten | `prepare_data.py` |
| `beacon.txt`, `sitemap.xml` | GND-BEACON, Sitemap | `beacon.xsl`, Python |

## 5. Kalender (Kernanforderung 1)

**Einstiege**
- Datumsfeld `<input type="date" min="1860-01-01" max="1938-12-31">` auf Start- und Kalenderseite, das direkt zur Tagesseite führt.
- „Heute vor 100 Jahren“ (heute wäre das der 17. November 1926), clientseitig berechnet.
- Auswahl von Jahr und Monat, Pfeiltasten für vor/zurück.

**Ansichten**
- *Zeitraum*: 80 Jahre × 12 Monate als Heatmap; ein Klick öffnet den Monat.
- *Jahr*: 12 Monatsraster, Tage nach Anzahl eingefärbt.
- *Monat*: Raster mit farbigen Punkten je Ereignisgruppe und den ersten Titeln pro Tag; auf schmalen Bildschirmen als Liste. Die Kalenderwoche am Zeilenanfang öffnet die Woche.
- *Woche*: sieben Spalten (Montag–Sonntag) mit allen Ereignissen (Typ, Titel, Urheber:in, Ort), darüber laufende mehrtägige Ereignisse; auf schmalen Bildschirmen untereinander. Ein Klick auf ein Ereignis öffnet den Tag an dieser Karte. URL: `?ansicht=woche&datum=1900-05-14` (beliebiger Tag der Woche), ein darin geöffneter Tag `?ansicht=tag&datum=…&von=woche`.
- *Tag*: Seitenleiste mit Ereigniskarten (Typ, Titel, Ort, **URI-Links**) und Link auf die Tagesseite.

**Filter** (wirken in allen Ansichten)
- Ereignisgruppen als Farbchips (10 Gruppen, Anhang A).
- Quelle (Burgtheater, Spielplan Oper, Schnitzler-Kultur, Brahms online …).
- Spielstätte sowie Entitätsfilter per URL-Parameter: `?ort=pmb15`, `?werk=pmb30823`, `?person=pmb13024` (inklusive Urheberschaft aufgeführter Werke), `?institution=pmb36689`. Darüber verlinken die Entitätsseiten „Im Kalender zeigen“.
- Der Zustand steht in der URL, z. B. `kalender.html?ansicht=monat&datum=1900-05&gruppen=oper,konzert&ort=pmb15`. So sind Ansichten teilbar und die Zurück-Taste funktioniert.

**Daten** (`pyscripts/prepare_data.py`)
- `uebersicht.json`: Tag → Gruppe → Anzahl. Wird für die Ansichten Zeitraum und Jahr und für den 404-Fall gebraucht.
- `JJJJ.json`: pro Ereignis `id`, Datum (und Ende), Typ, Titel ohne Datum, Schlüssel von Ort, Werk, Urheber:in, Person und Institution, Quelle und URIs. Wird beim Navigieren nachgeladen und im Browser gecacht.

**Änderungen gegenüber dem Chronik-Kalender:** Daten pro Jahr statt einer Gesamtdatei; Kategorien sind Ereignisgruppen statt Projekte; die Tagesansicht rendert Ereigniskarten mit URI-Links; dazu kommen die Entitätsfilter.

**Barrierefreiheit:** Tageszellen sind Buttons mit `aria-label` („3 Ereignisse am 1. Jänner 1900“). Alles ist per Tastatur bedienbar, die Farben sind auf Kontrast geprüft.

## 6. Ereignisanzeige und URI-Links (Kernanforderung 2)

**Tagesseite `1900-01-01.html`**
- Kopf „Montag, 1. Jänner 1900“. Navigation: ← vorheriger Tag mit Ereignissen · Jänner 1900 (Kalender) · Jahr 1900 · nächster Tag →, dazu ein Datumsfeld.
- Tageslinks, einmal pro Tag: Zeitungen vom Tag (ANNO, DDB); für 1862–1931 die Schnitzler-Chronik.
- Ereigniskarten, gruppiert nach Ereignisgruppe (Reihenfolge laut Anhang A), innerhalb der Gruppe nach Spielstätte.
- Abschnitt „Laufend“ für mehrtägige Ereignisse an jedem Tag ihrer Dauer, auch über Jahresgrenzen hinweg. Kanonisch stehen sie am ersten Tag.
- Wer über `pmbNNNN.html` oder einen Anker kommt, sieht die Karte über `:target` hervorgehoben.

**Ereigniskarte** (`xslt/partials/event-card.xsl`; die Kalender-Tagesansicht erzeugt dieselbe Struktur in JS)
- Typ als Badge. Titel: bei Aufführungen eines einzelnen Werks der Werktitel (Untertitel nach dem ersten Punkt kleiner gesetzt), sonst `eventName` ohne Datum.
- Ort → Ortsseite; Veranstalter → Institutionsseite; Werk(e) mit Beziehung (Premiere, Lesung …) und Urheber:innen aus `listbibl.xml`. Rollen: `hat-geschaffen` → Werk, `hat-geschaffen-vertonung` → Musik, `hat-ubersetzt` → Übersetzung usw. Mitwirkende und Teilnehmende verlinken auf Personenseiten.
- Quelle aus der Positivliste der Sammlungen.
- **Links-Leiste: jede `idno` als Link** in fester Reihenfolge:
  1. Quellen: Burgtheater-Archiv, Spielplan Oper, Theaterzettel (ANNO), Brahms online
  2. Projekte: Schnitzler: Kulturveranstaltungen, Schnitzler: Briefe, weitere
  3. Normdaten: PMB, Wikidata, Wikipedia
  - Beschriftung und Farbe kommen aus `xslt/list-of-relevant-uris.xml`, die Reihenfolge aus einem neuen Attribut `@group`. `mam:idnosToLinks` ignoriert das Attribut, die Datei bleibt also kompatibel.
  - Mehrere Links gleichen Typs (z. B. zwei PMB-IDs) werden alle gezeigt, nummeriert („PMB 1“, „PMB 2“), statt in einem Modal.
  - Unbekannter Subtype → neutraler Link mit dem Hostnamen als Beschriftung.
  - `target="_blank" rel="noopener"`, die volle URL im `title`, ein Icon für externe Links.
  - Eine generierte Theaterzettel-Tagesansicht für Burgtheater-Orte (wie in `entities.xsl`) gibt es nur, wenn kein `anno`-Link vorhanden ist.
- „Link kopieren“ (Permalink `pmbNNNN.html`) und ein Zitiervorschlag.

**Korrekturen an `list-of-relevant-uris.xml`** (in der Projektkopie; dieselben Korrekturen auch upstream in `schnitzler-chronik-static/xslt/export`):
- `spielplan-oper_1869–1945` (mit Halbgeviertstrich) → `spielplan-oper`. Sonst fehlen die Oper-Links bei 26.180 Ereignissen.
- Die Farbe `#337ab7a` ist ungültig (7 Stellen). Die Pill wäre weiße Schrift ohne Hintergrund.
- `burgtheater` steht zweimal in der Liste, das ergibt zwei Pills für denselben Link → auf einen Eintrag zusammenführen.
- Fehlende Subtypes aus den Registern ergänzen: `schnitzler-kino`, `oeml`, `imdb`, `exemplar`, `schnitzler-mikrofilme` (die Liste kennt nur `schnitzler-mikrofilme-daten`), `wiener-rundschau`, `tillich-briefe`, `freud`, `gtrans`. `tmp-burgtheater` und `insel` bewusst ausschließen; `idno[@type='URL']` ohne Subtype fängt der neutrale Fallback-Link auf.
- Einen Eintrag `wien-wo-es-war` ergänzen, für Rückverweise aus den anderen Projekten.
- Kontrast gegen weiße Schrift prüfen; z. B. erreicht `#00ACC1` (Brahms) nicht 4,5:1 → Textfarbe pro Eintrag festlegen.

## 7. Entitätsseiten (Personen, Orte, Werke, Institutionen)

Grundlage sind `entities.xsl`, `entities-setup.xsl`, `entities.css`, `entity-tabs.js` und `relations.json` aus `schnitzler-chronik-static/xslt/export`, synchronisiert mit `check_entities_xsl.py`. `LOD-idnos.xsl` und `list-of-relevant-uris.xml` liegen lokal unter `xslt/`. Das Muster mit Tabulator-Register und `xsl:result-document` pro Entität stammt aus `schnitzler-kultur/xslt/listperson.xsl`.

- **Steckbrief:**
  - Personen: Porträt, Lebensdaten, Berufe, Namensvarianten.
  - Orte: Karte und übergeordneter Ort.
  - Werke: Urheber:innen mit Rollen, Datum.
  - Institutionen: Sitz.
  - Bei allen: Links zu Ressourcen und Normdaten.
- **Tab „Ereignisse“** (die „Erwähnungen“ im Ereignis-Modus von `schnitzler-kultur`): Jahresdiagramm 1860–1938 und eine Liste nach Jahr und Monat, die direkt auf `TAG.html#pmbNNNN` verlinkt. Bei Personen getrennt nach „beteiligt“ (mitwirkend/teilnehmend) und „als Urheber:in aufgeführter Werke“.
- **Tab „Relationen“** aus PMB-`relations.csv` (`fetch_relations.py`): optional, Phase 4.
- Button **„Im Kalender zeigen“** (`kalender.html?ort=…` usw.).

**Nötige Änderungen an `entities.xsl`** (upstream, rückwärtskompatibel). Ohne sie wird das Ergebnis falsch oder der Build zu langsam:

| Problem | Änderung |
|---|---|
| Der Ereignis-Modus hängt an `$current-edition = 'schnitzler-kultur'` (9 Stellen) | Parameter `$mentions-from-events`, Default wie bisher |
| `fill-event-variable`, `mam:has-mentions` und `mam:mentions-count` durchsuchen alle Ereignisse linear: 10.000 Entitäten × 64.000 Ereignisse | `xsl:key` auf `tei:event` über `descendant::*/@key` sowie auf Werke nach Urheber:in |
| Das Diagramm ist fest auf 1876 bzw. 1879 bis 1931 eingestellt | Parameter `$mentions-start-year`, `$mentions-end-year` |
| Der Link einer Erwähnung ist `@target` + `.html` | überschreibbare Funktion `mam:mention-href()`; hier `TAG.html#pmbNNNN` |
| Die Oper ergäbe eine Seite von mehreren MB; `showNumberOfMentions` wird nirgends ausgewertet | `$mentions-max-inline`: darüber nur Diagramm und Jahrestabelle mit Links in den gefilterten Kalender |
| Die Tab-Beschriftung „Erwähnungen“ ist fest | Parameter `$mentions-tab-label` („Ereignisse“) |

`entities-setup.xsl` liest die Ereignisse aus `data/indices/listevent.xml`. Diese Datei erzeugt `prepare_data.py` aus den 80 Jahresdateien. Die Konkordanzdateien (`index_person_day.xml` u. a.) fehlen hier wie in `schnitzler-kultur`, wo sie offenbar nur Warnungen auslösen; beim ersten Build prüfen.

Falls die Upstream-Änderungen nicht gewünscht sind, bliebe ein lokales `entities-local.xsl`, das `entities.xsl` importiert und die betroffenen Templates überschreibt. Der Nachteil: `list-all-mentions` (~340 Zeilen) müsste komplett kopiert werden und liefe dann auseinander.

## 8. Suche (Typesense)

- Eine Collection `wien-wo-es-war`, ein Dokument pro Ereignis. Felder: `id`, `datum` (int `JJJJMMTT`, sortierbar), `jahr` (Facette, Bereich), `typ`, `gruppe`, `titel`, `werke`, `urheber`, `personen`, `orte`, `institutionen`, `quellen` (Facetten). `uris` und `tag_url` werden nur gespeichert.
- UI: `search.xsl` und `search.js` aus dem Cookiecutter, angepasst. Suchfeld, Jahresbereich, die Facetten von oben, Sortierung nach Datum. Treffer erscheinen im Stil der Ereigniskarte mit URI-Links und verlinken auf `TAG.html#pmbNNNN`.
- `pyscripts/make_ts_index.py`: die Cookiecutter-Vorlage, umgeschrieben von Volltext auf Ereignisse. Der Admin-Key liegt als GitHub-Secret `TYPESENSE_API_KEY`, der Search-only-Key steht in `search.js`.

## 9. Startseite, Register, Projektseiten

- **Startseite:** Titel „Wien, wo es war“, Datumsfeld, „Heute vor 100 Jahren“, Zahlen (Ereignisse, Spielstätten, Werke, Personen), Einstiege zu Kalender, Suche und Registern, Quellen mit Links. Optional „An diesem Tag“: derselbe Kalendertag über alle Jahre, aus 366 kleinen JSON-Dateien.
- **Register:** Tabulator-Tabellen wie in `schnitzler-kultur`, zusätzlich eine sortierbare Spalte „Ereignisse“. Die Orte auch als Karte der Spielstätten.
- **Über das Projekt / Quellen:**
  - Herkunft und Auswahlkriterien, aus dem README des Daten-Repos.
  - Datengeber: Burgtheater (Kulturerbe digital), Spielplan der Wiener Oper (mdw), Schnitzler-Kultur, Schnitzler-Briefe, Brahms online, PMB, Stadt Wien (Landesgrenze, CC BY 4.0).
  - Lizenzen.
  - Lücken: Nur Burgtheater und Oper sind vollständig erfasst.
  - Aufruf an weitere Datengeber.

## 10. Technik

### Setup mit dem Cookiecutter

```bash
cd ~/git
uvx cookiecutter gh:acdh-oeaw/dse-static-cookiecutter --overwrite-if-exists
```

`--overwrite-if-exists` ist nötig, weil der Ordner (mit dieser Datei) schon existiert. Fremde Dateien bleiben dabei erhalten.

| Frage | Antwort |
|---|---|
| directory_name | `wien-wo-es-war_static` |
| project_title | `Wien, wo es war. Kulturelle Ereignisse in Wien 1860–1938` |
| project_short_title | `Wien, wo es war` |
| default_lang | `de` |
| github_org | `arthur-schnitzler` |
| base_url | offen (Abschnitt 13) |
| redmine_id | offen (Abschnitt 13); nicht den Default 18716 übernehmen |
| translations | `no` |
| avoid_google_indexing | `true` bis zum Start; das schreibt `noindex` fest in `html_head.xsl`, dort zum Start entfernen |
| use_remote_data | `true` |
| data_dir | `wien-wo-es-war_data` |
| data_repo | `https://github.com/arthur-schnitzler/wien-wo-es-war_data` |

### Anpassungen nach dem Generieren

- **`shellscripts/fetch_data.sh`:** Das Skript erwartet im Daten-Repo einen Ordner `data/`, dort liegen `editions/` und `indices/` aber im Wurzelverzeichnis. Nach dem Klonen also `editions/`, `indices/` (und künftig `meta/`) nach `data/` verschieben.
- **Entfernen:** Beispieldaten, `noske-search.*`, `toc.xsl` („Editionseinheiten“), `editions.xsl`, `oai-pmh/`, `api.xsl`.
- **`params.xsl`:** `current-edition = 'wien-wo-es-war'` und `current-colour` ergänzen.
- **Navigation:** Kalender · Suche · Register (Personen, Orte, Werke, Institutionen) · Projekt.
- **Vendor:** Der Cookiecutter bringt instantsearch, typesense-instantsearch-adapter, Leaflet (mit markercluster) und DataTables mit. Für die Register wie in `schnitzler-kultur` (`tabulator_js.xsl`) kommt Tabulator in fester Version dazu; `openseadragon`, `acdh-noske-search` und `i18next` können weg.
- **`.gitignore`:** `html/js-data/` ergänzen. In VS Code `html/` aus Dateiüberwachung und Suche ausnehmen (~100.000 Dateien).
- **`build.xml`:**
  - In Targets gliedern (`seiten`, `tage`, `entitaeten`, `register`), damit Teilbuilds möglich sind.
  - Namensräume über `exclude-result-prefixes` vermeiden statt mit `<replace>` über 100.000 Dateien zu laufen.

### Verzeichnisstruktur (Auszug)

```
wien-wo-es-war_static/
├── PLANUNG.md
├── build.xml
├── check_entities_xsl.py          # Sync aus schnitzler-chronik-static/xslt/export
├── config/ereignistypen.csv       # Typ → Gruppe → Reihenfolge → Farbe (Anhang A)
├── pyscripts/
│   ├── prepare_data.py            # listevent.xml gesamt, Tagesindex, Kalender-JSON
│   ├── make_ts_index.py
│   ├── make_sitemap.py
│   └── check_output.py            # Prüfungen (Abschnitt 12)
├── shellscripts/fetch_data.sh
├── xslt/
│   ├── index.xsl  kalender.xsl  tage.xsl  search.xsl  meta.xsl  404.xsl
│   ├── listperson.xsl  listplace.xsl  listbibl.xsl  listorg.xsl
│   ├── list-of-relevant-uris.xml
│   └── partials/  event-card.xsl  LOD-idnos.xsl  entities.xsl  entities-setup.xsl  params.xsl …
└── html/  css/  js/calendar.js  js/search.js  js/entity-tabs.js  vendor/ …
```

### Build-Ablauf

1. `shellscripts/fetch_data.sh`: Daten klonen, `datahash.txt` schreiben, Impressum holen.
2. `pyscripts/prepare_data.py` erzeugt:
   - `data/indices/listevent.xml`, alle Jahre zusammengeführt, für `entities.xsl`;
   - `data/indices/tage.xml` (alle Tage mit Anzahl, für vor/zurück über Jahresgrenzen) und `data/indices/mehrtaegig.xml`;
   - `html/js-data/kalender/*.json` und `ereignistypen.json`.
   Bei Typen ohne Gruppe bricht das Skript mit einer Meldung ab.
3. `python check_entities_xsl.py` (optional zusätzlich `fetch_relations.py`).
4. `ant`:
   - `tage.xsl` läuft über die 80 Jahresdateien. Die Hauptausgabe ist `JJJJ.html` (Ant-Mapper `listevent_(\d{4}).xml` → `\1.html`), Tagesseiten und Weiterleitungen entstehen per `xsl:result-document`.
   - Die Register-XSLTs erzeugen die Entitätsseiten.
   - Dazu kommen Startseite, Kalender, Suche, Projektseiten, 404 und BEACON.
5. `make_ts_index.py`, `make_sitemap.py`, `check_output.py`.

### GitHub Actions

- `build.yml`:
  - Auslöser: `workflow_dispatch` sowie `repository_dispatch` aus dem `update-data`-Workflow des Daten-Repos (braucht dort ein Token-Secret).
  - Schritte wie im Build-Ablauf, mit `ANT_OPTS: -Xmx6g`; Deploy auf GitHub Pages mit eigener Domain (`CNAME`).
- Fallback ab 1 GB: Docker-Image (`docker/Dockerfile`, nginx) nach ghcr.io.

## 11. Umsetzung in Phasen

| Phase | Inhalt | fertig, wenn |
|---|---|---|
| 0 Gerüst | Cookiecutter, `fetch_data.sh`, Aufräumen, Parameter, Vendor-Dateien, Build-Targets, Grundgerüst von `prepare_data.py` | `ant` läuft lokal und in Actions durch, Startseite und Register erscheinen |
| 1 Tage & URIs | `tage.xsl`, `event-card.xsl`, Jahresseiten, Weiterleitungen, korrigierte URI-Liste, 404-Datumslogik | jede `idno` jedes Ereignisses ist auf seiner Tagesseite verlinkt (`check_output.py` grün) |
| 2 Kalender | Kalender-JSON, `kalender.xsl`, `calendar.js` (Fork), Filter, URL-Zustand, Datumssprung auf der Startseite | jeder Tag 1860–1938 in ≤ 2 Klicks erreichbar; Kalenderdaten beim ersten Aufruf < 150 KB gzip |
| 3 Entitäten | Upstream-Änderungen an `entities.xsl`, Entitätsseiten, Ereigniszahlen in den Registern, Spielstättenkarte | alle 10.080 Entitätsseiten gebaut; keine Seite > 1 MB; Build < 30 min |
| 4 Suche & Projekt | Typesense-Index und -Oberfläche, Projekt- und Quellenseiten, Sitemap, BEACON, optional Relationen | Facettensuche mit Jahresbereich funktioniert; alle Quellen sind genannt |
| 5 Start | Domain, Barrierefreiheit, Kontraste, Größen- und Linkprüfung, Eintrag in PMB und in `list-of-relevant-uris.xml` | Site öffentlich; PMB verlinkt auf `pmbNNNN.html` |

Die Phasen 1 und 2 decken die beiden Muss-Anforderungen ab und kommen deshalb zuerst.

## 12. Qualitätssicherung

`pyscripts/check_output.py` läuft nach jedem Build, auch in Actions, und prüft:
- Für jedes Ereignis: Die Tagesseite enthält `id="pmbNNNN"` und **alle** `idno`-URLs als `href` innerhalb dieser Karte. Die Weiterleitung existiert und zeigt auf den richtigen Tag.
- Mehrtägige Ereignisse erscheinen an allen Tagen ihrer Dauer.
- Die Summen in den Kalender-JSONs stimmen mit der Anzahl der Ereignisse pro Jahr überein.
- Alle internen Links zeigen auf existierende Dateien.
- Ein Größenbericht nennt MB, Dateien und die größten Seiten; ab 800 MB gibt es eine Warnung.

## 13. Offene Fragen

1. **Domain / `base_url`:** z. B. `wien-wo-es-war.acdh.oeaw.ac.at`? Hosting unter der GitHub-Org `arthur-schnitzler`?
2. **Redmine-ID** für das Impressum.
3. **Tagesseite kanonisch** (Empfehlung) oder doch eine Vollseite pro Ereignis? Letzteres etwa verdreifacht die Größe.
4. **Typesense-Instanz:** `typesense.acdh-dev.oeaw.ac.at` wie bei den Schnitzler-Projekten oder `typesense.acdh.oeaw.ac.at` wie im Cookiecutter? Und die Keys.
5. **Upstream-Änderungen** an `schnitzler-chronik-static/xslt/export` (Abschnitt 7 und die Korrekturen der URI-Liste in Abschnitt 6): einverstanden?
6. **Projektfarbe und Logo** (`current-colour`).
7. **Schnitzler-Querverweise** auf den Tagesseiten (Chronik 1862–1931): gewünscht, oder soll die Seite bewusst ohne Schnitzler-Bezug auskommen?
8. **Lizenz der Daten:** Das Daten-Repo steht unter MIT. Die Bedingungen von Burgtheater und mdw sind noch zu klären; für die Daten auf der Website CC BY 4.0?
9. **Meta-Texte** (Über das Projekt, Quellen): im Daten-Repo unter `meta/` (Empfehlung) oder hier?
10. **Englische Oberfläche** zu einem späteren Zeitpunkt?

## Anhang A: Ereignisgruppen

Gegen die Daten geprüft: Alle 109 Typen sind zugeordnet, die Summe beträgt 64.477. Die Zuordnung wird als `config/ereignistypen.csv` gepflegt; neue Typen ohne Gruppe lassen den Build mit einer Meldung abbrechen.

| # | Gruppe | Ereignisse | Typen (`eventName/@n`) |
|---|---|---|---|
| 1 | Theater | 33.231 | Theateraufführung, Theaterpremiere, Theateruraufführung, Theaterneuinszenierung, Theaterneueinstudierung, Theatererstaufführung, Schulaufführung, Studierendenaufführung, Privataufführung, Geschlossene Aufführung, Varieté, Revue, Marionettentheater, Puppenspiel |
| 2 | Oper & Operette | 19.994 | Opernaufführung, Opernpremiere, Opernuraufführung, Operettenaufführung |
| 3 | Ballett & Tanz | 5.983 | Ballett, Ballettpremiere, Balletturaufführung, Ballettsoirée, Tanzaufführung |
| 4 | Konzert | 2.698 | Konzert, Quartett, Liederkonzert, Philharmonisches Konzert, Klavierkonzert, Orchesterkonzert, Sinfoniekonzert, Gesellschaftskonzert, Privates Konzert, Volksgesang, Trio, Kammermusikkonzert, Violinkonzert, Schulkonzert, Wohltätigkeitskonzert, Cellokonzert, Kompositionskonzert, Chorgesang, Orgelkonzert, Violin-Klavier-Konzert, Musikpremiere, Matinée |
| 5 | Film | 742 | Filmvorführung, Private Filmvorführung, Filmpremiere |
| 6 | Lesung & Vortrag | 370 | Private Lesung, Lesung, Vortrag, Vorlesung, Schulvortragsabend, Privater Vortrag |
| 7 | Ausstellung & Schau | 455 | Panoramabesuch, Museumsbesuch, Ausstellungsbesuch, Ausstellung, Zirkusvorstellung, Völkerschau, Zaubervorstellung, Billardvorstellung, Festival |
| 8 | Ball & Gesellschaft | 295 | Hausball, Soirée, Ball, Hochzeit, Kränzchen, Vergnügungsabend, Empfang, Bankett, Feier, Maskenball, Redoute, Kommers, Polterabend, Kostümfest, Soirée-dansante, Tanz, Techniker-, Tanz-, Universitäts-, Mediziner-, Unitas-, Wärmestuben-Kränzchen, Kneipe, Narrenabend, Gesellschaftsabend, Damenabend, Spielabend, Diner, Silberne Hochzeit |
| 9 | Probe | 565 | Probe, Generalprobe, Kostümprobe, Arrangierprobe, Leseprobe |
| 10 | Sonstiges | 144 | Vereinstreffen, Veranstaltung, Privates Treffen, Wohltätigkeitsveranstaltung, Beerdigung, Sitzung, Kongress, Praktische Übung, Duell, Umzug, Heilige Messe, Schiedsgericht, ohne Typ |

## Anhang B: Vorlagen in den Nachbarprojekten

| Was | Woher |
|---|---|
| Entitätsseiten, Tabs, CSS | `../schnitzler-chronik-static/xslt/export/` (`README-entities-layout.md`) |
| Sync-Skript | `../schnitzler-kultur/check_entities_xsl.py` |
| Kalender | `../schnitzler-chronik-static/html/js/calendar.js`, `xslt/calendar.xsl` |
| Ereignisdarstellung (Werktitel kursiv, Personen-Chips, Zeitungen vom Tag) | `../schnitzler-kultur/xslt/partials/event.xsl` |
| Register mit Tabulator, eine Seite pro Entität | `../schnitzler-kultur/xslt/listperson.xsl` |
| Workflow mit Sync, Relationen, Sitemap | `../schnitzler-kultur/.github/workflows/build.yml` |
