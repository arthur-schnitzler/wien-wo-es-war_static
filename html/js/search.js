/**
 * Facettensuche über alle Ereignisse (PLANUNG.md, Abschnitt 8).
 * Typesense-Collection (Alias) aus pyscripts/make_ts_index.py; der Zustand steht in der URL.
 */
(function () {
  "use strict";

  // ===== Konfiguration: Instanz und Search-only-Key (offene Frage 4 in PLANUNG.md) =====
  const TYPESENSE = {
    host: "typesense.acdh.oeaw.ac.at",
    port: 443,
    protocol: "https",
    apiKey: "SEARCH_ONLY_KEY_EINTRAGEN",
  };
  const COLLECTION = "wohin-in-wien-damals";
  // ========================================================================================

  const MONATE = ["Jänner", "Februar", "März", "April", "Mai", "Juni", "Juli", "August",
    "September", "Oktober", "November", "Dezember"];
  const datumText = (tag) => {
    const [j, m, t] = tag.split("-").map(Number);
    return t + ". " + MONATE[m - 1] + " " + j;
  };
  const GRUPPEN_KLASSE = {
    "Theater": "theater", "Oper & Operette": "oper", "Ballett & Tanz": "ballett", "Konzert": "konzert",
    "Film": "film", "Lesung & Vortrag": "lesung", "Ausstellung & Schau": "ausstellung",
    "Ball & Gesellschaft": "ball", "Probe": "probe", "Sonstiges": "sonstiges",
  };

  if (!window.instantsearch || !window.TypesenseInstantSearchAdapter) return;

  const adapter = new TypesenseInstantSearchAdapter({
    server: {
      apiKey: TYPESENSE.apiKey,
      nodes: [{ host: TYPESENSE.host, port: TYPESENSE.port, protocol: TYPESENSE.protocol }],
      cacheSearchResultsForSeconds: 2 * 60,
    },
    additionalSearchParameters: {
      query_by: "titel,werke,urheber,personen,orte,institutionen,typ",
      query_by_weights: "4,4,3,2,2,1,1",
      sort_by: "_text_match:desc,datum:asc",
    },
  });

  const search = instantsearch({
    indexName: COLLECTION,
    searchClient: adapter.searchClient,
    routing: true,
    future: { preserveSharedStateOnUnmount: true },
  });

  const liste = {
    root: "",
    searchableInput: "form-control form-control-sm mb-2",
    searchableSubmit: "d-none",
    searchableReset: "d-none",
    list: "list-unstyled mb-1",
    item: "",
    label: "d-flex align-items-center gap-2 small",
    checkbox: "form-check-input mt-0",
    count: "badge text-bg-light border ms-auto",
    showMore: "btn btn-link btn-sm p-0",
  };

  function facette(container, attribute, titel, opts) {
    return instantsearch.widgets.panel({ templates: { header: () => titel } })(
      instantsearch.widgets.refinementList
    )(Object.assign({
      container, attribute, limit: 8, showMore: true, showMoreLimit: 40,
      cssClasses: liste,
      templates: { showMoreText: (d) => (d.isShowingMore ? "weniger" : "mehr") },
    }, opts || {}));
  }

  const suchbar = (ph) => ({ searchable: true, searchablePlaceholder: ph });

  function link(ref) {
    const [, id, name] = ref.split("|");
    const a = document.createElement("a");
    a.href = id + ".html";
    a.textContent = name;
    return a.outerHTML;
  }

  search.addWidgets([
    instantsearch.widgets.searchBox({
      container: "#searchbox",
      placeholder: "Werk, Person, Ort, Spielstätte …",
      showReset: true,
      cssClasses: { form: "d-flex", input: "form-control", submit: "d-none", reset: "btn btn-link" },
    }),
    instantsearch.widgets.stats({
      container: "#stats-container",
      templates: {
        text: (d) => (d.nbHits === 1 ? "1 Ereignis" : d.nbHits.toLocaleString("de-AT") + " Ereignisse"),
      },
    }),
    instantsearch.widgets.sortBy({
      container: "#sort-by",
      cssClasses: { select: "form-select form-select-sm" },
      items: [
        { label: "Relevanz", value: COLLECTION },
        { label: "Datum aufsteigend", value: COLLECTION + "/sort/datum:asc" },
        { label: "Datum absteigend", value: COLLECTION + "/sort/datum:desc" },
      ],
    }),
    instantsearch.widgets.panel({ templates: { header: () => "Zeitraum" } })(instantsearch.widgets.rangeInput)({
      container: "#rf-jahr",
      attribute: "jahr",
      templates: { separatorText: () => "bis", submitText: () => "OK" },
      cssClasses: { form: "d-flex gap-1 align-items-center", input: "form-control form-control-sm", submit: "btn btn-sm btn-secondary" },
    }),
    facette("#rf-gruppe", "gruppe", "Ereignisgruppe"),
    facette("#rf-typ", "typ", "Ereignistyp", suchbar("Typ suchen")),
    facette("#rf-quellen", "quellen", "Quelle"),
    facette("#rf-orte", "orte", "Ort", suchbar("Ort suchen")),
    facette("#rf-werke", "werke", "Werk", suchbar("Werk suchen")),
    facette("#rf-urheber", "urheber", "Urheber:in", suchbar("Urheber:in suchen")),
    facette("#rf-personen", "personen", "Mitwirkende und Teilnehmende", suchbar("Person suchen")),
    facette("#rf-institutionen", "institutionen", "Veranstaltet von", suchbar("Institution suchen")),
    instantsearch.widgets.currentRefinements({
      container: "#current-refinements",
      cssClasses: { list: "list-inline mb-0", item: "list-inline-item", category: "badge text-bg-light border me-1", delete: "btn btn-sm p-0 ms-1" },
    }),
    instantsearch.widgets.clearRefinements({
      container: "#clear-refinements",
      templates: { resetLabel: () => "Filter zurücksetzen" },
      cssClasses: { button: "btn btn-sm btn-outline-secondary", disabledButton: "d-none" },
    }),
    instantsearch.widgets.hits({
      container: "#hits",
      cssClasses: { list: "list-unstyled", item: "mb-3" },
      templates: {
        empty: (r) => "Keine Ereignisse für „" + r.query + "“.",
        item(hit, { html, components }) {
          const gruppe = GRUPPEN_KLASSE[hit.gruppe] || "sonstiges";
          const refs = hit.refs || [];
          const orte = refs.filter((r) => r.startsWith("ort|")).map(link).join(", ");
          const urheber = refs.filter((r) => r.startsWith("urheber|")).map(link).join(", ");
          const links = (hit.links || []).map((l) => {
            const [label, url, klasse] = l.split("|");
            const a = document.createElement("a");
            a.href = url; a.target = "_blank"; a.rel = "noopener"; a.title = url;
            a.className = "uri-pill " + klasse; a.textContent = label;
            return a.outerHTML;
          }).join(" ");
          return html`<article class="kal-karte gruppe-${gruppe}">
            <div class="d-flex flex-wrap gap-2 align-items-baseline">
              <span class="badge ereignis-typ">${hit.typ}</span>
              <a class="small" href="${hit.tag}.html">${datumText(hit.tag)}</a>
            </div>
            <h3 class="h6 my-1"><a href="${hit.tag}.html#${hit.id}">${components.Highlight({ hit, attribute: "titel" })}</a></h3>
            ${orte ? html`<div class="kal-karte-zeile"><span class="text-body-secondary">Ort </span><span dangerouslySetInnerHTML=${{ __html: orte }}></span></div>` : ""}
            ${urheber ? html`<div class="kal-karte-zeile"><span class="text-body-secondary">Von </span><span dangerouslySetInnerHTML=${{ __html: urheber }}></span></div>` : ""}
            <div class="d-flex flex-wrap gap-1 mt-1" dangerouslySetInnerHTML=${{ __html: links }}></div>
          </article>`;
        },
      },
    }),
    instantsearch.widgets.pagination({
      container: "#pagination",
      padding: 2,
      cssClasses: { list: "pagination pagination-sm flex-wrap", item: "page-item", link: "page-link", selectedItem: "active", disabledItem: "disabled" },
    }),
  ]);

  search.on("error", (e) => {
    console.error(e);
    const el = document.getElementById("suche-fehler");
    if (el) el.hidden = false;
  });

  search.start();
})();
