(() => {
  // Valeurs de secours utilisées si l'overlay ne fournit pas environment.js.
  const config = window.FOODTRACK_CONFIG || {
    environment: "unknown",
    label: "Inconnu",
    threshold: "—",
    logLevel: "—",
    accent: "#0f766e",
    accentDark: "#0b5f58",
    accentSoft: "#ccfbf1"
  };

  // La palette de l'interface suit l'environnement sans dupliquer la feuille CSS.
  const root = document.documentElement;

  root.style.setProperty("--accent", config.accent);
  root.style.setProperty("--accent-dark", config.accentDark);
  root.style.setProperty("--accent-soft", config.accentSoft);

  // Affiche les paramètres injectés par Kustomize dans les zones prévues.
  document.title = `FoodTrack · ${config.label}`;

  document.getElementById("environment").textContent = config.label;
  document.getElementById("footer-environment").textContent = config.label;
  document.getElementById("threshold").textContent = config.threshold;
  document.getElementById("namespace").textContent =
    `foodtrack-${config.environment}`;
  document.getElementById("log-level").textContent = config.logLevel;

  // Données fictives : elles servent uniquement à présenter le tableau de bord.
  const readings = [
    [
      "FT-204",
      "Produits frais",
      "Lille",
      "3,2 °C",
      "Conforme",
      "ok"
    ],
    [
      "FT-118",
      "Surgelés",
      "Rouen",
      "−18,4 °C",
      "Conforme",
      "ok"
    ],
    [
      "FT-087",
      "Produits laitiers",
      "Amiens",
      "5,8 °C",
      "Surveillance",
      "watch"
    ],
    [
      "FT-315",
      "Viandes",
      "Paris",
      "2,1 °C",
      "Conforme",
      "ok"
    ],
    [
      "FT-092",
      "Fruits et légumes",
      "Reims",
      "8,6 °C",
      "Alerte",
      "alert"
    ]
  ];

  // Construit les lignes du tableau à partir du jeu de démonstration.
  document.getElementById("readings").innerHTML = readings
    .map(
      ([
        vehicle,
        load,
        city,
        temperature,
        status,
        statusClass
      ]) => `
        <tr>
          <td class="vehicle">${vehicle}</td>
          <td>${load}</td>
          <td>${city}</td>
          <td class="temperature">${temperature}</td>
          <td>
            <span class="tag ${statusClass}">${status}</span>
          </td>
        </tr>
      `
    )
    .join("");

  // Horodate la dernière vérification affichée dans le bloc d'état.
  const checkedAt = new Intl.DateTimeFormat("fr-FR", {
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit"
  }).format(new Date());

  document.getElementById("last-update").textContent = checkedAt;

  const apiStatus = document.getElementById("api-status");
  const apiDot = document.getElementById("api-dot");
  const globalStatus = document.getElementById("global-status");

  // Vérifie l'API via le reverse proxy Nginx et adapte l'état visuel.
  fetch("/api/", { cache: "no-store" })
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      apiStatus.textContent = "En ligne";
      apiDot.className = "status-dot";
      globalStatus.textContent = "Opérationnelle";
    })
    .catch(() => {
      apiStatus.textContent = "Indisponible";
      apiDot.className = "status-dot offline";
      globalStatus.textContent = "Service dégradé";
      globalStatus.classList.add("offline");
    });
})();