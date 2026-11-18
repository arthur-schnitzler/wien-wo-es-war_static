/**
 * Kalender – Wien, wo es war
 *
 * Fork des SimpleCalendar aus schnitzler-chronik-static/html/js/calendar.js
 * (PLANUNG.md, Abschnitt 5). Änderungen gegenüber der Chronik:
 * - Daten pro Jahr nachgeladen (js-data/kalender/JJJJ.json) statt einer Gesamtdatei;
 *   Übersicht und Gruppenfilter kommen ohne Jahresdaten aus (uebersicht.json)
 * - Kategorien sind Ereignisgruppen (js-data/ereignistypen.json)
 * - die Tagesansicht zeigt Ereigniskarten mit allen URI-Links
 * - Filter nach Quelle, Spielstätte und Entität (?ort= ?werk= ?person= ?institution=)
 * - Ansichten: Zeitraum (Jahre × Monate), Jahr, Monat, Woche; Tag als Seitenleiste
 * - Zustand in der URL, z. B. kalender.html?ansicht=monat&datum=1900-05&gruppen=oper&ort=pmb15
 *   oder kalender.html?ansicht=woche&datum=1900-05-14 (ein beliebiger Tag der Woche);
 *   ein in der Wochenansicht geöffneter Tag: ?ansicht=tag&datum=1900-05-16&von=woche
 */
(function () {
  "use strict";

  const START = 1860;
  const ENDE = 1938;
  const MONATE = ["Jänner", "Februar", "März", "April", "Mai", "Juni", "Juli", "August",
    "September", "Oktober", "November", "Dezember"];
  const WT_KURZ = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"];
  const WT_LANG = ["Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"];
  const ENTITAETEN = { ort: "Ort", werk: "Werk", person: "Person", institution: "Institution" };
  const ANSICHTEN = { zeitraum: "Zeitraum", jahr: "Jahr", monat: "Monat", woche: "Woche" };
  const ERSTER = START + "-01-01";
  const LETZTER = ENDE + "-12-31";
  const REZENSION = "wird rezensiert in";
  const SCHMAL = window.matchMedia("(max-width: 767.98px)");

  /* ---------- Helfer ---------- */

  function h(tag, attrs, ...kinder) {
    const el = document.createElement(tag);
    Object.entries(attrs || {}).forEach(([k, v]) => {
      if (v == null || v === false) return;
      if (k === "class") el.className = v;
      else if (k === "style") el.style.cssText = v;
      else if (k.startsWith("on")) el.addEventListener(k.slice(2), v);
      else el.setAttribute(k, v === true ? "" : v);
    });
    kinder.flat(Infinity).forEach((c) => {
      if (c == null || c === false) return;
      el.append(c instanceof Node ? c : String(c));
    });
    return el;
  }

  const pad = (n) => String(n).padStart(2, "0");
  const schluessel = (j, m, t) => j + "-" + pad(m) + "-" + pad(t);
  const teile = (k) => k.split("-").map(Number);
  const tageImMonat = (j, m) => new Date(Date.UTC(j, m, 0)).getUTCDate();
  // 0 = Montag
  const wochentag = (j, m, t) => (new Date(Date.UTC(j, m - 1, t)).getUTCDay() + 6) % 7;
  function verschiebe(k, tage) {
    const [j, m, t] = teile(k);
    const d = new Date(Date.UTC(j, m - 1, t + tage));
    return schluessel(d.getUTCFullYear(), d.getUTCMonth() + 1, d.getUTCDate());
  }
  const datumText = (k) => { const [j, m, t] = teile(k); return t + ". " + MONATE[m - 1] + " " + j; };
  const datumLang = (k) => { const [j, m, t] = teile(k); return WT_LANG[wochentag(j, m, t)] + ", " + datumText(k); };
  const anzahlText = (n) => (n === 1 ? "1 Ereignis" : n + " Ereignisse");
  const imZeitraum = (k) => k >= ERSTER && k <= LETZTER;

  /* Wochen beginnen am Montag; eine Woche wird über ihren Montag angesprochen */
  const montag = (k) => { const [j, m, t] = teile(k); return verschiebe(k, -wochentag(j, m, t)); };
  // Kalenderwoche nach ISO 8601: Woche des Donnerstags
  function kalenderwoche(mo) {
    const [j, m, t] = teile(verschiebe(mo, 3));
    return Math.floor((Date.UTC(j, m - 1, t) - Date.UTC(j, 0, 1)) / 864e5 / 7) + 1;
  }
  // „14.–20. Mai 1900“, „28. Mai – 3. Juni 1900“, „31. Dezember 1900 – 6. Jänner 1901“
  function wochenTitel(mo) {
    const so = verschiebe(mo, 6);
    const [j1, m1, t1] = teile(mo);
    const [j2, m2, t2] = teile(so);
    if (j1 !== j2) return datumText(mo) + " – " + datumText(so);
    if (m1 !== m2) return t1 + ". " + MONATE[m1 - 1] + " – " + datumText(so);
    return t1 + ".–" + t2 + ". " + MONATE[m1 - 1] + " " + j1;
  }
  // Monat, zu dem eine Woche gehört (der ihres Donnerstags), begrenzt auf den Zeitraum
  function monatDerWoche(mo) {
    let d = verschiebe(mo, 3);
    if (d < ERSTER) d = ERSTER;
    if (d > LETZTER) d = LETZTER;
    const [j, m] = teile(d);
    return { jahr: j, monat: m };
  }

  function hexRgb(hex) {
    const n = parseInt(hex.slice(1), 16);
    return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
  }
  // relative Leuchtdichte nach WCAG 2
  function leuchtdichte(c) {
    const f = (v) => { v /= 255; return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); };
    return 0.2126 * f(c[0]) + 0.7152 * f(c[1]) + 0.0722 * f(c[2]);
  }
  // Farbe mit Weiß gemischt (t = Anteil Weiß); Schrift weiß oder schwarz, je nachdem was mehr Kontrast hat
  function heat(hex, t) {
    const c = hexRgb(hex).map((v) => Math.round(v + (255 - v) * t));
    const l = leuchtdichte(c);
    const weiss = 1.05 / (l + 0.05);
    const schwarz = (l + 0.05) / 0.05;
    return { bg: "rgb(" + c.join(",") + ")", fg: weiss >= schwarz ? "#fff" : "#000" };
  }

  /* ---------- Kalender ---------- */

  class Kalender {
    constructor(el) {
      this.el = el;
      this.jahre = new Map(); // Jahr -> Promise der Jahresdaten
      this.zaehlCache = new Map();
      this.renderNr = 0;
      this.zustand = {
        ansicht: "zeitraum", jahr: 1900, monat: 1, tag: null, woche: null,
        gruppen: null, quelle: "", ort: "", werk: "", person: "", institution: "",
      };
    }

    async init() {
      const lade = (u) => fetch(u).then((r) => { if (!r.ok) throw new Error(u); return r.json(); });
      const [ueb, typen, filter, uris] = await Promise.all([
        lade("js-data/kalender/uebersicht.json"),
        lade("js-data/ereignistypen.json"),
        lade("js-data/kalender/filter.json"),
        lade("js-data/uris.json"),
      ]);
      this.gruppen = typen.gruppen; // [{id, label, farbe, reihenfolge}]
      this.gIndex = new Map(this.gruppen.map((g, i) => [g.id, i]));
      this.gruppeVonTyp = typen.typen;
      this.filterDaten = filter;
      this.uris = uris;
      this.laufend = ueb.laufend || {};
      this.zeitraeume = ueb.zeitraeume || {};
      this.uebersichtLesen(ueb);

      this.zustandAusUrl();
      this.geruest();
      window.addEventListener("popstate", () => { this.zustandAusUrl(); this.render(); });
      document.addEventListener("keydown", (e) => this.taste(e));
      SCHMAL.addEventListener("change", () => this.render());
      await this.render();
    }

    // uebersicht.json: tage[JJJJ][MM] = [[Tag, Gruppenindex, Anzahl, …]]
    uebersichtLesen(ueb) {
      const G = this.gruppen.length;
      const reihenfolge = ueb.gruppen.map((id) => this.gIndex.get(id));
      this.tageBasis = new Map();
      Object.entries(ueb.tage).forEach(([j, monate]) => {
        Object.entries(monate).forEach(([m, eintraege]) => {
          eintraege.forEach((e) => {
            const z = new Array(G).fill(0);
            for (let i = 1; i < e.length; i += 2) z[reihenfolge[e[i]]] += e[i + 1];
            this.tageBasis.set(j + "-" + m + "-" + pad(e[0]), z);
          });
        });
      });
      this.alleTage = [...this.tageBasis.keys()].sort();
    }

    /* ----- Daten ----- */

    jahrLaden(j) {
      if (!this.jahre.has(j)) {
        const p = fetch("js-data/kalender/" + j + ".json")
          .then((r) => r.json())
          .then((d) => {
            d.nachTag = new Map();
            d.ereignisse.forEach((e) => {
              if (!d.nachTag.has(e.datum)) d.nachTag.set(e.datum, []);
              d.nachTag.get(e.datum).push(e);
            });
            d.nachId = new Map(d.ereignisse.map((e) => [e.id, e]));
            return d;
          });
        this.jahre.set(j, p);
      }
      return this.jahre.get(j);
    }

    async alleJahreLaden(fortschritt) {
      const jahre = [];
      for (let j = START; j <= ENDE; j++) jahre.push(j);
      let fertig = 0;
      const arbeiter = async () => {
        while (jahre.length) {
          await this.jahrLaden(jahre.shift());
          fertig++;
          fortschritt(fertig);
        }
      };
      await Promise.all([1, 2, 3, 4, 5, 6].map(arbeiter));
    }

    // Filter, die Ereignisdaten brauchen (nicht nur die Gruppe)
    detailFilter() {
      const z = this.zustand;
      return !!(z.quelle || z.ort || z.werk || z.person || z.institution);
    }

    gruppeAktiv(id) { return !this.zustand.gruppen || this.zustand.gruppen.has(id); }

    gruppeVon(e) { return this.gruppeVonTyp[e.typ] || "sonstiges"; }

    passt(e, jd) {
      if (!this.gruppeAktiv(this.gruppeVon(e))) return false;
      return this.passtDetail(e, jd);
    }

    passtDetail(e, jd) {
      const z = this.zustand;
      if (z.quelle && !(e.quellen || []).includes(z.quelle)) return false;
      if (z.ort && !(e.orte || []).includes(z.ort)) return false;
      if (z.institution && !(e.institutionen || []).includes(z.institution)) return false;
      const werke = (e.werke || []).map((w) => w[0]);
      if (z.werk && !werke.includes(z.werk)) return false;
      if (z.person) {
        const beteiligt = (e.personen || []).some((p) => p[0] === z.person);
        const urheber = werke.some((w) => (jd.urheber[w] || []).some((a) => a[0] === z.person));
        if (!beteiligt && !urheber) return false;
      }
      return true;
    }

    filterSignatur() {
      const z = this.zustand;
      return [z.quelle, z.ort, z.werk, z.person, z.institution].join("|");
    }

    // Tag -> Anzahl je Gruppe für ein Jahr, nach Detailfiltern (nicht nach Gruppen) gefiltert
    async zaehlung(j) {
      if (!this.detailFilter()) return null; // dann gilt tageBasis
      const k = j + "|" + this.filterSignatur();
      if (!this.zaehlCache.has(k)) {
        const jd = await this.jahrLaden(j);
        const G = this.gruppen.length;
        const m = new Map();
        jd.ereignisse.forEach((e) => {
          if (!this.passtDetail(e, jd)) return;
          if (!m.has(e.datum)) m.set(e.datum, new Array(G).fill(0));
          m.get(e.datum)[this.gIndex.get(this.gruppeVon(e)) ?? G - 1]++;
        });
        this.zaehlCache.set(k, m);
      }
      return this.zaehlCache.get(k);
    }

    // Anzahl je Gruppe an einem Tag (ohne Gruppenfilter); zaehl = Ergebnis von zaehlung() oder null
    tagesWerte(tag, zaehl) {
      return (zaehl ? zaehl.get(tag) : this.tageBasis.get(tag)) || null;
    }

    summe(werte) {
      if (!werte) return 0;
      let s = 0;
      werte.forEach((n, i) => { if (this.gruppeAktiv(this.gruppen[i].id)) s += n; });
      return s;
    }

    dominant(werte) {
      let best = -1, beste = 0;
      werte.forEach((n, i) => {
        if (this.gruppeAktiv(this.gruppen[i].id) && n > beste) { beste = n; best = i; }
      });
      return best >= 0 ? this.gruppen[best] : null;
    }

    titel(e, jd) {
      const werke = (e.werke || []).filter((w) => w[1] !== REZENSION);
      if (werke.length === 1) return jd.namen[werke[0][0]] || e.titel || e.typ;
      return e.titel || (werke[0] ? jd.namen[werke[0][0]] : "") || e.typ;
    }

    // ohne Untertitel (Teil nach dem ersten „. “ vor einem Großbuchstaben), für Monat und Woche;
    // „Fidelio, op. 72“, „Klavierquartett Nr. 1“ und „2. Liederabend“ bleiben ganz
    kurztitel(e, jd) {
      return this.titel(e, jd).split(/\.\s(?=[A-ZÄÖÜ])/)[0];
    }

    url(subtype, wert, jd) {
      return /^https?:/.test(wert) ? wert : (jd.praefixe[subtype] || "") + wert;
    }

    /* ----- Zustand und URL ----- */

    zustandAusUrl() {
      const p = new URLSearchParams(window.location.search);
      const z = this.zustand;
      const ansicht = p.get("ansicht");
      const datum = p.get("datum") || "";
      const [j, m, t] = datum.split("-").map(Number);
      z.tag = null;
      if (j >= START && j <= ENDE) z.jahr = j;
      if (m >= 1 && m <= 12) z.monat = m;
      const tagOk = t >= 1 && t <= tageImMonat(z.jahr, z.monat);
      if (ansicht === "tag" && tagOk) {
        z.tag = schluessel(z.jahr, z.monat, t);
        z.ansicht = p.get("von") === "woche" ? "woche" : "monat";
        z.woche = montag(z.tag);
      } else if (ansicht === "woche") {
        z.ansicht = "woche";
        z.woche = tagOk ? montag(schluessel(z.jahr, z.monat, t)) : this.wocheImMonat();
        Object.assign(z, monatDerWoche(z.woche));
      } else if (ANSICHTEN[ansicht]) {
        z.ansicht = ansicht;
      } else if (m) {
        z.ansicht = "monat";
      } else if (j) {
        z.ansicht = "jahr";
      }
      const g = p.get("gruppen");
      z.gruppen = g ? new Set(g.split(",").filter((id) => this.gIndex.has(id))) : null;
      z.quelle = p.get("quelle") || "";
      Object.keys(ENTITAETEN).forEach((k) => { z[k] = /^pmb\d+$/.test(p.get(k) || "") ? p.get(k) : ""; });
    }

    urlAusZustand() {
      const z = this.zustand;
      const p = new URLSearchParams();
      if (z.tag) {
        p.set("ansicht", "tag");
        p.set("datum", z.tag);
        if (z.ansicht === "woche") p.set("von", "woche");
      } else {
        p.set("ansicht", z.ansicht);
        if (z.ansicht === "jahr") p.set("datum", String(z.jahr));
        if (z.ansicht === "monat") p.set("datum", z.jahr + "-" + pad(z.monat));
        // erster Tag der Woche im Zeitraum (die erste Woche beginnt am 26.12.1859)
        if (z.ansicht === "woche") p.set("datum", z.woche < ERSTER ? ERSTER : z.woche);
      }
      if (z.gruppen) p.set("gruppen", [...z.gruppen].join(","));
      if (z.quelle) p.set("quelle", z.quelle);
      Object.keys(ENTITAETEN).forEach((k) => { if (z[k]) p.set(k, z[k]); });
      return "?" + p.toString();
    }

    // neuer Eintrag im Verlauf, damit die Zurück-Taste funktioniert
    weiter(aenderung) {
      Object.assign(this.zustand, aenderung);
      const url = this.urlAusZustand();
      if (url !== window.location.search) history.pushState(null, "", url);
      return this.render();
    }

    taste(e) {
      if (e.target instanceof Element && e.target.closest("input, select, textarea")) return;
      if (e.key === "Escape" && this.zustand.tag) { this.weiter({ tag: null }); return; }
      if (this.zustand.tag) return;
      if (e.key === "ArrowLeft") { e.preventDefault(); this.blaettern(-1); }
      if (e.key === "ArrowRight") { e.preventDefault(); this.blaettern(1); }
    }

    blaettern(r) {
      const z = this.zustand;
      if (z.ansicht === "jahr") {
        const j = z.jahr + r;
        if (j >= START && j <= ENDE) this.weiter({ jahr: j });
      } else if (z.ansicht === "monat") {
        let j = z.jahr, m = z.monat + r;
        if (m > 12) { m = 1; j++; }
        if (m < 1) { m = 12; j--; }
        if (j >= START && j <= ENDE) this.weiter({ jahr: j, monat: m });
      } else if (z.ansicht === "woche") {
        const mo = verschiebe(z.woche, 7 * r);
        if (verschiebe(mo, 6) >= ERSTER && mo <= LETZTER) this.weiter({ woche: mo, ...monatDerWoche(mo) });
      }
    }

    // erste Woche, deren Donnerstag im gewählten Monat liegt
    wocheImMonat() {
      const z = this.zustand;
      const erster = schluessel(z.jahr, z.monat, 1);
      return verschiebe(montag(erster), wochentag(z.jahr, z.monat, 1) >= 4 ? 7 : 0);
    }

    // Woche beim Wechsel in die Wochenansicht: die des offenen Tages, die zuletzt
    // gezeigte, wenn sie in den gewählten Monat fällt, sonst die erste des Monats
    wocheFuerWechsel() {
      const z = this.zustand;
      if (z.tag) return montag(z.tag);
      const erster = schluessel(z.jahr, z.monat, 1);
      const letzter = schluessel(z.jahr, z.monat, tageImMonat(z.jahr, z.monat));
      if (z.woche && verschiebe(z.woche, 6) >= erster && z.woche <= letzter) return z.woche;
      return this.wocheImMonat();
    }

    // Jahre, deren Daten die aktuelle Ansicht braucht (eine Woche kann zwei berühren)
    jahreDerAnsicht() {
      const z = this.zustand;
      if (z.ansicht !== "woche") return [z.jahr];
      const jahre = new Set([teile(z.woche)[0], teile(verschiebe(z.woche, 6))[0]]);
      return [...jahre].filter((j) => j >= START && j <= ENDE);
    }

    /* ----- Gerüst ----- */

    geruest() {
      this.el.replaceChildren();
      this.el.classList.add("kal");
      this.leisteEl = h("div", { class: "kal-leiste" });
      this.filterEl = h("div", { class: "kal-filter" });
      this.statusEl = h("p", { class: "kal-status", role: "status", "aria-live": "polite" });
      this.koerperEl = h("div", { class: "kal-koerper" });
      this.tagEl = h("div", { class: "kal-tag-hintergrund", hidden: true, onclick: () => this.weiter({ tag: null }) });
      this.el.append(this.leisteEl, this.filterEl, this.statusEl, this.koerperEl, this.tagEl);
    }

    /* ----- Rendering ----- */

    async render() {
      const nr = ++this.renderNr;
      const z = this.zustand;
      this.status("");
      this.leiste();

      let zaehlProJahr = new Map();
      if (this.detailFilter()) {
        if (z.ansicht === "zeitraum") {
          await this.alleJahreLaden((n) => {
            if (nr === this.renderNr) this.status("Lade Jahresdaten … " + n + "/" + (ENDE - START + 1));
          });
          for (let j = START; j <= ENDE; j++) zaehlProJahr.set(j, await this.zaehlung(j));
        } else {
          for (const j of this.jahreDerAnsicht()) zaehlProJahr.set(j, await this.zaehlung(j));
        }
      }
      if (nr !== this.renderNr) return;
      this.status("");
      this.zaehlProJahr = zaehlProJahr;
      this.filter();

      let inhalt;
      if (z.ansicht === "zeitraum") inhalt = this.ansichtZeitraum();
      else if (z.ansicht === "jahr") inhalt = this.ansichtJahr();
      else if (z.ansicht === "woche") inhalt = await this.ansichtWoche(nr);
      else inhalt = await this.ansichtMonat(nr);
      if (nr !== this.renderNr) return;
      this.koerperEl.replaceChildren(inhalt);
      await this.tagesleiste(nr);
    }

    status(text) { this.statusEl.textContent = text; }

    zaehlFuer(j) { return this.zaehlProJahr.get(j) || null; }

    leiste() {
      const z = this.zustand;
      const titel = z.ansicht === "zeitraum" ? START + "–" + ENDE
        : z.ansicht === "jahr" ? String(z.jahr)
          : z.ansicht === "woche" ? wochenTitel(z.woche) : MONATE[z.monat - 1] + " " + z.jahr;
      const heute = new Date();
      const vor100 = schluessel(heute.getFullYear() - 100, heute.getMonth() + 1, heute.getDate());
      const datumFeld = h("input", {
        type: "date", class: "form-control form-control-sm", id: "kal-datum",
        min: ERSTER, max: LETZTER,
        value: z.tag || (z.ansicht === "woche" ? (z.woche < ERSTER ? ERSTER : z.woche) : schluessel(z.jahr, z.monat, 1)),
      });
      this.leisteEl.replaceChildren(
        h("div", { class: "btn-group btn-group-sm", role: "group", "aria-label": "Ansicht" },
          Object.entries(ANSICHTEN).map(([id, label]) => h("button", {
            type: "button", class: "btn btn-outline-secondary" + (z.ansicht === id ? " active" : ""),
            "aria-pressed": z.ansicht === id ? "true" : "false",
            onclick: () => this.weiter(id === "woche" && z.ansicht !== "woche"
              ? { ansicht: id, tag: null, woche: this.wocheFuerWechsel() }
              : { ansicht: id, tag: null }),
          }, label))),
        h("div", { class: "kal-navigation" },
          h("button", {
            type: "button", class: "btn btn-sm btn-outline-secondary", "aria-label": "zurück",
            disabled: z.ansicht === "zeitraum", onclick: () => this.blaettern(-1),
          }, "‹"),
          h("h2", { class: "kal-titel h4 mb-0" }, titel),
          h("button", {
            type: "button", class: "btn btn-sm btn-outline-secondary", "aria-label": "weiter",
            disabled: z.ansicht === "zeitraum", onclick: () => this.blaettern(1),
          }, "›")),
        h("form", {
          class: "kal-sprung d-flex gap-1 align-items-center", role: "search",
          onsubmit: (e) => {
            e.preventDefault();
            if (/^\d{4}-\d{2}-\d{2}$/.test(datumFeld.value)) window.location.href = datumFeld.value + ".html";
          },
        },
        h("label", { for: "kal-datum", class: "visually-hidden" }, "Zur Tagesseite springen"),
        datumFeld,
        h("button", { type: "submit", class: "btn btn-sm btn-secondary" }, "Los")),
        h("a", { class: "btn btn-sm btn-link", href: vor100 + ".html" }, "Heute vor 100 Jahren")
      );
    }

    // Anzahl je Gruppe im sichtbaren Zeitraum (für die Filterchips)
    periodeWerte() {
      const z = this.zustand;
      const G = this.gruppen.length;
      const s = new Array(G).fill(0);
      const add = (w) => { if (w) w.forEach((n, i) => { s[i] += n; }); };
      let sichtbar;
      if (z.ansicht === "woche") {
        const so = verschiebe(z.woche, 6);
        sichtbar = (k) => k >= z.woche && k <= so;
      } else {
        const prefix = z.ansicht === "zeitraum" ? "" : z.ansicht === "jahr" ? z.jahr + "-" : z.jahr + "-" + pad(z.monat) + "-";
        sichtbar = (k) => k.startsWith(prefix);
      }
      if (this.detailFilter()) {
        this.zaehlProJahr.forEach((m) => m && m.forEach((w, k) => { if (sichtbar(k)) add(w); }));
      } else {
        this.tageBasis.forEach((w, k) => { if (sichtbar(k)) add(w); });
      }
      return s;
    }

    filter() {
      const z = this.zustand;
      const werte = this.periodeWerte();
      const chips = this.gruppen.map((g, i) => {
        const aktiv = this.gruppeAktiv(g.id);
        return h("button", {
          type: "button", class: "kal-chip gruppe-" + g.id + (aktiv ? " aktiv" : ""),
          "aria-pressed": aktiv ? "true" : "false",
          onclick: () => {
            const set = new Set(z.gruppen || this.gruppen.map((x) => x.id));
            if (set.has(g.id)) set.delete(g.id); else set.add(g.id);
            this.weiter({ gruppen: set.size === this.gruppen.length ? null : set });
          },
        }, h("span", { class: "kal-chip-farbe", "aria-hidden": "true" }), g.label,
        h("span", { class: "kal-chip-zahl" }, werte[i].toLocaleString("de-AT")));
      });
      const nurDiese = h("span", { class: "kal-chip-aktionen" },
        h("button", { type: "button", class: "btn btn-link btn-sm p-0", onclick: () => this.weiter({ gruppen: null }) }, "alle"),
        " · ",
        h("button", { type: "button", class: "btn btn-link btn-sm p-0", onclick: () => this.weiter({ gruppen: new Set() }) }, "keine"));

      const quelle = h("select", {
        class: "form-select form-select-sm", id: "kal-quelle",
        onchange: (e) => this.weiter({ quelle: e.target.value }),
      }, h("option", { value: "" }, "alle Quellen"),
      this.filterDaten.quellen.map(([q, n]) => h("option", { value: q, selected: z.quelle === q }, q + " (" + n.toLocaleString("de-AT") + ")")));

      const orte = this.filterDaten.orte.filter((o) => o[2] >= 20 || o[0] === z.ort);
      const ort = h("select", {
        class: "form-select form-select-sm", id: "kal-ort",
        onchange: (e) => this.weiter({ ort: e.target.value }),
      }, h("option", { value: "" }, "alle Spielstätten"),
      orte.map(([k, name, n]) => h("option", { value: k, selected: z.ort === k }, name + " (" + n.toLocaleString("de-AT") + ")")));

      const entitaeten = ["werk", "person", "institution"].filter((k) => z[k]).map((k) =>
        h("span", { class: "badge text-bg-light border kal-entitaet" },
          ENTITAETEN[k] + ": ", h("a", { href: z[k] + ".html" }, this.name(z[k])), " ",
          h("button", {
            type: "button", class: "btn-close btn-close-sm", "aria-label": ENTITAETEN[k] + "-Filter entfernen",
            onclick: () => this.weiter({ [k]: "" }),
          })));

      const zuruecksetzen = (this.detailFilter() || z.gruppen)
        ? h("button", {
          type: "button", class: "btn btn-sm btn-outline-secondary",
          onclick: () => this.weiter({ gruppen: null, quelle: "", ort: "", werk: "", person: "", institution: "" }),
        }, "Filter zurücksetzen")
        : null;

      this.filterEl.replaceChildren(
        h("div", { class: "kal-chips", role: "group", "aria-label": "Ereignisgruppen" }, chips, nurDiese),
        h("div", { class: "kal-auswahl" },
          h("label", { for: "kal-quelle", class: "visually-hidden" }, "Quelle"), quelle,
          h("label", { for: "kal-ort", class: "visually-hidden" }, "Spielstätte"), ort,
          entitaeten, zuruecksetzen));
    }

    // Name einer Entität: Filterlisten, sonst aus geladenen Jahresdaten
    name(k) {
      const f = this.filterDaten.orte.concat(this.filterDaten.institutionen).find((x) => x[0] === k);
      if (f) return f[1];
      for (const p of this.jahre.values()) {
        if (p.wert && p.wert.namen[k]) return p.wert.namen[k];
      }
      return k;
    }

    /* ----- Zeitraum: Jahre × Monate ----- */

    ansichtZeitraum() {
      const werteMonat = new Map();
      let max = 1;
      for (let j = START; j <= ENDE; j++) {
        const zaehl = this.zaehlFuer(j);
        for (let m = 1; m <= 12; m++) {
          const G = this.gruppen.length;
          const s = new Array(G).fill(0);
          for (let t = 1; t <= tageImMonat(j, m); t++) {
            const w = this.tagesWerte(schluessel(j, m, t), zaehl);
            if (w) w.forEach((n, i) => { s[i] += n; });
          }
          werteMonat.set(j + "-" + m, s);
          max = Math.max(max, this.summe(s));
        }
      }
      const tabelle = h("table", { class: "kal-zeitraum" },
        h("caption", { class: "visually-hidden" }, "Ereignisse pro Monat " + START + "–" + ENDE),
        h("thead", {}, h("tr", {}, h("th", { scope: "col" }, h("span", { class: "visually-hidden" }, "Jahr")),
          MONATE.map((m) => h("th", { scope: "col", title: m }, m.slice(0, 3))),
          h("th", { scope: "col" }, "Σ"))));
      const tbody = h("tbody");
      for (let j = START; j <= ENDE; j++) {
        let jahrSumme = 0;
        const zeile = h("tr", { class: j % 10 === 0 ? "dekade" : null },
          h("th", { scope: "row" }, h("button", { type: "button", class: "kal-jahr-knopf", onclick: () => this.weiter({ ansicht: "jahr", jahr: j }) }, j)));
        for (let m = 1; m <= 12; m++) {
          const s = werteMonat.get(j + "-" + m);
          const n = this.summe(s);
          jahrSumme += n;
          const zelle = h("td");
          if (n) {
            const g = this.dominant(s);
            const anteil = n / max;
            const farbe = heat(g.farbe, anteil > 0.6 ? 0 : anteil > 0.35 ? 0.25 : anteil > 0.15 ? 0.5 : anteil > 0.05 ? 0.7 : 0.85);
            zelle.append(h("button", {
              type: "button", class: "kal-zelle", style: "background:" + farbe.bg + ";color:" + farbe.fg,
              title: MONATE[m - 1] + " " + j + ": " + anzahlText(n),
              "aria-label": anzahlText(n) + " im " + MONATE[m - 1] + " " + j,
              onclick: () => this.weiter({ ansicht: "monat", jahr: j, monat: m }),
            }));
          }
          zeile.append(zelle);
        }
        zeile.append(h("td", { class: "kal-summe" }, jahrSumme ? jahrSumme.toLocaleString("de-AT") : ""));
        tbody.append(zeile);
      }
      tabelle.append(tbody);
      return h("div", { class: "kal-zeitraum-rahmen" }, tabelle,
        h("p", { class: "small text-body-secondary mt-2" },
          "Ein Feld je Monat; die Farbe zeigt die häufigste Ereignisgruppe, die Stärke die Anzahl. Ein Klick öffnet den Monat."));
    }

    /* ----- Jahr: 12 Monatsraster ----- */

    ansichtJahr() {
      const z = this.zustand;
      const zaehl = this.zaehlFuer(z.jahr);
      const raster = h("div", { class: "kal-jahr" });
      for (let m = 1; m <= 12; m++) {
        const grid = h("div", { class: "kal-mini" },
          WT_KURZ.map((w) => h("span", { class: "kal-mini-wt", "aria-hidden": "true" }, w)));
        for (let i = 0; i < wochentag(z.jahr, m, 1); i++) grid.append(h("span"));
        for (let t = 1; t <= tageImMonat(z.jahr, m); t++) {
          const k = schluessel(z.jahr, m, t);
          const w = this.tagesWerte(k, zaehl);
          const n = this.summe(w);
          if (n) {
            const farbe = heat(this.dominant(w).farbe, n >= 5 ? 0 : n >= 3 ? 0.25 : n === 2 ? 0.45 : 0.65);
            grid.append(h("button", {
              type: "button", class: "kal-mini-tag", style: "background:" + farbe.bg + ";color:" + farbe.fg,
              title: anzahlText(n), "aria-label": anzahlText(n) + " am " + datumText(k),
              onclick: () => this.weiter({ jahr: z.jahr, monat: m, tag: k, ansicht: "monat" }),
            }, t));
          } else {
            grid.append(h("span", { class: "kal-mini-leer" }, t));
          }
        }
        raster.append(h("section", { class: "kal-jahr-monat" },
          h("h3", { class: "h6" }, h("button", {
            type: "button", class: "btn btn-link p-0",
            onclick: () => this.weiter({ ansicht: "monat", monat: m }),
          }, MONATE[m - 1])), grid));
      }
      return raster;
    }

    /* ----- Monat: Raster mit Gruppenpunkten und ersten Titeln, schmal als Liste ----- */

    async ansichtMonat(nr) {
      const z = this.zustand;
      const jd = await this.jahrLaden(z.jahr);
      if (nr !== this.renderNr) return h("div");
      const zaehl = this.zaehlFuer(z.jahr);
      const tage = [];
      for (let t = 1; t <= tageImMonat(z.jahr, z.monat); t++) {
        const k = schluessel(z.jahr, z.monat, t);
        const ereignisse = (jd.nachTag.get(k) || []).filter((e) => this.passt(e, jd));
        tage.push({ k, t, w: this.tagesWerte(k, zaehl), ereignisse });
      }
      return SCHMAL.matches ? this.monatsliste(tage, jd) : this.monatsraster(tage, jd);
    }

    punkte(w) {
      return h("span", { class: "kal-punkte", "aria-hidden": "true" },
        this.gruppen.map((g, i) => (w && w[i] && this.gruppeAktiv(g.id))
          ? h("span", { class: "kal-punkt gruppe-" + g.id, title: g.label + ": " + w[i] }) : null));
    }

    monatsraster(tage, jd) {
      const z = this.zustand;
      const grid = h("div", { class: "kal-monat", role: "grid" },
        h("div", { class: "kal-monat-wt", title: "Kalenderwoche", "aria-hidden": "true" }, "KW"),
        WT_KURZ.map((w) => h("div", { class: "kal-monat-wt", "aria-hidden": "true" }, w)));
      tage.forEach(({ k, t, w, ereignisse }) => {
        const n = ereignisse.length;
        const wt = wochentag(z.jahr, z.monat, t);
        // am Zeilenanfang: Knopf für die Wochenansicht
        if (t === 1 || wt === 0) {
          const mo = montag(k);
          grid.append(h("button", {
            type: "button", class: "kal-monat-kw", title: "Woche anzeigen",
            "aria-label": "Woche vom " + wochenTitel(mo) + " anzeigen",
            onclick: () => this.weiter({ ansicht: "woche", woche: mo, tag: null }),
          }, kalenderwoche(mo)));
        }
        if (t === 1) for (let i = 0; i < wt; i++) grid.append(h("div", { class: "kal-monat-leer" }));
        const zelle = h("button", {
          type: "button", class: "kal-monat-tag" + (n ? " hat" : "") + (wt >= 5 ? " wochenende" : "") + (z.tag === k ? " gewaehlt" : ""),
          "aria-label": (n ? anzahlText(n) : "keine Ereignisse") + " am " + datumText(k),
          onclick: () => this.weiter({ tag: k }),
        },
        h("span", { class: "kal-monat-nr" }, t, n ? h("span", { class: "kal-monat-n" }, n) : null),
        this.punkte(w),
        h("span", { class: "kal-monat-titel" },
          ereignisse.slice(0, 2).map((e) => h("span", { class: "gruppe-" + this.gruppeVon(e), title: this.titel(e, jd) }, this.kurztitel(e, jd))),
          n > 2 ? h("span", { class: "kal-mehr" }, "+ " + (n - 2) + " weitere") : null));
        grid.append(zelle);
      });
      return grid;
    }

    monatsliste(tage, jd) {
      const liste = h("ol", { class: "kal-monatsliste list-unstyled" });
      const mit = tage.filter((x) => x.ereignisse.length);
      mit.forEach(({ k, ereignisse }) => {
        liste.append(h("li", {},
          h("button", { type: "button", class: "kal-liste-tag", onclick: () => this.weiter({ tag: k }) },
            h("span", { class: "fw-semibold" }, datumLang(k)), " ", h("span", { class: "text-body-secondary" }, anzahlText(ereignisse.length))),
          h("ul", { class: "list-unstyled kal-liste-titel" },
            ereignisse.slice(0, 4).map((e) => h("li", { class: "gruppe-" + this.gruppeVon(e) }, this.kurztitel(e, jd))),
            ereignisse.length > 4 ? h("li", { class: "kal-mehr" }, "+ " + (ereignisse.length - 4) + " weitere") : null)));
      });
      if (!mit.length) liste.append(h("li", {}, "In diesem Monat gibt es keine Ereignisse, die den Filtern entsprechen."));
      return liste;
    }

    /* ----- Woche: sieben Spalten mit allen Ereignissen, schmal untereinander ----- */

    async ansichtWoche(nr) {
      const z = this.zustand;
      const so = verschiebe(z.woche, 6);
      const nachGruppe = (a, b) => this.gIndex.get(this.gruppeVon(a)) - this.gIndex.get(this.gruppeVon(b));
      const tage = [];
      for (let i = 0; i < 7; i++) {
        const k = verschiebe(z.woche, i);
        if (!imZeitraum(k)) { tage.push({ k, i, aus: true }); continue; }
        const jd = await this.jahrLaden(teile(k)[0]);
        tage.push({ k, i, jd, ereignisse: (jd.nachTag.get(k) || []).filter((e) => this.passt(e, jd)).sort(nachGruppe) });
      }

      // Ereignisse über mehrere Tage, die vor dieser Woche begonnen haben
      const laufendIds = new Set();
      tage.forEach(({ k }) => (this.laufend[k] || []).forEach((id) => laufendIds.add(id)));
      const laufend = [];
      for (const id of laufendIds) {
        const zr = this.zeitraeume[id];
        if (!zr || zr[0] >= z.woche) continue;
        const ljd = await this.jahrLaden(teile(zr[0])[0]);
        const e = ljd.nachId.get(id);
        if (e && this.passt(e, ljd)) laufend.push([e, ljd, zr]);
      }
      if (nr !== this.renderNr) return h("div");

      const summe = tage.reduce((s, x) => s + (x.ereignisse ? x.ereignisse.length : 0), 0);
      const spalten = tage.map(({ k, i, jd, ereignisse, aus }) => {
        const [, m, t] = teile(k);
        const kopfId = "kal-woche-" + k;
        const datum = [h("span", { class: "kal-woche-wt" }, WT_KURZ[i]), " ", t + ". " + MONATE[m - 1]];
        if (aus) {
          return h("section", { class: "kal-woche-tag aus", "aria-labelledby": kopfId },
            h("h3", { class: "kal-woche-kopf", id: kopfId }, h("span", { class: "kal-woche-datum" }, datum)),
            h("p", { class: "kal-woche-hinweis" }, "außerhalb des Zeitraums"));
        }
        const n = ereignisse.length;
        return h("section", {
          class: "kal-woche-tag" + (n ? " hat" : "") + (i >= 5 ? " wochenende" : "") + (z.tag === k ? " gewaehlt" : ""),
          "aria-labelledby": kopfId,
        },
        h("h3", { class: "kal-woche-kopf", id: kopfId },
          h("button", {
            type: "button", class: "kal-woche-datum",
            "aria-label": (n ? anzahlText(n) : "keine Ereignisse") + " am " + datumLang(k),
            onclick: () => this.weiter({ tag: k, jahr: teile(k)[0], monat: m }),
          }, datum, n ? h("span", { class: "kal-woche-n" }, n) : null)),
        n ? h("ol", { class: "kal-woche-liste list-unstyled" },
          ereignisse.map((e) => h("li", {}, this.wochenEintrag(e, jd, k))))
          : h("p", { class: "kal-woche-hinweis" }, "keine Ereignisse"));
      });

      return h("div", { class: "kal-woche-rahmen" },
        laufend.length ? h("div", { class: "kal-woche-laufend" },
          h("h3", { class: "h6 mb-1" }, "Laufend"),
          h("ul", { class: "list-unstyled mb-0" }, laufend.map(([e, ljd, zr]) => h("li", { class: "gruppe-" + this.gruppeVon(e) },
            h("a", { href: e.datum + ".html#" + e.id }, this.kurztitel(e, ljd)),
            h("span", { class: "text-body-secondary" }, " · " + e.typ + ", " + datumText(zr[0]) + " bis " + datumText(zr[1])))))) : null,
        h("div", { class: "kal-woche" }, spalten),
        !summe && !laufend.length
          ? h("p", { class: "text-body-secondary mt-2" }, "In dieser Woche gibt es keine Ereignisse"
            + (this.detailFilter() || z.gruppen ? ", die den Filtern entsprechen." : ".")) : null,
        h("p", { class: "small text-body-secondary mt-2" },
          "Kalenderwoche " + kalenderwoche(z.woche) + " (" + datumText(z.woche) + " bis " + datumText(so) + "). "
          + "Ein Klick auf ein Ereignis oder ein Datum öffnet den Tag mit allen Links; die Pfeiltasten blättern wochenweise."));
    }

    // ein Ereignis in der Wochenansicht: Typ, Titel, Urheber:in und Ort; öffnet den Tag an dieser Karte
    wochenEintrag(e, jd, k) {
      const [j, m] = teile(k);
      const werke = (e.werke || []).filter((w) => w[1] !== REZENSION);
      const urheber = [];
      werke.forEach((w) => (jd.urheber[w[0]] || []).forEach((a) => {
        if (!urheber.includes(a[0])) urheber.push(a[0]);
      }));
      const ort = (e.orte || []).map((o) => (o === "pmb50" ? "Wien" : jd.namen[o] || o));
      const info = [urheber.slice(0, 2).map((a) => jd.namen[a] || a).join(", ") + (urheber.length > 2 ? " u. a." : ""), ort.join(", ")]
        .filter(Boolean).join(" · ");
      return h("button", {
        type: "button", class: "kal-woche-ereignis gruppe-" + this.gruppeVon(e), title: this.titel(e, jd),
        onclick: () => { this.fokus = e.id; this.weiter({ tag: k, jahr: j, monat: m }); },
      },
      h("span", { class: "kal-woche-typ" }, e.typ, e.ende ? " bis " + datumText(e.ende) : ""),
      h("span", { class: "kal-woche-titel" }, this.kurztitel(e, jd)),
      info ? h("span", { class: "kal-woche-info" }, info) : null);
    }

    /* ----- Tag: Seitenleiste mit Ereigniskarten ----- */

    async tagesleiste(nr) {
      const z = this.zustand;
      if (!z.tag) {
        this.tagEl.hidden = true;
        this.tagEl.replaceChildren();
        document.body.classList.remove("kal-offen");
        return;
      }
      const k = z.tag;
      const jd = await this.jahrLaden(teile(k)[0]);
      // laufende Ereignisse, auch aus früheren Jahren
      const laufendIds = this.laufend[k] || [];
      const laufend = [];
      for (const id of laufendIds) {
        const zr = this.zeitraeume[id];
        if (!zr) continue;
        const ljd = await this.jahrLaden(teile(zr[0])[0]);
        const e = ljd.nachId.get(id);
        if (e && this.passt(e, ljd)) laufend.push([e, ljd]);
      }
      if (nr !== this.renderNr) return;
      const alle = jd.nachTag.get(k) || [];
      const sichtbar = alle.filter((e) => this.passt(e, jd))
        .sort((a, b) => this.gIndex.get(this.gruppeVon(a)) - this.gIndex.get(this.gruppeVon(b)));
      const ausgeblendet = alle.length - sichtbar.length;

      const schliessen = h("button", { type: "button", class: "btn-close", "aria-label": "Schließen", onclick: () => this.weiter({ tag: null }) });
      const leiste = h("aside", {
        class: "kal-tag", role: "dialog", "aria-modal": "true", "aria-labelledby": "kal-tag-titel",
        onclick: (e) => e.stopPropagation(),
      },
      h("div", { class: "kal-tag-kopf" },
        h("div", {},
          h("h2", { class: "h5 mb-1", id: "kal-tag-titel" }, datumLang(k)),
          h("div", { class: "small text-body-secondary" }, anzahlText(sichtbar.length),
            ausgeblendet ? " (" + ausgeblendet + " ausgeblendet)" : ""),
          alle.length || laufend.length ? h("a", { href: k + ".html", class: "small" }, "Zur Tagesseite →") : null),
        schliessen),
      h("div", { class: "kal-tag-liste" },
        sichtbar.map((e) => this.karte(e, jd)),
        !sichtbar.length ? h("p", { class: "text-body-secondary" }, "Keine Ereignisse, die den Filtern entsprechen.") : null,
        laufend.length ? h("h3", { class: "h6 mt-3" }, "Laufend") : null,
        laufend.map(([e, ljd]) => this.karte(e, ljd, true))),
      h("div", { class: "kal-tag-fuss" },
        h("button", { type: "button", class: "btn btn-sm btn-outline-secondary", onclick: () => this.nachbar(k, -1) }, "‹ vorheriger Tag"),
        h("button", { type: "button", class: "btn btn-sm btn-outline-secondary", onclick: () => this.nachbar(k, 1) }, "nächster Tag ›")));

      this.tagEl.replaceChildren(leiste);
      this.tagEl.hidden = false;
      document.body.classList.add("kal-offen");
      // aus der Wochenansicht: zur angeklickten Karte springen
      const karte = this.fokus && document.getElementById("kal-karte-" + this.fokus);
      this.fokus = null;
      if (karte) {
        karte.classList.add("fokus");
        karte.scrollIntoView({ block: "nearest" });
        karte.querySelector("h3 a").focus({ preventScroll: true });
      } else {
        schliessen.focus();
      }
    }

    // nächster bzw. vorheriger Tag mit Ereignissen, die den Filtern entsprechen
    async nachbar(k, r) {
      const tage = this.alleTage;
      let p = tage.findIndex((t) => t > k);
      if (p < 0) p = tage.length;
      let x = r > 0 ? p : (tage[p - 1] === k ? p - 2 : p - 1);
      for (; x >= 0 && x < tage.length; x += r) {
        const t = tage[x];
        if (!this.summe(this.tageBasis.get(t))) continue;
        if (this.detailFilter()) {
          const jd = await this.jahrLaden(teile(t)[0]);
          if (!(jd.nachTag.get(t) || []).some((e) => this.passt(e, jd))) continue;
        }
        const [j, m] = teile(t);
        if (this.zustand.ansicht === "woche") return this.weiter({ tag: t, jahr: j, monat: m, woche: montag(t) });
        return this.weiter({ tag: t, jahr: j, monat: m, ansicht: "monat" });
      }
    }

    karte(e, jd, istLaufend) {
      const gruppe = this.gruppeVon(e);
      const werke = (e.werke || []).filter((w) => w[1] !== REZENSION);
      const urheber = [];
      werke.forEach((w) => (jd.urheber[w[0]] || []).forEach((a) => {
        if (!urheber.some((u) => u[0] === a[0])) urheber.push(a);
      }));
      const link = (k) => h("a", { href: k + ".html" }, jd.namen[k] || k);
      const zeile = (label, inhalt) => (inhalt && inhalt.length) ? h("div", { class: "kal-karte-zeile" }, h("span", { class: "text-body-secondary" }, label + " "), inhalt) : null;
      const liste = (keys) => keys.map((k, i) => [i ? ", " : "", k === "pmb50" ? h("a", { href: "pmb50.html" }, "Wien (Ort nicht näher bestimmt)") : link(k)]);

      return h("article", { class: "kal-karte gruppe-" + gruppe, id: istLaufend ? null : "kal-karte-" + e.id },
        h("div", { class: "d-flex flex-wrap gap-2 align-items-baseline" },
          h("span", { class: "badge ereignis-typ" }, e.typ),
          istLaufend && e.ende ? h("span", { class: "small text-body-secondary" }, "bis " + datumText(e.ende)) : null),
        h("h3", { class: "h6 my-1" }, h("a", { href: e.datum + ".html#" + e.id }, this.titel(e, jd))),
        zeile("Ort", liste(e.orte || [])),
        werke.length > 1 ? zeile("Werke", liste(werke.map((w) => w[0]))) : null,
        zeile("Von", liste(urheber.map((a) => a[0]))),
        zeile("Mitwirkende", liste((e.personen || []).filter((p) => p[1] === "hat mitwirkend").map((p) => p[0]))),
        zeile("Teilnehmende", liste((e.personen || []).filter((p) => p[1] === "hat teilnehmend").map((p) => p[0]))),
        h("div", { class: "kal-karte-links d-flex flex-wrap gap-1 mt-1" }, this.links(e, jd)));
    }

    // alle URIs als Links, Reihenfolge und Beschriftung wie auf den Ereigniskarten (js-data/uris.json)
    links(e, jd) {
      const uris = (e.uris || []).map(([s, w], i) => ({ s, url: this.url(s, w, jd), i }));
      const anzahl = {};
      uris.forEach((u) => { anzahl[u.s] = (anzahl[u.s] || 0) + 1; });
      const rang = (s) => (this.uris[s] ? this.uris[s][1] : 3000);
      uris.sort((a, b) => rang(a.s) - rang(b.s) || a.i - b.i);
      const nr = {};
      return uris.map((u) => {
        nr[u.s] = (nr[u.s] || 0) + 1;
        const bekannt = this.uris[u.s];
        const label = (bekannt ? bekannt[0] : u.url.replace(/^[a-z]+:\/\/(www\.)?([^/?#]+).*$/, "$2"))
          + (anzahl[u.s] > 1 ? " " + nr[u.s] : "");
        const klasse = bekannt && bekannt[2] ? "uri-" + u.s.replace(/[^A-Za-z0-9_-]/g, "_") : "uri-neutral";
        return h("a", { href: u.url, target: "_blank", rel: "noopener", title: u.url, class: "uri-pill " + klasse }, label);
      });
    }
  }

  async function start() {
    const el = document.getElementById("kalender");
    if (!el) return;
    const kal = new Kalender(el);
    // geladene Jahresdaten auch synchron erreichbar machen (für name())
    const laden = kal.jahrLaden.bind(kal);
    kal.jahrLaden = (j) => {
      const p = laden(j);
      if (!p.wert) p.then((d) => { p.wert = d; });
      return p;
    };
    try {
      await kal.init();
    } catch (err) {
      console.error(err);
      el.replaceChildren(h("p", { class: "alert alert-warning" },
        "Der Kalender konnte nicht geladen werden. ", h("a", { href: "jahre.html" }, "Zur Übersicht aller Jahre")));
    }
    window.kalender = kal;
  }

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", start);
  else start();
})();
