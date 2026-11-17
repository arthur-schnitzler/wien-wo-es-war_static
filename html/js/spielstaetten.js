// Karte der Spielstätten im Ortsregister: Kreisgröße nach Anzahl der Ereignisse
(function () {
  "use strict";
  var el = document.getElementById("spielstaetten-karte");
  var daten = document.getElementById("spielstaetten-daten");
  if (!el || !daten || !window.L) return;
  var orte = JSON.parse(daten.textContent); // [lat, lng, Name, id, Anzahl]
  var karte = L.map(el, { scrollWheelZoom: false }).setView([48.2082, 16.3738], 12);
  L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
    maxZoom: 19,
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
  }).addTo(karte);
  var max = orte.reduce(function (m, o) { return Math.max(m, o[4]); }, 1);
  var punkte = orte
    .sort(function (a, b) { return b[4] - a[4]; })
    .map(function (o) {
      var r = 4 + 26 * Math.sqrt(o[4] / max);
      var name = document.createElement("a");
      name.href = o[3] + ".html";
      name.textContent = o[2];
      var inhalt = document.createElement("div");
      inhalt.append(name, document.createElement("br"),
        o[4] + (o[4] === 1 ? " Ereignis" : " Ereignisse") + " · ");
      var kal = document.createElement("a");
      kal.href = "kalender.html?ansicht=zeitraum&ort=" + o[3];
      kal.textContent = "im Kalender";
      inhalt.append(kal);
      return L.circleMarker([o[0], o[1]], {
        radius: r, color: "#3B290E", weight: 1, fillColor: "#976A37", fillOpacity: 0.55,
      }).bindPopup(inhalt).bindTooltip(o[2]);
    });
  var gruppe = L.featureGroup(punkte).addTo(karte);
  if (punkte.length) karte.fitBounds(gruppe.getBounds(), { padding: [20, 20], maxZoom: 14 });
})();
