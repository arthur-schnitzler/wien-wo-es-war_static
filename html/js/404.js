// 404: Ist die Adresse ein Tag ohne Ereignisse (JJJJ-MM-TT.html), werden die nächsten Tage
// mit Ereignissen angeboten (Daten: js-data/kalender/uebersicht.json).
(function () {
  "use strict";

  var START = "1860-01-01";
  var ENDE = "1938-12-31";
  var MONATE = ["Jänner", "Februar", "März", "April", "Mai", "Juni", "Juli", "August",
    "September", "Oktober", "November", "Dezember"];
  var WOCHENTAGE = ["Sonntag", "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag"];
  var ANZAHL = 3; // Tage davor und danach

  var treffer = window.location.pathname.match(/(\d{4})-(\d{2})-(\d{2})\.html$/);
  if (!treffer) {
    return;
  }
  var iso = treffer[1] + "-" + treffer[2] + "-" + treffer[3];
  var jahr = +treffer[1], monat = +treffer[2], tag = +treffer[3];
  var datum = new Date(Date.UTC(jahr, monat - 1, tag));
  var gueltig = datum.getUTCFullYear() === jahr && datum.getUTCMonth() === monat - 1 && datum.getUTCDate() === tag;

  var ziel = document.getElementById("fehler-inhalt");

  function text(isoTag, mitWochentag) {
    var t = isoTag.split("-").map(Number);
    var d = new Date(Date.UTC(t[0], t[1] - 1, t[2]));
    return (mitWochentag ? WOCHENTAGE[d.getUTCDay()] + ", " : "") + t[2] + ". " + MONATE[t[1] - 1] + " " + t[0];
  }

  function el(name, attrs, inhalt) {
    var e = document.createElement(name);
    Object.keys(attrs || {}).forEach(function (k) { e.setAttribute(k, attrs[k]); });
    (inhalt || []).forEach(function (c) { e.append(c); });
    return e;
  }

  function zeige(titel, absaetze, liste) {
    ziel.replaceChildren(el("h1", {}, [titel]));
    absaetze.forEach(function (p) { ziel.append(p); });
    if (liste) {
      ziel.append(liste);
    }
    document.title = titel + " – Wien, wo es war";
  }

  if (!gueltig) {
    zeige("Kein gültiges Datum", [el("p", {}, ["„" + iso + "“ ist kein gültiges Datum."])]);
    return;
  }
  if (iso < START || iso > ENDE) {
    zeige(text(iso, true), [el("p", {}, [
      "Die Daten reichen vom " + text(START) + " bis zum " + text(ENDE) + ". ",
      el("a", { href: "jahre.html" }, ["Alle Jahre"])
    ])]);
    return;
  }

  var monatsLink = el("a", { href: "kalender.html?ansicht=monat&datum=" + iso.slice(0, 7) }, [MONATE[monat - 1] + " " + jahr + " im Kalender"]);
  var jahresLink = el("a", { href: jahr + ".html#m" + treffer[2] }, ["Jahr " + jahr]);

  fetch("js-data/kalender/uebersicht.json")
    .then(function (r) { return r.json(); })
    .then(function (daten) {
      var tage = [];
      Object.keys(daten.tage).forEach(function (j) {
        Object.keys(daten.tage[j]).forEach(function (m) {
          daten.tage[j][m].forEach(function (e) {
            tage.push(j + "-" + m + "-" + String(e[0]).padStart(2, "0"));
          });
        });
      });
      Object.keys(daten.laufend || {}).forEach(function (t) { tage.push(t); });
      tage = Array.from(new Set(tage)).sort();
      var vorher = tage.filter(function (t) { return t < iso; }).slice(-ANZAHL);
      var nachher = tage.filter(function (t) { return t > iso; }).slice(0, ANZAHL);
      var liste = el("ul", {}, vorher.concat(nachher).map(function (t) {
        return el("li", {}, [el("a", { href: t + ".html" }, [text(t, true)])]);
      }));
      zeige(text(iso, true), [
        el("p", {}, ["An diesem Tag sind keine Ereignisse verzeichnet."]),
        el("p", {}, ["Die nächsten Tage mit Ereignissen:"])
      ], liste);
      ziel.append(el("p", {}, [monatsLink, " · ", jahresLink]));
    })
    .catch(function () {
      zeige(text(iso, true), [
        el("p", {}, ["An diesem Tag sind keine Ereignisse verzeichnet."]),
        el("p", {}, [monatsLink, " · ", jahresLink])
      ]);
    });
})();
