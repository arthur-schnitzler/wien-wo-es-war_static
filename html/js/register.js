// Register: Tabulator aus der HTML-Tabelle #register (Spaltenoptionen über tabulator-* Attribute)
(function () {
  "use strict";
  var el = document.getElementById("register");
  if (!el || !window.Tabulator) return;
  var tabelle = new Tabulator(el, {
    layout: "fitColumns",
    pagination: true,
    paginationSize: 50,
    paginationSizeSelector: [25, 50, 100, 500],
    paginationCounter: "rows",
    initialSort: [{ column: el.dataset.sortierung || "ereignisse", dir: el.dataset.richtung || "desc" }],
    locale: "de",
    langs: {
      de: {
        pagination: {
          first: "«", first_title: "Erste Seite", last: "»", last_title: "Letzte Seite",
          prev: "‹", prev_title: "Vorherige Seite", next: "›", next_title: "Nächste Seite",
          page_size: "Zeilen", counter: { showing: "", of: "von", rows: "Einträgen", pages: "Seiten" },
        },
        headerFilters: { default: "filtern …" },
      },
    },
  });
  window.registerTabelle = tabelle;
})();
