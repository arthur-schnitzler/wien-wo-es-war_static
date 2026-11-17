// Tagesseiten: Datumssprung, „Link kopieren“, „Zitieren“
(function () {
  "use strict";

  // Datumssprung: führt direkt zur Tagesseite; Tage ohne Ereignisse fängt 404.html ab
  document.querySelectorAll("form.datum-sprung").forEach(function (form) {
    form.addEventListener("submit", function (ev) {
      ev.preventDefault();
      var wert = form.querySelector('input[type="date"]').value;
      if (/^\d{4}-\d{2}-\d{2}$/.test(wert)) {
        window.location.href = wert + ".html";
      }
    });
  });

  // „Heute vor 100 Jahren“: Link auf die Tagesseite des Datums vor n Jahren
  document.querySelectorAll("a[data-heute-vor]").forEach(function (a) {
    var heute = new Date();
    var jahr = heute.getFullYear() - Number(a.dataset.heuteVor);
    var monat = String(heute.getMonth() + 1).padStart(2, "0");
    var tag = String(heute.getDate()).padStart(2, "0");
    a.href = jahr + "-" + monat + "-" + tag + ".html";
    a.title = tag + "." + monat + "." + jahr;
  });

  function kopieren(text, knopf) {
    var fertig = function () {
      var alt = knopf.innerHTML;
      knopf.textContent = "Kopiert";
      setTimeout(function () {
        knopf.innerHTML = alt;
      }, 1500);
    };
    if (navigator.clipboard && window.isSecureContext) {
      navigator.clipboard.writeText(text).then(fertig);
    } else {
      window.prompt("Zum Kopieren:", text);
    }
  }

  // Permalink: pmbNNNN.html leitet auf die Karte im Starttag weiter
  function permalink(karte) {
    return new URL(karte.dataset.ereignis + ".html", window.location.href).href;
  }

  function zitat(karte) {
    var titel = karte.querySelector(".ereignis-titel").textContent.replace(/\s+/g, " ").trim();
    var seit = karte.querySelector(".seit a");
    var datum = seit
      ? seit.textContent.trim()
      : document.querySelector("h1").textContent.replace(/^[^,]*,\s*/, "").trim();
    var projekt = document.querySelector('meta[name="description"]');
    var quelle = document.body.dataset.zitatQuelle || (projekt ? projekt.content : document.title);
    return titel + ", " + datum + ". In: " + quelle + ". " + permalink(karte);
  }

  document.addEventListener("click", function (ev) {
    var knopf = ev.target.closest(".link-kopieren, .zitat-kopieren");
    if (!knopf) {
      return;
    }
    var karte = knopf.closest(".ereignis");
    if (knopf.classList.contains("link-kopieren")) {
      kopieren(permalink(karte), knopf);
    } else {
      kopieren(zitat(karte), knopf);
    }
  });
})();
