import { 
  savePlayerToFirestore, 
  deletePlayerFromFirestore,
  saveGameToFirestore, 
  deleteGameFromFirestore,
  saveSlotToFirestore, 
  deleteSlotFromFirestore,
  subscribeToPlayers, 
  subscribeToGames, 
  subscribeToSlots,
  trackEvent,
  setUserAnalyticsIdentity
} from "./firebase-config.js";

// Register Service Worker for background Push Notifications
if ("serviceWorker" in navigator) {
  navigator.serviceWorker.register("./sw.js").then((reg) => {
    console.log("Service Worker registered:", reg.scope);
  }).catch((err) => {
    console.warn("Service Worker registration notice:", err);
  });
}

// Initial Santa Cruz Mock Community Data for zero-config startup
const initialCommunityPlayers = [
  {
    id: "kai-slug-001",
    name: "Kai Rodriguez",
    nickname: "The Jet",
    avatarEmoji: "🦈",
    phoneNumber: "8315550101",
    password: "volleyball123",
    rating: "AA",
    eloRating: 2240,
    homeBeach: "Main Beach",
    starRatingSum: 24,
    starRatingCount: 5,
    wins: 38,
    losses: 7,
    streak: 6,
    pointsScored: 940,
    pointsAllowed: 610,
    uniquePartnerIds: ["taylor-slug-002", "maya-slug-003", "carlos-slug-004"],
    uniqueOpponentIds: ["chloe-slug-005", "lucas-slug-006"]
  },
  {
    id: "taylor-slug-002",
    name: "Taylor Jenkins",
    nickname: "Sand Fox",
    avatarEmoji: "slug", // Banana Slug mascot
    phoneNumber: "8315550102",
    password: "volleyball123",
    rating: "AA",
    eloRating: 2195,
    homeBeach: "Main Beach",
    starRatingSum: 40,
    starRatingCount: 8,
    wins: 34,
    losses: 9,
    streak: 3,
    pointsScored: 890,
    pointsAllowed: 640,
    uniquePartnerIds: ["kai-slug-001", "maya-slug-003"],
    uniqueOpponentIds: ["carlos-slug-004", "lucas-slug-006"]
  },
  {
    id: "maya-slug-003",
    name: "Maya Lin",
    nickname: "Sky High",
    avatarEmoji: "🦦",
    phoneNumber: "8315550103",
    password: "volleyball123",
    rating: "A",
    eloRating: 1880,
    homeBeach: "Harbor Beach",
    starRatingSum: 34,
    starRatingCount: 7,
    wins: 29,
    losses: 12,
    streak: 4,
    pointsScored: 810,
    pointsAllowed: 690,
    uniquePartnerIds: ["kai-slug-001", "chloe-slug-005"],
    uniqueOpponentIds: ["taylor-slug-002"]
  },
  {
    id: "carlos-slug-004",
    name: "Carlos Mendez",
    nickname: "Block Party",
    avatarEmoji: "🐋",
    phoneNumber: "8315550104",
    password: "volleyball123",
    rating: "A",
    eloRating: 1825,
    homeBeach: "4th Street",
    starRatingSum: 28,
    starRatingCount: 6,
    wins: 25,
    losses: 14,
    streak: -1,
    pointsScored: 760,
    pointsAllowed: 710,
    uniquePartnerIds: ["lucas-slug-006"],
    uniqueOpponentIds: ["kai-slug-001", "taylor-slug-002"]
  },
  {
    id: "chloe-slug-005",
    name: "Chloe Dupont",
    nickname: "Ace",
    avatarEmoji: "slug", // Banana Slug mascot
    phoneNumber: "8315550105",
    password: "volleyball123",
    rating: "B",
    eloRating: 1610,
    homeBeach: "Main Beach",
    starRatingSum: 29,
    starRatingCount: 6,
    wins: 19,
    losses: 16,
    streak: 2,
    pointsScored: 680,
    pointsAllowed: 670,
    uniquePartnerIds: ["maya-slug-003"],
    uniqueOpponentIds: ["kai-slug-001"]
  },
  {
    id: "lucas-slug-006",
    name: "Lucas Silva",
    nickname: "Breeze",
    avatarEmoji: "🏐",
    phoneNumber: "8315550106",
    password: "volleyball123",
    rating: "Intermediate",
    eloRating: 1390,
    homeBeach: "Harbor Beach",
    starRatingSum: 23,
    starRatingCount: 5,
    wins: 14,
    losses: 18,
    streak: -2,
    pointsScored: 590,
    pointsAllowed: 640,
    uniquePartnerIds: ["carlos-slug-004"],
    uniqueOpponentIds: ["kai-slug-001", "taylor-slug-002"]
  }
];

const initialCommunityGames = [
  {
    id: "game-001",
    title: "Saturday Morning AA Doubles",
    targetRating: "AA",
    isLevelLocked: true,
    hostPlayerId: "kai-slug-001",
    courtLocation: "Main Beach",
    courtNumber: "Court #1",
    scheduledDate: new Date(Date.now() + 86400000).toISOString(),
    status: "scheduled",
    isAutoMatched: false,
    matchedOptionName: "Host Scheduled",
    notes: "Tournament AA practice. High intensity.",
    team1PlayerIds: ["kai-slug-001"],
    team2PlayerIds: ["taylor-slug-002"],
    submittedRatings: {},
    setScores: []
  },
  {
    id: "game-002",
    title: "A Level Sunset Clash",
    targetRating: "A",
    isLevelLocked: true,
    hostPlayerId: "maya-slug-003",
    courtLocation: "4th Street",
    courtNumber: "Court #2",
    scheduledDate: new Date(Date.now() + 172800000).toISOString(),
    status: "scheduled",
    isAutoMatched: false,
    matchedOptionName: "Host Scheduled",
    notes: "Sideout rallies & cut-shot drills.",
    team1PlayerIds: ["maya-slug-003"],
    team2PlayerIds: ["carlos-slug-004"],
    submittedRatings: {},
    setScores: []
  },
  {
    id: "game-003",
    title: "Harbor B Doubles (Need 1)",
    targetRating: "B",
    isLevelLocked: true,
    hostPlayerId: "chloe-slug-005",
    courtLocation: "Harbor Beach",
    courtNumber: "Court #1",
    scheduledDate: new Date(Date.now() + 86400000).toISOString(),
    status: "scheduled",
    isAutoMatched: false,
    matchedOptionName: "Host Scheduled",
    notes: "Need 1 more solid B player for 3 sets to 21.",
    team1PlayerIds: ["chloe-slug-005"],
    team2PlayerIds: ["carlos-slug-004"],
    submittedRatings: {},
    setScores: []
  },
  {
    id: "game-004",
    title: "Sunday Intermediate Fun Sets",
    targetRating: "Intermediate",
    isLevelLocked: true,
    hostPlayerId: "lucas-slug-006",
    courtLocation: "Seabright Beach",
    courtNumber: "Court #1",
    scheduledDate: new Date(Date.now() + 259200000).toISOString(),
    status: "scheduled",
    isAutoMatched: false,
    matchedOptionName: "Host Scheduled",
    notes: "Friendly pickup doubles, learning handsets.",
    team1PlayerIds: ["lucas-slug-006"],
    team2PlayerIds: [],
    submittedRatings: {},
    setScores: []
  }
];

// App State
export function isUpcomingGame(game) {
  if (!game) return false;
  if (!game.status) return true;
  const s = String(game.status).trim().toLowerCase();
  return s === "scheduled" || s === "in progress" || s === "inprogress" || s === "open" || s === "upcoming";
}

export function parseGameDate(rawDate) {
  if (!rawDate) return new Date();
  if (typeof rawDate === "string") {
    const d = new Date(rawDate);
    if (!isNaN(d.getTime())) return d;
  }
  if (typeof rawDate === "number") {
    // Apple Reference Date (seconds since 2001-01-01: ~500M to 2B)
    if (rawDate > 500000000 && rawDate < 2000000000) {
      return new Date((rawDate + 978307200) * 1000);
    }
    // Unix timestamp in seconds
    if (rawDate > 1000000000 && rawDate < 10000000000) {
      return new Date(rawDate * 1000);
    }
    // Unix timestamp in milliseconds
    return new Date(rawDate);
  }
  if (typeof rawDate === "object" && rawDate !== null) {
    if (rawDate.seconds) {
      return new Date(rawDate.seconds * 1000);
    }
    if (typeof rawDate.toDate === "function") {
      return rawDate.toDate();
    }
  }
  return new Date();
}
window.isUpcomingGame = isUpcomingGame;
window.parseGameDate = parseGameDate;

// Matches iOS SetGame.parseUUID deterministic hash for cross-platform player IDs
export function deterministicUUID(str) {
  if (!str) return "";
  const s = String(str).trim();
  if (/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(s)) {
    return s.toUpperCase();
  }
  const bytes = new TextEncoder().encode(s);
  const hash = new Uint8Array(16);
  for (let i = 0; i < bytes.length; i++) {
    hash[i % 16] ^= bytes[i];
  }
  hash[6] = (hash[6] & 0x0F) | 0x40;
  hash[8] = (hash[8] & 0x3F) | 0x80;
  const hex = Array.from(hash).map(b => b.toString(16).padStart(2, "0").toUpperCase()).join("");
  return `${hex.slice(0,8)}-${hex.slice(8,12)}-${hex.slice(12,16)}-${hex.slice(16,20)}-${hex.slice(20,32)}`;
}
window.deterministicUUID = deterministicUUID;

export function isSamePlayer(id1, id2) {
  if (!id1 || !id2) return false;
  const s1 = String(id1).trim().toLowerCase();
  const s2 = String(id2).trim().toLowerCase();
  if (s1 === s2) return true;
  return deterministicUUID(id1).toUpperCase() === deterministicUUID(id2).toUpperCase();
}
window.isSamePlayer = isSamePlayer;

export function isPlayerInList(list, playerId) {
  if (!Array.isArray(list) || !playerId) return false;
  return list.some(id => isSamePlayer(id, playerId));
}
window.isPlayerInList = isPlayerInList;

export function getUniqueConnectionsCount(player) {
  if (!player) return 0;
  const partners = player.uniquePartnerIds || [];
  const opponents = player.uniqueOpponentIds || [];
  const all = new Set([...partners, ...opponents]);
  return all.size;
}

export function getPopularKidsTitle(connections) {
  if (connections >= 30) return "👑 Beach Mayor";
  if (connections >= 20) return "🌟 Social Catalyst";
  if (connections >= 12) return "🤝 Community Wingman";
  if (connections >= 5) return "🏖️ Active Regular";
  return "🌱 New on Court";
}

// ==========================================
// Beach Volleyball Weather Service (Open-Meteo)
// ==========================================
export const weatherService = {
  cache: {},
  inFlight: {},

  getCoordinates(court) {
    const clean = String(court || "").trim().toLowerCase();
    if (clean.includes("harbor")) {
      return { lat: 36.9631, lon: -122.0016 }; // Santa Cruz Harbor Beach
    } else if (clean.includes("4th") || clean.includes("seabright")) {
      return { lat: 36.9650, lon: -122.0100 }; // 4th Ave / Seabright Beach
    } else if (clean.includes("manhattan")) {
      return { lat: 33.8837, lon: -118.4116 }; // Manhattan Beach Pier
    } else if (clean.includes("hermosa")) {
      return { lat: 33.8617, lon: -118.4011 }; // Hermosa Beach
    } else if (clean.includes("huntington")) {
      return { lat: 33.6595, lon: -117.9988 }; // Huntington Beach
    }
    // Default: Main Beach, Santa Cruz
    return { lat: 36.9638, lon: -122.0179 };
  },

  getCacheKey(court, rawDate) {
    const d = parseGameDate(rawDate);
    const dateStr = d.toLocaleDateString("en-CA"); // YYYY-MM-DD
    const hour = d.getHours();
    const cleanCourt = String(court || "Main Beach").trim().toLowerCase().replace(/\s+/g, "-");
    return `${cleanCourt}_${dateStr}_${hour}`;
  },

  getCached(court, rawDate) {
    const key = this.getCacheKey(court, rawDate);
    if (this.cache[key]) return this.cache[key];
    try {
      const stored = sessionStorage.getItem(`wb_weather_${key}`);
      if (stored) {
        const parsed = JSON.parse(stored);
        this.cache[key] = parsed;
        return parsed;
      }
    } catch (e) {}
    return null;
  },

  setCached(court, rawDate, forecast) {
    const key = this.getCacheKey(court, rawDate);
    this.cache[key] = forecast;
    try {
      sessionStorage.setItem(`wb_weather_${key}`, JSON.stringify(forecast));
    } catch (e) {}
  },

  async getForecast(court, rawDate) {
    const cached = this.getCached(court, rawDate);
    if (cached) return cached;

    const key = this.getCacheKey(court, rawDate);
    if (this.inFlight[key]) return this.inFlight[key];

    this.inFlight[key] = this.fetchForecast(court, rawDate)
      .then(forecast => {
        this.setCached(court, rawDate, forecast);
        delete this.inFlight[key];
        return forecast;
      })
      .catch(err => {
        console.warn("Weather fetch notice:", err);
        const fallback = this.getFallback(court, rawDate);
        this.setCached(court, rawDate, fallback);
        delete this.inFlight[key];
        return fallback;
      });

    return this.inFlight[key];
  },

  async fetchForecast(court, rawDate) {
    const coords = this.getCoordinates(court);
    const targetDate = parseGameDate(rawDate);
    const url = `https://api.open-meteo.com/v1/forecast?latitude=${coords.lat}&longitude=${coords.lon}&hourly=temperature_2m,uv_index,wind_speed_10m,weather_code&temperature_unit=fahrenheit&wind_speed_unit=mph&timezone=auto&past_days=7&forecast_days=14`;

    const res = await fetch(url);
    if (!res.ok) throw new Error(`Weather API error ${res.status}`);
    const data = await res.json();
    return this.parseClosestHour(data, court, targetDate);
  },

  parseClosestHour(data, court, targetDate) {
    const times = data.hourly?.time || [];
    if (times.length === 0) return this.getFallback(court, targetDate);

    let bestIdx = 0;
    let minDiff = Infinity;
    const targetTs = targetDate.getTime();

    for (let i = 0; i < times.length; i++) {
      const d = new Date(times[i]);
      const diff = Math.abs(d.getTime() - targetTs);
      if (diff < minDiff) {
        minDiff = diff;
        bestIdx = i;
      }
    }

    const tempF = Math.round(data.hourly.temperature_2m[bestIdx] ?? 72);
    const uvIndex = Math.round((data.hourly.uv_index[bestIdx] ?? 5) * 10) / 10;
    const windMph = Math.round(data.hourly.wind_speed_10m[bestIdx] ?? 8);
    const code = data.hourly.weather_code[bestIdx] ?? 0;

    const { emoji, text } = this.interpretWeatherCode(code);
    const uvCategory = this.getUvCategory(uvIndex);
    const windCategory = this.getWindCategory(windMph);
    const windAdvice = this.getWindAdvice(windMph);
    const uvAdvice = this.getUvAdvice(uvIndex);

    return {
      courtLocation: court,
      dateSlot: times[bestIdx],
      tempF,
      uvIndex,
      uvCategory,
      uvColor: this.getUvColor(uvIndex),
      windMph,
      windCategory,
      windAdvice,
      uvAdvice,
      conditionEmoji: emoji,
      conditionText: text,
      compactSummary: `${tempF}°F • UV ${Math.round(uvIndex)} (${uvCategory}) • 💨 ${windMph} mph (${windCategory})`
    };
  },

  getFallback(court, targetDate) {
    const hour = parseGameDate(targetDate).getHours();
    let tempF = 72;
    let uvIndex = 5.0;
    let windMph = 8;
    if (hour < 11) {
      tempF = 65;
      uvIndex = 3.5;
      windMph = 5;
    } else if (hour < 16) {
      tempF = 74;
      uvIndex = 7.0;
      windMph = 9;
    } else {
      tempF = 68;
      uvIndex = 2.0;
      windMph = 8;
    }
    const uvCategory = this.getUvCategory(uvIndex);
    const windCategory = this.getWindCategory(windMph);
    return {
      courtLocation: court,
      dateSlot: "avg",
      tempF,
      uvIndex,
      uvCategory,
      uvColor: this.getUvColor(uvIndex),
      windMph,
      windCategory,
      windAdvice: this.getWindAdvice(windMph),
      uvAdvice: this.getUvAdvice(uvIndex),
      conditionEmoji: "☀️",
      conditionText: "Seasonal Average",
      compactSummary: `${tempF}°F • UV ${Math.round(uvIndex)} (${uvCategory}) • 💨 ${windMph} mph (${windCategory})`
    };
  },

  interpretWeatherCode(code) {
    if (code === 0) return { emoji: "☀️", text: "Sunny" };
    if (code === 1 || code === 2) return { emoji: "🌤️", text: "Mostly Sunny" };
    if (code === 3) return { emoji: "☁️", text: "Overcast" };
    if (code === 45 || code === 48) return { emoji: "🌫️", text: "Foggy" };
    if (code >= 51 && code <= 55) return { emoji: "🌦️", text: "Light Drizzle" };
    if (code >= 61 && code <= 65) return { emoji: "🌧️", text: "Rain" };
    if (code >= 80 && code <= 82) return { emoji: "🌧️", text: "Rain Showers" };
    if (code >= 95 && code <= 99) return { emoji: "⛈️", text: "Thunderstorm" };
    return { emoji: "☀️", text: "Clear" };
  },

  getUvCategory(uv) {
    if (uv < 3) return "Low";
    if (uv < 6) return "Moderate";
    if (uv < 8) return "High";
    if (uv < 11) return "Very High";
    return "Extreme";
  },

  getUvColor(uv) {
    if (uv < 3) return "#16a34a"; // green
    if (uv < 6) return "#d97706"; // amber
    if (uv < 8) return "#ea580c"; // orange
    if (uv < 11) return "#dc2626"; // red
    return "#9333ea"; // purple
  },

  getUvAdvice(uv) {
    if (uv < 3) return "Minimal sun protection needed.";
    if (uv < 6) return "Apply SPF 30+ sunscreen and wear sunglasses.";
    if (uv < 8) return "Generous SPF 50+, hat & sunglasses strongly recommended.";
    return "Extreme exposure: seek shade between sets and reapply SPF often.";
  },

  getWindCategory(wind) {
    if (wind < 6) return "Calm";
    if (wind < 12) return "Breezy";
    if (wind < 18) return "Windy";
    return "High Wind";
  },

  getWindAdvice(wind) {
    if (wind < 6) return "Ideal beach conditions • Crisp sets and consistent float serves.";
    if (wind < 12) return "Gentle ocean breeze • Mild ball drift; favor tighter setting.";
    if (wind < 18) return "Noticeable wind • Ball floats quickly; adjust approach and deep passes.";
    return "High coastal gusts • Tough passing; keep sets low and aggressive.";
  }
};
window.weatherService = weatherService;

export function renderWeatherLine(game) {
  const cached = weatherService.getCached(game.courtLocation, game.scheduledDate);
  if (cached) {
    return buildWeatherLineHtml(game.id, cached);
  }

  // Trigger background fetch and update element
  weatherService.getForecast(game.courtLocation, game.scheduledDate).then(w => {
    const el = document.getElementById(`weather-line-${game.id}`);
    if (el && w) {
      el.innerHTML = buildWeatherLineHtml(game.id, w);
    }
    const cardEl = document.getElementById(`weather-details-${game.id}`);
    if (cardEl && w) {
      cardEl.innerHTML = renderWeatherDetailsCard(game, w);
    }
  }).catch(() => {});

  return `
    <div class="weather-capsule-dark">
      <div style="display:flex; align-items:center; gap:6px;">
        <span style="font-size:18px;">☀️</span>
        <span style="font-size:13px; color:rgba(255,255,255,0.7);">Checking forecast...</span>
      </div>
    </div>
  `;
}

function buildWeatherLineHtml(gameId, w) {
  const uvCat = w.uvCategory || (w.uvIndex >= 6 ? "High" : w.uvIndex >= 3 ? "Moderate" : "Low");
  const uvColor = w.uvColor || (w.uvIndex >= 6 ? "#ef4444" : w.uvIndex >= 3 ? "#f59e0b" : "#10b981");
  const windCat = w.windCategory || (w.windMph >= 12 ? "Windy" : w.windMph >= 6 ? "Breezy" : "Calm");
  const windDir = w.windDirection || "NW";

  return `
    <div class="weather-capsule-dark" onclick="window.toggleWeatherDetails('${gameId}')" title="Click for beach volleyball playing conditions">
      <!-- Temp -->
      <div style="display:flex; align-items:center; gap:6px;">
        <span style="font-size:18px;">${w.conditionEmoji || '☀️'}</span>
        <span style="font-size:16px; font-weight:800; color:#ffffff;">${w.tempF}°F</span>
      </div>

      <!-- UV -->
      <div class="weather-capsule-sec">
        <div style="display:flex; align-items:center; gap:4px; font-size:13px; font-weight:800; color:#ffffff;">
          <span>☀️</span>
          <span>UV ${Math.round(w.uvIndex)}</span>
        </div>
        <div style="font-size:11px; font-weight:700; color:${uvColor};">(${uvCat})</div>
      </div>

      <!-- Wind -->
      <div class="weather-capsule-sec">
        <div style="display:flex; align-items:center; gap:4px; font-size:13px; font-weight:800; color:#ffffff;">
          <span>💨</span>
          <span>${w.windMph} mph ${windDir}</span>
        </div>
        <div style="font-size:11px; font-weight:700; color:#38bdf8;">(${windCat})</div>
      </div>
    </div>
  `;
}
window.renderWeatherLine = renderWeatherLine;

export function renderWeatherDetailsCard(game, forcedWeather) {
  const w = forcedWeather || weatherService.getCached(game.courtLocation, game.scheduledDate) || weatherService.getFallback(game.courtLocation, game.scheduledDate);
  return `
    <div class="weather-details-inner">
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
        <span style="font-size: 11px; font-weight: 800; color: #0f172a; text-transform: uppercase; letter-spacing: 0.5px;">
          🏖️ Beach Volleyball Conditions • ${game.courtLocation}
        </span>
        <button type="button" onclick="window.toggleWeatherDetails('${game.id}')" style="background:none; border:none; color:var(--text-muted); font-size:14px; cursor:pointer;" title="Close">✕</button>
      </div>
      <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; margin-bottom: 8px;">
        <div class="weather-col">
          <div class="weather-col-label">TEMP</div>
          <div class="weather-col-value">${w.conditionEmoji} ${w.tempF}°F</div>
          <div class="weather-col-sub">${w.conditionText}</div>
        </div>
        <div class="weather-col">
          <div class="weather-col-label">UV INDEX</div>
          <div class="weather-col-value" style="color: ${w.uvColor};">☀️ ${Math.round(w.uvIndex)} <span style="font-size:10px;">(${w.uvCategory})</span></div>
          <div class="weather-col-sub">${w.uvCategory === 'Low' ? 'Low risk' : 'Sunscreen advised'}</div>
        </div>
        <div class="weather-col">
          <div class="weather-col-label">WIND</div>
          <div class="weather-col-value" style="color: #0284c7;">💨 ${w.windMph} mph</div>
          <div class="weather-col-sub">${w.windCategory}</div>
        </div>
      </div>
      <div style="font-size: 11px; color: var(--text-muted); display: flex; flex-direction: column; gap: 4px; border-top: 1px solid var(--border, #e2e8f0); padding-top: 6px;">
        <div>💨 <strong>Volleyball Setting/Passing Impact:</strong> ${w.windAdvice}</div>
        <div>☀️ <strong>Sun Exposure Guidelines:</strong> ${w.uvAdvice}</div>
      </div>
    </div>
  `;
}
window.renderWeatherDetailsCard = renderWeatherDetailsCard;

window.toggleWeatherDetails = function(gameId) {
  const card = document.getElementById(`weather-details-${gameId}`);
  if (card) {
    const isHidden = card.style.display === "none" || !card.style.display;
    card.style.display = isHidden ? "block" : "none";
  }
};

// App State
class AppState {
  constructor() {
    let savedPlayers = null;
    let savedGames = null;
    let savedSlots = null;
    let savedUserId = null;
    try {
      savedPlayers = JSON.parse(localStorage.getItem("setgames_players"));
      savedGames = JSON.parse(localStorage.getItem("setgames_games"));
      savedSlots = JSON.parse(localStorage.getItem("setgames_slots"));
      savedUserId = localStorage.getItem("setgames_current_user_id");
    } catch (e) {
      console.warn("Storage read warning:", e);
    }

    this.players = (savedPlayers && savedPlayers.length > 0) ? savedPlayers : initialCommunityPlayers;
    this.games = Array.isArray(savedGames) ? savedGames.filter(isUpcomingGame) : [];
    this.availabilitySlots = deduplicateSlots(savedSlots || []);
    this.pickupQueue = [];
    this.selectedLadderTier = "All";
    this.collapsedMatches = {};
    this.collapsedPools = {};
    this.isDemoModeEnabled = localStorage.getItem("setgames_demo_mode") === "true";
    
    // Active user session
    this.currentUser = this.players.find(p => p.id === savedUserId) || null;
    if (!isRootUser(this.currentUser)) {
      this.isDemoModeEnabled = false;
      try {
        localStorage.removeItem("setgames_demo_mode");
      } catch (e) {}
    }
  }

  saveLocal() {
    try {
      localStorage.setItem("setgames_players", JSON.stringify(this.players));
      localStorage.setItem("setgames_games", JSON.stringify(this.games));
      localStorage.setItem("setgames_slots", JSON.stringify(this.availabilitySlots));
      if (this.isDemoModeEnabled) {
        localStorage.setItem("setgames_demo_mode", "true");
      } else {
        localStorage.removeItem("setgames_demo_mode");
      }
      if (this.currentUser) {
        localStorage.setItem("setgames_current_user_id", this.currentUser.id);
      } else {
        localStorage.removeItem("setgames_current_user_id");
      }
    } catch (e) {
      console.warn("Storage save warning:", e);
    }
  }

  getPlayer(id) {
    if (!id) return { id: "", name: "Beach Player", nickname: "Player", avatarEmoji: "🏐", rating: "B", eloRating: 1500, homeBeach: "Main Beach" };
    const targetId = String(id).trim();
    const targetUUID = deterministicUUID(targetId).toUpperCase();

    // 1. Check for valid named player matching direct id or deterministic UUID
    let found = this.players.find(p => p && (p.name || p.nickname) && (
      String(p.id).toLowerCase() === targetId.toLowerCase() ||
      deterministicUUID(p.id).toUpperCase() === targetUUID ||
      (p.uuid && String(p.uuid).toUpperCase() === targetUUID)
    ));
    if (found) {
      return {
        ...found,
        name: found.name || found.nickname || "Beach Player",
        nickname: found.nickname || found.name || "Player",
        avatarEmoji: found.avatarEmoji || "🏐",
        rating: found.rating || "B"
      };
    }

    // 2. Fallback check on any player matching id
    found = this.players.find(p => p && (
      String(p.id).toLowerCase() === targetId.toLowerCase() ||
      deterministicUUID(p.id).toUpperCase() === targetUUID
    ));
    if (found && (found.name || found.nickname)) {
      return {
        ...found,
        name: found.name || found.nickname || "Beach Player",
        nickname: found.nickname || found.name || "Player",
        avatarEmoji: found.avatarEmoji || "🏐",
        rating: found.rating || "B"
      };
    }

    if (typeof targetId === "string" && targetId.startsWith("guest_")) {
      const clean = targetId.replace("guest_", "").replace(/([0-9]+)/, " $1").replace(/^./, str => str.toUpperCase());
      return { id: targetId, name: clean, nickname: clean, avatarEmoji: "🏐", rating: "B", eloRating: 1500, homeBeach: "Main Beach" };
    }
    return { id: targetId, name: "Beach Player", nickname: "Player", avatarEmoji: "🏐", rating: "B", eloRating: 1500, homeBeach: "Main Beach" };
  }
}

const state = new AppState();
window.state = state;

// Toast helper
export function showToast(message) {
  const toast = document.getElementById("toast");
  const msgEl = document.getElementById("toast-msg");
  if (!toast || !msgEl) return;
  msgEl.textContent = message;
  toast.classList.add("show");
  setTimeout(() => {
    toast.classList.remove("show");
  }, 3500);
}

// Avatar HTML Renderer
export function isSlugAvatar(avatarKey) {
  if (!avatarKey) return false;
  const s = String(avatarKey).trim().toLowerCase();
  return s === "slug" || s === "🍌" || s.includes("slug");
}

export function isMustangAvatar(avatarKey) {
  if (!avatarKey) return false;
  const s = String(avatarKey).trim().toLowerCase();
  return s === "mustang" || s === "horse" || s === "🐎";
}

export function renderAvatarContent(avatarKey) {
  if (isSlugAvatar(avatarKey)) {
    return `<img src="assets/slug.png" alt="Banana Slug" class="avatar-slug-img" style="width: 100%; height: 100%; object-fit: cover; border-radius: 50%; display: block;">`;
  }
  if (isMustangAvatar(avatarKey)) {
    return "🐎";
  }
  return `${avatarKey || "🏐"}`;
}

export function renderAvatar(avatarKey, sizeClass = "", isFlaker = false) {
  const inner = renderAvatarContent(avatarKey);
  if (isFlaker) {
    return `<div style="display:inline-flex; flex-direction:column; align-items:center; vertical-align:middle;">
      <div class="avatar ${sizeClass}">${inner}</div>
      <span style="font-size:9px; font-weight:900; color:#fff; background:#ef4444; border-radius:999px; width:13px; height:13px; display:inline-flex; align-items:center; justify-content:center; margin-top:2px; line-height:1; box-shadow:0 1px 2px rgba(0,0,0,0.25);" title="Flaker: Backed out 3 times in a row">F</span>
    </div>`;
  }
  return `<div class="avatar ${sizeClass}">${inner}</div>`;
}

// UI RENDERERS
function renderHeader() {
  const headerChip = document.getElementById("user-chip-container");
  if (!headerChip) return;
  if (state.currentUser) {
    const isFlaker = (state.currentUser.consecutiveBackouts || 0) >= 3;
    headerChip.innerHTML = `
      <div class="user-chip" id="user-chip-btn">
        ${renderAvatar(state.currentUser.avatarEmoji, "", isFlaker)}
        <span>${(state.currentUser.name || "Player").split(" ")[0]}</span>
        <span class="badge badge-tier-${String(state.currentUser.rating || 'b').toLowerCase()}">${state.currentUser.rating || 'B'}</span>
      </div>
    `;
    document.getElementById("user-chip-btn").onclick = () => switchTab("profile");
  } else {
    headerChip.innerHTML = `<button class="btn btn-primary btn-sm" id="btn-signup-header" onclick="window.showAuthModal()">Log In / Sign Up</button>`;
  }
}

export function formatStarRating(player) {
  if (!player) return "5.0";
  const penalty = ((player.consecutiveBackouts || 0) >= 3) ? 1.0 : 0.0;
  const base = (!player.starRatingCount || player.starRatingCount === 0) ? 5.0 : (player.starRatingSum / player.starRatingCount);
  return Math.max(1.0, base - penalty).toFixed(1);
}

export function isRootUser(user) {
  if (!user) return false;
  const cleaned = (user.phoneNumber || "").replace(/\D/g, "");
  return cleaned === "4087869405" || user.id === "47519EF2-207D-4C20-B9A6-BFEDA40FE581" || user.isRoot === true;
}

function resolvePlayerNames(pids, game, isHidden) {
  if (!pids || pids.length === 0) return "TBD";
  return pids.map(id => {
    if (isHidden && game) {
      const allP = [...(game.team1PlayerIds || []), ...(game.team2PlayerIds || [])];
      const idx = allP.indexOf(id);
      return `Player ${idx >= 0 ? idx + 1 : 1}`;
    }
    const p = state.getPlayer(id);
    return p ? (p.nickname || p.name) : (typeof id === 'string' && id.startsWith("guest_") ? id.replace("guest_", "") : "Player");
  }).join(" & ");
}

window.joinGamePool = (gameId) => {
  const game = state.games.find(g => g.id === gameId);
  if (!game) return;
  if (!state.currentUser) {
    window.showAuthModal();
    return;
  }
  const uid = state.currentUser.id;
  const allP = [...(game.team1PlayerIds || []), ...(game.team2PlayerIds || [])];
  if (allP.includes(uid)) {
    showToast("You are already in this game's pool!");
    return;
  }
  const maxP = game.maxPlayers || 4;
  if (allP.length >= maxP) {
    showToast("Sorry, this match is already full!");
    return;
  }

  // Private Game Check
  if (game.isPrivate && !isRootUser(state.currentUser) && game.hostPlayerId !== uid) {
    showToast("Private Game: This match is private and invite-only.");
    return;
  }

  // Level Lock Check
  const allowed = (game.allowedRatings && game.allowedRatings.length > 0) ? game.allowedRatings : [game.targetRating || "B"];
  if (game.isLevelLocked && !allowed.includes(state.currentUser.rating)) {
    showToast(`Level Locked: This match is locked to ${allowed.join(", ")} players only (Your rating: ${state.currentUser.rating}).`);
    return;
  }

  if (!game.team1PlayerIds) game.team1PlayerIds = [];
  if (!game.team2PlayerIds) game.team2PlayerIds = [];

  if (game.team1PlayerIds.length <= game.team2PlayerIds.length) {
    game.team1PlayerIds.push(uid);
  } else {
    game.team2PlayerIds.push(uid);
  }

  if ((game.team1PlayerIds.length + game.team2PlayerIds.length) >= maxP) {
    triggerWebPushNotification("🏐 Set Game Locked!", `${game.title} at ${game.courtLocation} is now fully locked!`);
  }

  saveGameToFirestore(game);
  state.saveLocal();
  renderMatches();
  trackEvent("join_game", {
    game_id: game.id,
    game_title: game.title,
    court: game.courtLocation
  });
  showToast(`Joined ${game.title}! See you on the sand.`);
};
window.joinGame = window.joinGamePool;

window.joinWaitlist = (gameId) => {
  const game = state.games.find(g => g.id === gameId);
  if (!game) return;
  if (!state.currentUser) {
    window.showAuthModal();
    return;
  }
  const uid = state.currentUser.id;
  const allP = [...(game.team1PlayerIds || []), ...(game.team2PlayerIds || [])];
  if (allP.includes(uid)) {
    showToast("You are already an active player in this game!");
    return;
  }
  if (!game.waitlistPlayerIds) game.waitlistPlayerIds = [];
  if (game.waitlistPlayerIds.includes(uid)) {
    showToast("You are already on the waiting list!");
    return;
  }

  // Private Game Check
  if (game.isPrivate && !isRootUser(state.currentUser) && game.hostPlayerId !== uid) {
    showToast("Private Game: This match is private and invite-only.");
    return;
  }

  const allowed = (game.allowedRatings && game.allowedRatings.length > 0) ? game.allowedRatings : [game.targetRating || "B"];
  if (game.isLevelLocked && !allowed.includes(state.currentUser.rating)) {
    showToast(`Level Locked: ${allowed.join(", ")} only (Your rating: ${state.currentUser.rating}).`);
    return;
  }
  game.waitlistPlayerIds.push(uid);
  saveGameToFirestore(game);
  state.saveLocal();
  renderMatches();
  showToast(`Added to waiting list (#${game.waitlistPlayerIds.length}) for ${game.title}!`);
};

window.leaveWaitlist = (gameId) => {
  const game = state.games.find(g => g.id === gameId);
  if (!game || !state.currentUser) return;
  const uid = state.currentUser.id;
  if (!game.waitlistPlayerIds) return;
  game.waitlistPlayerIds = game.waitlistPlayerIds.filter(id => id !== uid);
  saveGameToFirestore(game);
  state.saveLocal();
  renderMatches();
  showToast(`Removed from waiting list for ${game.title}.`);
};

window.promoteWaitlistPlayer = (gameId, playerId) => {
  const game = state.games.find(g => g.id === gameId);
  if (!game || !state.currentUser) return;

  const currentUserId = state.currentUser.id;
  const isHost = (game.hostPlayerId === currentUserId) || (game.team1PlayerIds && game.team1PlayerIds[0] === currentUserId) || (state.currentUser && state.currentUser.isRoot);
  if (!isHost) {
    showToast("Only the match host or admin can add waiting players.");
    return;
  }

  if (!game.waitlistPlayerIds || !game.waitlistPlayerIds.includes(playerId)) {
    showToast("Player is no longer on the waiting list.");
    return;
  }

  // Remove from waitlist
  game.waitlistPlayerIds = game.waitlistPlayerIds.filter(id => id !== playerId);

  if (!game.team1PlayerIds) game.team1PlayerIds = [];
  if (!game.team2PlayerIds) game.team2PlayerIds = [];

  const allPlayers = [...game.team1PlayerIds, ...game.team2PlayerIds];
  const maxP = game.maxPlayers || 4;
  if (allPlayers.length >= maxP) {
    game.maxPlayers = allPlayers.length + 1;
  }

  if (game.team1PlayerIds.length <= game.team2PlayerIds.length) {
    game.team1PlayerIds.push(playerId);
  } else {
    game.team2PlayerIds.push(playerId);
  }

  state.saveLocal();
  saveGameToFirestore(game);
  renderMatches();

  const promoted = state.getPlayer(playerId);
  const pName = promoted.nickname ? `${promoted.name} (${promoted.nickname})` : promoted.name;
  showToast(`Added ${pName} to the game!`);

  // Dispatch APNs push
  const token = promoted.deviceToken;
  const hostPlayer = state.getPlayer(currentUserId);
  const hostName = hostPlayer ? (hostPlayer.nickname || hostPlayer.name) : "The host";
  if (token && token !== state.currentUser?.deviceToken) {
    fetch("/api/send-push", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        tokens: [token],
        title: "🎉 Added from Waiting",
        body: `${hostName} added you to the game '${game.title || "Match"}'!`,
        gameId: game.id
      })
    }).catch(err => console.log("Push note:", err));
  }
};

window.addSpotToGame = (gameId) => {
  const game = state.games.find(g => g.id === gameId);
  if (!game || !state.currentUser) return;

  const currentUserId = state.currentUser.id;
  const isHost = (game.hostPlayerId === currentUserId) || (game.team1PlayerIds && game.team1PlayerIds[0] === currentUserId) || (state.currentUser && state.currentUser.isRoot);
  if (!isHost) {
    showToast("Only the match host or admin can add spots to this game.");
    return;
  }

  const currentTotal = (game.team1PlayerIds?.length || 0) + (game.team2PlayerIds?.length || 0);
  game.maxPlayers = Math.max(game.maxPlayers || 4, currentTotal) + 1;

  state.saveLocal();
  saveGameToFirestore(game);
  renderMatches();
  showToast(`Added an open spot to ${game.title || "Match"}!`);
};

window.removePlayerFromPool = (gameId, playerId) => {
  const game = state.games.find(g => g.id === gameId);
  if (!game || !state.currentUser) return;

  const currentUserId = state.currentUser.id;
  const isHost = game.hostPlayerId === currentUserId || (game.team1PlayerIds && game.team1PlayerIds[0] === currentUserId) || state.currentUser.isRoot;
  if (!isHost) {
    showToast("Only the match host can remove players from the pool.");
    return;
  }

  if (playerId === game.hostPlayerId) {
    showToast("Hosts cannot remove themselves from the pool.");
    return;
  }

  const p = state.getPlayer(playerId);
  const pName = p ? (p.nickname ? `${p.name} (${p.nickname})` : p.name) : "this player";

  if (!confirm(`Are you sure you want to remove ${pName} from this match?\n\nIf players are on the waitlist, the next player will be auto-promoted.`)) {
    return;
  }

  const wasInTeam1 = game.team1PlayerIds && game.team1PlayerIds.includes(playerId);
  const wasInTeam2 = game.team2PlayerIds && game.team2PlayerIds.includes(playerId);
  if (!wasInTeam1 && !wasInTeam2) return;

  game.team1PlayerIds = (game.team1PlayerIds || []).filter(id => id !== playerId);
  game.team2PlayerIds = (game.team2PlayerIds || []).filter(id => id !== playerId);

  // Auto-promote first waitlisted player into the open spot
  let promotedPlayerName = null;
  let promotedPlayer = null;
  if (!game.waitlistPlayerIds) game.waitlistPlayerIds = [];
  const currentTotal = (game.team1PlayerIds?.length || 0) + (game.team2PlayerIds?.length || 0);
  const maxP = game.maxPlayers || 4;
  if (game.waitlistPlayerIds.length > 0 && currentTotal < maxP) {
    const promotedId = game.waitlistPlayerIds.shift();
    if ((game.team1PlayerIds?.length || 0) <= (game.team2PlayerIds?.length || 0)) {
      if (!game.team1PlayerIds) game.team1PlayerIds = [];
      game.team1PlayerIds.push(promotedId);
    } else {
      if (!game.team2PlayerIds) game.team2PlayerIds = [];
      game.team2PlayerIds.push(promotedId);
    }
    promotedPlayer = state.players.find(pl => pl.id === promotedId);
    promotedPlayerName = promotedPlayer ? (promotedPlayer.nickname || promotedPlayer.name) : "A waitlisted player";
  }

  state.saveLocal();
  saveGameToFirestore(game);
  renderMatches();

  showToast(`Removed ${pName} from the match.` + (promotedPlayerName ? ` ${promotedPlayerName} was auto-promoted!` : ""));

  // Dispatch APNs push alerts
  if (p && p.deviceToken && p.deviceToken !== state.currentUser?.deviceToken) {
    fetch("/api/send-push", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        tokens: [p.deviceToken],
        title: "Volleyball Match Alert",
        body: `You were removed from '${game.title || "Match"}' by the host.`,
        gameId: game.id
      })
    }).catch(err => console.log("Push note:", err));
  }

  if (promotedPlayer && promotedPlayer.deviceToken && promotedPlayer.deviceToken !== state.currentUser?.deviceToken) {
    fetch("/api/send-push", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        tokens: [promotedPlayer.deviceToken],
        title: "🎉 You're in!",
        body: `A spot opened up in '${game.title || "Match"}' and you were promoted from the waitlist!`,
        gameId: game.id
      })
    }).catch(err => console.log("Push note:", err));
  }
};

window.toggleMatchesCollapse = (gameId) => {
  state.expandedMatches = state.expandedMatches || {};
  state.expandedMatches[gameId] = !state.expandedMatches[gameId];
  renderMatches();
};

window.togglePoolCollapse = (gameId) => {
  state.collapsedPools = state.collapsedPools || {};
  state.collapsedPools[gameId] = !state.collapsedPools[gameId];
  renderMatches();
};

function revertSubMatchStatsWeb(match, prevWinner) {
  if (match.team1Score === undefined || match.team2Score === undefined) return;
  const s1 = match.team1Score;
  const s2 = match.team2Score;
  const team1Ids = match.team1PlayerIds || [];
  const team2Ids = match.team2PlayerIds || [];

  const prevWinners = prevWinner === 1 ? team1Ids : team2Ids;
  const prevLosers = prevWinner === 1 ? team2Ids : team1Ids;
  const winPts = prevWinner === 1 ? s1 : s2;
  const losePts = prevWinner === 1 ? s2 : s1;

  prevWinners.forEach(pid => {
    const p = state.players.find(x => x.id === pid);
    if (p) {
      p.wins = Math.max(0, (p.wins || 0) - 1);
      p.eloRating = Math.max(800, (p.eloRating || 1500) - 24);
      p.pointsScored = Math.max(0, (p.pointsScored || 0) - winPts);
      p.pointsAllowed = Math.max(0, (p.pointsAllowed || 0) - losePts);
      if (p.recentForm && p.recentForm.length > 0) p.recentForm.pop();
      savePlayerToFirestore(p);
    }
  });

  prevLosers.forEach(pid => {
    const p = state.players.find(x => x.id === pid);
    if (p) {
      p.losses = Math.max(0, (p.losses || 0) - 1);
      p.eloRating = (p.eloRating || 1500) + 20;
      p.pointsScored = Math.max(0, (p.pointsScored || 0) - losePts);
      p.pointsAllowed = Math.max(0, (p.pointsAllowed || 0) - winPts);
      if (p.recentForm && p.recentForm.length > 0) p.recentForm.pop();
      savePlayerToFirestore(p);
    }
  });
}

function applySubMatchStatsWeb(match) {
  if (!match.isCompleted || match.team1Score === undefined || match.team2Score === undefined) return;
  const s1 = match.team1Score;
  const s2 = match.team2Score;
  const winningTeam = s1 > s2 ? 1 : 2;

  if (match.appliedStatsWinner === winningTeam) return;

  if (match.appliedStatsWinner && match.appliedStatsWinner !== winningTeam) {
    revertSubMatchStatsWeb(match, match.appliedStatsWinner);
  }

  const team1Ids = match.team1PlayerIds || [];
  const team2Ids = match.team2PlayerIds || [];

  const winners = winningTeam === 1 ? team1Ids : team2Ids;
  const losers = winningTeam === 1 ? team2Ids : team1Ids;
  const winnerScore = winningTeam === 1 ? s1 : s2;
  const loserScore = winningTeam === 1 ? s2 : s1;

  winners.forEach(pid => {
    const p = state.players.find(x => x.id === pid);
    if (p) {
      p.wins = (p.wins || 0) + 1;
      p.streak = (p.streak && p.streak > 0) ? p.streak + 1 : 1;
      p.eloRating = (p.eloRating || 1500) + 24;
      p.pointsScored = (p.pointsScored || 0) + winnerScore;
      p.pointsAllowed = (p.pointsAllowed || 0) + loserScore;
      p.recentForm = p.recentForm || [];
      p.recentForm.push(true);
      if (p.recentForm.length > 5) p.recentForm.shift();
      p.consecutiveBackouts = 0;
      savePlayerToFirestore(p);
    }
  });

  losers.forEach(pid => {
    const p = state.players.find(x => x.id === pid);
    if (p) {
      p.losses = (p.losses || 0) + 1;
      p.streak = (p.streak && p.streak < 0) ? p.streak - 1 : -1;
      p.eloRating = Math.max(800, (p.eloRating || 1500) - 20);
      p.pointsScored = (p.pointsScored || 0) + loserScore;
      p.pointsAllowed = (p.pointsAllowed || 0) + winnerScore;
      p.recentForm = p.recentForm || [];
      p.recentForm.push(false);
      if (p.recentForm.length > 5) p.recentForm.shift();
      p.consecutiveBackouts = 0;
      savePlayerToFirestore(p);
    }
  });

  match.appliedStatsWinner = winningTeam;

  if (state.currentUser && (winners.includes(state.currentUser.id) || losers.includes(state.currentUser.id))) {
    const updated = state.players.find(x => x.id === state.currentUser.id);
    if (updated) state.currentUser = updated;
  }
}

window.updateSubMatchScoreWeb = (gameId, matchId) => {
  const game = state.games.find(g => g.id === gameId);
  if (!game || !game.subMatches) return;
  const match = game.subMatches.find(m => (m.id === matchId || String(game.subMatches.indexOf(m)) === String(matchId)));
  if (!match) return;

  const s1Val = document.getElementById(`sub-s1-${gameId}-${matchId}`)?.value.trim();
  const s2Val = document.getElementById(`sub-s2-${gameId}-${matchId}`)?.value.trim();
  if (s1Val !== "" && s2Val !== "" && s1Val !== undefined && s2Val !== undefined) {
    const s1 = parseInt(s1Val);
    const s2 = parseInt(s2Val);
    if (!isNaN(s1) && !isNaN(s2)) {
      match.team1Score = s1;
      match.team2Score = s2;
      match.isCompleted = true;
      match.winningTeam = s1 > s2 ? 1 : 2;

      applySubMatchStatsWeb(match);

      if (game.subMatches.every(m => m.isCompleted)) {
        game.status = "completed";
      }
      saveGameToFirestore(game);
      state.saveLocal();
      renderMatches();
      renderLadder();
      renderHeader();
      renderProfile();
      showToast(`Saved score for Match ${match.matchNumber}! Stats updated.`);
    }
  }
};

let currentMatchFilter = "all"; // 'all', 'myGames', 'openSpots'
window.setMatchFilter = (filter) => {
  currentMatchFilter = filter;
  document.querySelectorAll(".match-filter-chip").forEach(el => {
    el.classList.toggle("active", el.dataset.filter === filter);
  });
  renderMatches();
};

function renderMatches() {
  const container = document.getElementById("matches-list");
  if (!container) return;

  if (!state.currentUser) {
    container.innerHTML = `
      <div style="text-align: center; padding: 50px 20px; background: var(--card-bg, #ffffff); border-radius: 16px; border: 1px solid var(--border, #e2e8f0); margin: 20px 0;">
        <div style="font-size: 48px; margin-bottom: 12px;">🔒</div>
        <h3 style="font-size: 19px; font-weight: 800; color: #0f172a; margin-bottom: 8px;">Log In to Access Set Games</h3>
        <p style="font-size: 13px; color: var(--text-muted); margin-bottom: 20px; max-width: 320px; margin-left: auto; margin-right: auto;">
          Only authenticated community members can view scheduled matches, team rosters, and court details.
        </p>
        <button class="btn btn-primary" onclick="window.showAuthModal()" style="padding: 10px 24px; font-weight: 700; border-radius: 10px;">Log In / Sign Up</button>
        <div style="margin-top: 14px;">
          <button class="btn btn-outline btn-sm" onclick="window.switchTab('ladders')">🏆 View Beach Ladders</button>
        </div>
      </div>
    `;
    return;
  }

  const currentUserId = state.currentUser?.id;
  checkUpcomingMatchReminders();

  // 1. Determine games for current view filter
  const isCompletedFilter = currentMatchFilter === "completed" || currentMatchFilter === "pastGames";
  let targetGames;
  if (isCompletedFilter) {
    targetGames = state.games.filter(g => {
      const s = String(g.status || "").trim().toLowerCase();
      return s === "completed" || parseGameDate(g.scheduledDate) < new Date();
    }).sort((a, b) => parseGameDate(b.scheduledDate).getTime() - parseGameDate(a.scheduledDate).getTime());
  } else {
    targetGames = state.games.filter(isUpcomingGame)
      .sort((a, b) => parseGameDate(a.scheduledDate).getTime() - parseGameDate(b.scheduledDate).getTime());
  }

  const canJoin = (game) => {
    const allP = [...(game.team1PlayerIds || []), ...(game.team2PlayerIds || [])];
    const maxP = game.maxPlayers || 4;
    const hasOpenSpots = allP.length < maxP;
    if (!hasOpenSpots) return false;
    if (game.isPrivate) return false;
    if (!state.currentUser) return true;
    if (game.team1PlayerIds?.includes(state.currentUser.id) || game.team2PlayerIds?.includes(state.currentUser.id)) {
      return false; // already in match
    }
    const allowed = (game.allowedRatings && game.allowedRatings.length > 0) ? game.allowedRatings : [game.targetRating || "B"];
    if (game.isLevelLocked && !allowed.includes(state.currentUser.rating)) {
      return false;
    }
    return true;
  };

  // 2. Apply selected view filter ('all', 'myGames', 'pastGames')
  let displayGames = targetGames.filter(game => {
    if (isCompletedFilter) return true;
    const isMember = currentUserId && (
      game.team1PlayerIds?.includes(currentUserId) ||
      game.team2PlayerIds?.includes(currentUserId) ||
      game.hostPlayerId === currentUserId
    );
    if (currentMatchFilter === "myGames" || currentMatchFilter === "myMatches") {
      return isMember;
    } else if (currentMatchFilter === "openSpots") {
      return canJoin(game);
    }
    return true;
  });

  if (displayGames.length === 0) {
    const emptyMsg = isCompletedFilter ?
      "No past completed games found." :
      (currentMatchFilter === "myGames" || currentMatchFilter === "myMatches") ?
      `You are not registered in any upcoming games.<br><button type="button" class="btn btn-primary btn-sm" style="margin-top:12px;" onclick="window.setMatchFilter('all')">📅 View All Upcoming Games (${targetGames.length})</button>` :
      `No upcoming games available.<br><button type="button" class="btn btn-primary btn-sm" style="margin-top:12px;" onclick="window.openCreateMatchModal()">+ Host a Game</button>`;
    container.innerHTML = `<div style="text-align:center; padding: 40px 16px; color: var(--text-muted);">${emptyMsg}</div>`;
    return;
  }

  const cardsHtml = displayGames.map((game, index) => {
    try {
    const allPlayerIds = [...(game.team1PlayerIds || []), ...(game.team2PlayerIds || [])];
    const maxPlayers = game.maxPlayers || 4;
    const spotsLeft = Math.max(0, maxPlayers - allPlayerIds.length);
    const needsPlayers = spotsLeft > 0;
    const isMember = currentUserId && (
      isPlayerInList(allPlayerIds, currentUserId) ||
      isSamePlayer(game.hostPlayerId, currentUserId)
    );
    const isRoot = isRootUser(state.currentUser);
    const isHost = currentUserId && (
      isSamePlayer(game.hostPlayerId, currentUserId) ||
      isSamePlayer(game.team1PlayerIds?.[0], currentUserId) ||
      isRoot
    );
    const hostPlayer = game.hostPlayerId ? state.getPlayer(game.hostPlayerId) : (game.team1PlayerIds?.[0] ? state.getPlayer(game.team1PlayerIds[0]) : null);

    const d = parseGameDate(game.scheduledDate);
    const scheduleFormatted = d.toLocaleDateString("en-US", {
      weekday: "short",
      month: "short",
      day: "numeric"
    }) + " • " + d.toLocaleTimeString("en-US", {
      hour: "numeric",
      minute: "2-digit"
    });
    const dateStr = d.toLocaleDateString("en-US", {
      weekday: "short",
      month: "short",
      day: "numeric"
    }) + " at " + d.toLocaleTimeString("en-US", {
      hour: "numeric",
      minute: "2-digit"
    });
    const courtClean = game.courtNumber ? (game.courtNumber.includes("#") ? game.courtNumber : "#" + (game.courtNumber.replace(/[^0-9]/g, '') || '1')) : "#1";
    const courtDisplay = courtClean.startsWith("#") ? `Court ${courtClean}` : courtClean;

    const pCount = game.maxPlayers || 4;
    const formatLabel = pCount === 2 ? "1v1" : pCount === 6 ? "3v3" : "2v2";

    const allowedList = (game.allowedRatings && game.allowedRatings.length > 0) ? game.allowedRatings : [game.targetRating || "B"];
    const skillStr = allowedList.length >= 6 ? "All Levels" : allowedList.join("/");

    const hostDisplayName = hostPlayer ? (hostPlayer.nickname || hostPlayer.name || "Host") : "Host";
    const hostStarVal = hostPlayer ? formatStarRating(hostPlayer) : "5.0";

    const t1Ids = (game.team1PlayerIds && game.team1PlayerIds.length > 0) ? game.team1PlayerIds : allPlayerIds.slice(0, 2);
    const t2Ids = (game.team2PlayerIds && game.team2PlayerIds.length > 0) ? game.team2PlayerIds : allPlayerIds.slice(2);

    const renderSlot = (pid, isTeam1) => {
      if (pid) {
        const p = state.getPlayer(pid);
        const isHidden = !isMember && !isRoot;
        const validName = p ? (p.nickname || p.name || 'Player') : (typeof pid === 'string' && pid.startsWith("guest_") ? pid.replace("guest_", "") : "Player");
        const displayName = isHidden ? 'Player' : validName;
        const avatarDisplay = isHidden ? renderAvatarContent('🏐') : renderAvatarContent(p ? p.avatarEmoji : '🏐');
        const tierVal = (p?.rating || 'B');
        const tierClass = String(tierVal).toLowerCase() === 'intermediate' ? 'badge-tier-intermediate' : `badge-tier-${String(tierVal).toLowerCase()}`;
        const starVal = p ? formatStarRating(p) : "5.0";
        const teamClass = isTeam1 ? 'player-tile-team1' : 'player-tile-team2';

        const canRemove = isHost && !isSamePlayer(pid, game.hostPlayerId);
        const removeBtnHtml = canRemove ? `
          <button type="button" class="player-tile-trash" title="Remove player from match" onclick="event.stopPropagation(); window.removePlayerFromPool('${game.id}', '${pid}')">🗑️</button>
        ` : '';

        return `
          <div class="player-tile-dark ${teamClass}">
            <div class="player-tile-avatar">${avatarDisplay}</div>
            <div class="player-tile-info">
              <div class="player-tile-name">${displayName}</div>
              <div style="display:flex; align-items:center; gap:5px;">
                <span class="badge-tier-pill ${tierClass}">${tierVal}</span>
                <span style="font-size:11px; font-weight:700; color:#fbbf24;">⭐ ${starVal}</span>
              </div>
            </div>
            ${removeBtnHtml}
          </div>
        `;
      } else {
        const emptyClass = isTeam1 ? 'player-tile-empty-t1' : 'player-tile-empty-t2';
        const canJoin = needsPlayers && !isMember && !game.isPrivate;
        const joinAttr = canJoin ? `onclick="window.joinGamePool('${game.id}')"` : '';
        return `
          <div class="player-tile-dark ${emptyClass}" ${joinAttr}>
            <span>+ Open Spot</span>
          </div>
        `;
      }
    };

    const waitlistIds = game.waitlistPlayerIds || [];
    const isWaitlisted = currentUserId && isPlayerInList(waitlistIds, currentUserId);
    const waitlistPos = isWaitlisted ? (waitlistIds.findIndex(id => isSamePlayer(id, currentUserId)) + 1) : null;

    const isMatchesCollapsed = !(state.expandedMatches && state.expandedMatches[game.id]);
    const isPoolCollapsed = !!(state.collapsedPools && state.collapsedPools[game.id]);
    const msgCount = game.messages ? game.messages.length : 0;

    return `
      ${index > 0 ? '<div class="games-white-gap"></div>' : ''}
      <div class="game-details-card" id="match-card-${game.id}">
        <!-- Header Row: Date/Time + Dropdown Ellipsis -->
        <div class="card-header-row">
          <div class="card-date-title" onclick="window.showGameDetailsModal('${game.id}')">
            <span>🗓️</span>
            <span>${scheduleFormatted}</span>
          </div>
          <div style="position: relative;">
            <button type="button" class="card-more-btn" onclick="event.stopPropagation(); window.toggleCardActionsMenu('${game.id}', event)" title="More options">
              •••
            </button>
            <div id="card-menu-${game.id}" class="card-dropdown-menu" style="display: none;">
              <button type="button" class="card-dropdown-item" onclick="window.openEditMatchModal('${game.id}')">
                <span>✏️</span> Edit Details
              </button>
              ${(isHost || isRoot) && spotsLeft === 0 ? `
                <button type="button" class="card-dropdown-item" style="color: #38bdf8;" onclick="window.addSpotToGame('${game.id}')">
                  <span>➕</span> + Add Spot to Full Game
                </button>
              ` : ''}
              ${(isHost || isRoot) ? `
                <button type="button" class="card-dropdown-item" style="color: #ef4444;" onclick="window.deleteGame('${game.id}')">
                  <span>🗑️</span> Cancel Game
                </button>
              ` : ''}
              <button type="button" class="card-dropdown-item" onclick="window.openGameQRCodeModal('${game.id}')">
                <span>🔲</span> View QR Code
              </button>
            </div>
          </div>
        </div>

        <!-- Metadata Lines -->
        <div class="card-metadata-lines" onclick="window.showGameDetailsModal('${game.id}')">
          <div class="card-metadata-line-item">
            <span>📍</span>
            <span>${game.courtLocation} - ${courtDisplay}</span>
          </div>
          <div class="card-metadata-line-item">
            <span>${formatLabel} Skill: ${skillStr}</span>
            ${game.isLevelLocked ? `<span style="font-size:10px; font-weight:700; background:rgba(234,88,12,0.2); color:#fb923c; padding:2px 6px; border-radius:4px;">🔒 Locked</span>` : ''}
          </div>
          <div class="card-metadata-line-item">
            <span>Host: ${hostDisplayName}</span>
            <span style="color:#fbbf24; font-size:13px; font-weight:700;">⭐ ${hostStarVal}</span>
            ${game.isPrivate ? `<span style="color: rgba(255, 255, 255, 0.85); display: inline-flex; align-items: center; gap: 4px;">🔒 Private Games</span>` : ''}
          </div>
        </div>

        <!-- Weather Forecast Capsule (3-column pill) -->
        <div id="weather-line-${game.id}">
          ${renderWeatherLine(game)}
        </div>

        <!-- Collapsible Beach Volleyball Conditions Card -->
        <div id="weather-details-${game.id}" class="weather-conditions-card" style="display: none;">
          ${renderWeatherDetailsCard(game)}
        </div>

        <!-- Player Pool: List with Count (if > 4 players) OR 2x2 Grid (if <= 4 players) -->
        ${allPlayerIds.length > 4 ? `
          <div class="player-pool-list-container">
            <div class="player-pool-list-header" style="cursor: pointer; user-select: none;" onclick="window.togglePlayerPoolCollapse('${game.id}', event)">
              <span class="player-pool-list-title">
                <span>👥</span> PLAYER POOL (${allPlayerIds.length} PLAYERS)
              </span>
              <div style="display: flex; align-items: center; gap: 6px;">
                <span class="player-pool-list-badge" style="color: ${spotsLeft > 0 ? '#fb923c' : '#4ade80'};">
                  ${spotsLeft > 0 ? `${spotsLeft} Spot${spotsLeft > 1 ? 's' : ''} Open` : 'Pool Full ✓'}
                </span>
                <span style="font-size: 11px; color: rgba(255, 255, 255, 0.7); font-weight: bold;">${isPoolCollapsed ? '⌵' : '⌃'}</span>
              </div>
            </div>

            ${!isPoolCollapsed ? `
              <div class="player-pool-list-items">
                ${allPlayerIds.map((pid, idx) => {
                  const p = state.getPlayer(pid);
                  const isHidden = !isMember && !isRoot;
                  const validName = p ? (p.nickname || p.name || 'Player') : (typeof pid === 'string' && pid.startsWith("guest_") ? pid.replace("guest_", "") : "Player");
                  const displayName = isHidden ? 'Player' : validName;
                  const avatarDisplay = isHidden ? renderAvatarContent('🏐') : renderAvatarContent(p ? p.avatarEmoji : '🏐');
                  const tierVal = (p?.rating || 'B');
                  const tierClass = String(tierVal).toLowerCase() === 'intermediate' ? 'badge-tier-intermediate' : `badge-tier-${String(tierVal).toLowerCase()}`;
                  const starVal = p ? formatStarRating(p) : "5.0";
                  const isGameHost = isSamePlayer(pid, game.hostPlayerId);
                  const canRemove = isHost && !isGameHost;

                  return `
                    <div class="player-pool-list-row">
                      <div style="display: flex; align-items: center; gap: 8px; min-width: 0;">
                        <span style="font-size: 10px; font-weight: 800; background: rgba(56, 189, 248, 0.18); color: #38bdf8; width: 22px; height: 22px; border-radius: 50%; display: flex; align-items: center; justify-content: center; flex-shrink: 0;">
                          #${idx + 1}
                        </span>
                        <div style="width: 28px; height: 28px; border-radius: 50%; background: #fff; display: flex; align-items: center; justify-content: center; font-size: 16px; flex-shrink: 0;">
                          ${avatarDisplay}
                        </div>
                        <div style="min-width: 0;">
                          <div style="font-size: 12px; font-weight: 700; color: #ffffff; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; display: flex; align-items: center; gap: 4px;">
                            <span>${displayName}</span>
                            ${isGameHost ? `<span style="font-size: 8px; font-weight: 800; background: rgba(251, 191, 36, 0.2); color: #fbbf24; padding: 1px 4px; border-radius: 3px;">HOST</span>` : ''}
                          </div>
                          <div style="display: flex; align-items: center; gap: 5px; margin-top: 1px;">
                            <span class="badge-tier-pill ${tierClass}" style="font-size: 9px; padding: 1px 5px;">${tierVal}</span>
                            <span style="font-size: 10px; font-weight: 700; color: #fbbf24;">⭐ ${starVal}</span>
                          </div>
                        </div>
                      </div>
                      ${canRemove ? `
                        <button type="button" class="player-tile-trash" title="Remove player from match" style="margin-left: 8px; flex-shrink: 0;" onclick="event.stopPropagation(); window.removePlayerFromPool('${game.id}', '${pid}')">🗑️</button>
                      ` : ''}
                    </div>
                  `;
                }).join("")}

                ${spotsLeft > 0 ? `
                  <div class="player-tile-dark player-tile-empty-t1" style="min-height: 38px; padding: 6px 10px; cursor: pointer; display: flex; align-items: center; justify-content: center;" onclick="${needsPlayers && !isMember && !game.isPrivate ? `window.joinGamePool('${game.id}')` : ''}">
                    <span style="font-size: 11px; font-weight: 700; color: #38bdf8;">+ Open Spot (${spotsLeft} remaining)</span>
                  </div>
                ` : ''}
              </div>
            ` : ''}
          </div>
        ` : `
          <!-- 2x2 Player Spot Grid: Team 1 (Row 1 Cyan) / Team 2 (Row 2 Coral) -->
          <div class="player-grid-2x2">
            ${renderSlot(t1Ids[0], true)}
            ${renderSlot(t1Ids[1], true)}
            ${renderSlot(t2Ids[0], false)}
            ${renderSlot(t2Ids[1], false)}
          </div>
        `}

        <!-- Waiting Section (if pool full or waitlist has players) -->
        ${(spotsLeft === 0 || waitlistIds.length > 0) ? `
          <div style="margin-top: -6px; margin-bottom: 14px; padding: 10px 12px; background: rgba(147, 51, 234, 0.08); border: 1px dashed rgba(168, 85, 247, 0.4); border-radius: 12px;">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
              <span style="font-size: 11px; font-weight: 800; color: #c084fc; text-transform: uppercase; letter-spacing: 0.5px;">
                ⏳ WAITING (${waitlistIds.length} Queued)
              </span>
              <span style="font-size: 10px; color: rgba(255, 255, 255, 0.6);">Host or Admin can add to game</span>
            </div>

            ${spotsLeft === 0 && !isMember ? (
              game.isPrivate ? `
                <div style="background: rgba(255, 255, 255, 0.05); color: rgba(255, 255, 255, 0.6); border: 1px dashed rgba(255, 255, 255, 0.15); font-weight: 700; width: 100%; margin-bottom: 8px; padding: 8px 12px; border-radius: 8px; font-size: 12px; text-align: center;">
                  🔒 Private Game • Invite Only
                </div>
              ` : (
                isWaitlisted ? `
                  <div style="background: rgba(168, 85, 247, 0.12); border: 1px solid rgba(168, 85, 247, 0.3); border-radius: 8px; padding: 8px 12px; margin-bottom: 8px; display: flex; justify-content: space-between; align-items: center;">
                    <div style="font-size: 12px; font-weight: 700; color: #d8b4fe;">
                      ⏳ You are #${waitlistPos} on Waiting List
                    </div>
                    <button type="button" class="btn btn-outline btn-sm" style="color: #f87171; border-color: #f87171; padding: 2px 8px; font-size: 11px;" onclick="window.leaveWaitlist('${game.id}')">
                      Leave Waiting
                    </button>
                  </div>
                ` : `
                  <button type="button" class="btn btn-sm" style="background: rgba(168, 85, 247, 0.2); color: #d8b4fe; border: 1px dashed #a855f7; font-weight: 700; width: 100%; margin-bottom: 8px; padding: 8px 12px; border-radius: 8px; font-size: 12px; cursor: pointer;" onclick="window.joinWaitlist('${game.id}')">
                    ⏳ Full Game • Join Waiting List (${waitlistIds.length} queued)
                  </button>
                `
              )
            ) : ''}

            ${waitlistIds.length === 0 ? `
              <div style="padding: 8px 10px; background: rgba(0, 0, 0, 0.2); border-radius: 6px; font-size: 11px; color: rgba(255, 255, 255, 0.6);">
                No players currently waiting. Next signups will queue here in order.
              </div>
            ` : `
              <div style="display: flex; flex-direction: column; gap: 6px;">
                ${waitlistIds.map((pid, idx) => {
                  const p = state.getPlayer(pid);
                  const isHidden = !isMember && !isRoot;
                  const validName = p ? (p.nickname || p.name || `Player ${idx + 1}`) : `Player ${idx + 1}`;
                  const pName = isHidden ? `Player ${idx + 1}` : validName;
                  const isMe = isSamePlayer(currentUserId, pid);
                  return `
                    <div style="display: flex; align-items: center; justify-content: space-between; background: #12151f; border: 1px solid rgba(255, 255, 255, 0.08); border-radius: 8px; padding: 6px 10px;">
                      <div style="display: flex; align-items: center; gap: 8px;">
                        <span style="font-size: 11px; font-weight: 800; background: #a855f7; color: #fff; width: 20px; height: 20px; border-radius: 50%; display: flex; align-items: center; justify-content: center;">#${idx + 1}</span>
                        <div>
                          <div style="font-size: 12px; font-weight: 700; color: #ffffff;">${pName}</div>
                          <div style="font-size: 10px; color: rgba(255, 255, 255, 0.6);">Level: ${(p && p.rating) ? p.rating : 'Unrated'}</div>
                        </div>
                      </div>
                      <div style="display: flex; align-items: center; gap: 6px;">
                        ${(isHost || isRoot) ? `
                          <button type="button" class="btn btn-sm" style="background: #10b981; color: white; border: none; font-weight: 700; padding: 4px 10px; font-size: 11px; border-radius: 6px; cursor: pointer; display: inline-flex; align-items: center; gap: 4px;" onclick="window.promoteWaitlistPlayer('${game.id}', '${pid}')">
                            <span>➕</span> Add to Game
                          </button>
                        ` : ''}
                        ${isMe ? `
                          <button type="button" class="btn btn-outline btn-sm" style="color: #f87171; border-color: #f87171; padding: 2px 8px; font-size: 11px;" onclick="window.leaveWaitlist('${game.id}')">Leave</button>
                        ` : ''}
                      </div>
                    </div>
                  `;
                }).join("")}
              </div>
            `}
          </div>
        ` : ''}

        <!-- Collapsible Matches in this Game Section -->
        <div style="margin-bottom: 12px;">
          <div 
            onclick="window.toggleMatchesCollapse('${game.id}')"
            class="matches-title-row"
          >
            <span style="display: flex; align-items: center; gap: 6px;">
              🥎 MATCHES IN THIS GAME (${(game.subMatches || []).length})
            </span>
            <span style="font-size: 14px;">${isMatchesCollapsed ? '⌄' : '⌃'}</span>
          </div>

          <div onclick="window.toggleMatchesCollapse('${game.id}')" class="matches-schedule-pill">
            <div style="display: flex; align-items: center; gap: 8px;">
              <span>🏐</span>
              <span>Match Schedule (${(game.subMatches || []).length})</span>
            </div>
            <div style="display: flex; align-items: center; gap: 6px; color: rgba(255,255,255,0.6);">
              ${(game.subMatches || []).length > 0 ? `<span>🏐</span><span>🏐</span>` : ''}
              <span style="font-size: 13px;">${isMatchesCollapsed ? '⌄' : '⌃'}</span>
            </div>
          </div>

          ${!isMatchesCollapsed ? `
            ${(!game.subMatches || game.subMatches.length === 0) ? `
              <div style="display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 14px; background: #1e1915; border: 1px dashed rgba(249, 115, 22, 0.4); border-radius: 10px; margin-bottom: 10px; text-align: center;">
                <div style="font-size: 12px; font-weight: 800; color: #fdba74; margin-bottom: 2px;">No matches generated yet</div>
                <div style="font-size: 11px; color: #fb923c; margin-bottom: 10px;">Generate fair team rotations and schedules automatically for players in this game.</div>
                <button type="button" class="btn btn-primary btn-sm" style="background: #ea580c; border-color: #ea580c; font-size: 12px; font-weight: 800; padding: 6px 14px; border-radius: 8px;" onclick="window.openRandomTeamsModalForGame('${game.id}')">
                  🎲 Generate Matches (${allPlayerIds.length} Players)
                </button>
              </div>
            ` : `
              <div style="display: flex; flex-direction: column; gap: 8px; margin-bottom: 10px;">
                ${game.subMatches.map((m, mIdx) => {
                  const s1Val = (m.team1Score !== undefined && m.team1Score !== null) ? m.team1Score : "";
                  const s2Val = (m.team2Score !== undefined && m.team2Score !== null) ? m.team2Score : "";
                  const mKey = m.id || mIdx;
                  return `
                    <div style="background: #11151f; border: 1px solid rgba(255,255,255,0.08); border-radius: 10px; padding: 10px 12px;">
                      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px;">
                        <span style="font-size: 11px; font-weight: 800; color: #38bdf8;">MATCH ${m.matchNumber || mIdx + 1} • ${m.courtNumber || "Court #1"}</span>
                        ${m.isCompleted ? '<span style="font-size: 10px; color: #22c55e; font-weight: 800;">SCORED ✓</span>' : '<span style="font-size: 10px; color: rgba(255,255,255,0.5);">Scheduled</span>'}
                      </div>
                      <div style="display: flex; justify-content: space-between; align-items: center; font-weight: 700; font-size: 13px; margin-bottom: 6px; color: #ffffff;">
                        <div style="flex: 1; text-align: left;">${resolvePlayerNames(m.team1PlayerIds, game, !isMember && !isRoot)}</div>
                        <span style="color: rgba(255,255,255,0.4); font-size: 11px; font-weight: 900; padding: 0 8px;">VS</span>
                        <div style="flex: 1; text-align: right;">${resolvePlayerNames(m.team2PlayerIds, game, !isMember && !isRoot)}</div>
                      </div>
                      ${m.restingPlayerIds && m.restingPlayerIds.length > 0 ? `
                        <div style="font-size: 10px; color: rgba(255,255,255,0.5); margin-bottom: 6px;">
                          ⏸ Resting: ${resolvePlayerNames(m.restingPlayerIds, game, !isMember && !isRoot)}
                        </div>
                      ` : ''}
                      <div style="display: flex; align-items: center; gap: 6px; padding-top: 4px; border-top: 1px solid rgba(255,255,255,0.06);">
                        <span style="font-size: 11px; font-weight: 700; color: rgba(255,255,255,0.6);">Score:</span>
                        <input type="number" id="sub-s1-${game.id}-${mKey}" class="form-input" style="width: 52px; padding: 3px 6px; font-size: 12px; font-weight: 700; text-align: center; background:#1e2433; color:#fff; border-color:rgba(255,255,255,0.15);" placeholder="T1" value="${s1Val}">
                        <span>–</span>
                        <input type="number" id="sub-s2-${game.id}-${mKey}" class="form-input" style="width: 52px; padding: 3px 6px; font-size: 12px; font-weight: 700; text-align: center; background:#1e2433; color:#fff; border-color:rgba(255,255,255,0.15);" placeholder="T2" value="${s2Val}">
                        <button type="button" class="btn btn-sm btn-outline" style="font-size: 11px; padding: 2px 8px; margin-left: 6px; color:#38bdf8; border-color:#38bdf8;" onclick="window.updateSubMatchScoreWeb('${game.id}', '${mKey}')">
                          Save
                        </button>
                        <span style="font-size: 11px; color: #22c55e; font-weight: 700; margin-left: auto;">
                          ${m.isCompleted && m.winningTeam ? '(Team ' + m.winningTeam + ' Won)' : ''}
                        </span>
                      </div>
                    </div>
                  `;
                }).join("")}
                <div style="display: flex; justify-content: flex-end; margin-top: 4px;">
                  <button type="button" class="btn btn-outline btn-sm" style="font-size: 11px; color: #ea580c; border-color: #fdba74;" onclick="window.openRandomTeamsModalForGame('${game.id}')">
                    🎲 Regenerate / Adjust Matches
                  </button>
                </div>
              </div>
            `}
          ` : ''}
        </div>

        <!-- Card Footer -->
        <div class="card-footer-dark">
          <!-- Top Row: Time & Admin Actions Dropdown Trigger -->
          <div class="card-footer-top-row">
            <div style="display: flex; align-items: center; gap: 6px;">
              <span>🕒</span>
              <span>${dateStr}</span>
            </div>
            <div class="card-footer-admin-trigger" onclick="window.toggleCardAdminMenu('${game.id}')">
              ADMIN ACTIONS • SETTINGS ▾
            </div>
          </div>

          <!-- Bottom Row: Action Buttons -->
          <div class="card-footer-actions-row">
            <!-- Left Group -->
            <div style="display: flex; align-items: center; gap: 8px;">
              <!-- Button 1: QR Code -->
              <button type="button" class="card-btn-white" onclick="window.openGameQRCodeModal('${game.id}')" title="Scan QR Code">
                <span style="font-size: 16px;">📱</span>
                <span style="font-size: 10px; font-weight: 700; margin-top: 2px; line-height: 1.1; text-align: center;">QR<br>Code</span>
              </button>

              <!-- Button 2: Chat -->
              ${isMember ? `
                <button type="button" class="card-btn-blue" onclick="window.openMatchChatModal('${game.id}')" title="Match Chat">
                  <span style="font-size: 16px;">💬</span>
                  <span style="font-size: 10px; font-weight: 700; margin-top: 2px; line-height: 1.1; text-align: center;">Chat<br>(${msgCount})</span>
                  ${msgCount > 0 ? `<span class="card-unread-badge">${msgCount}</span>` : ''}
                </button>
              ` : ''}

              <!-- Button 3: Leave / Join / Waiting -->
              ${isMember ? `
                <button type="button" class="card-btn-danger" onclick="window.leaveGame('${game.id}')" title="Leave Match">
                  <span style="font-size: 11px; font-weight: 800; line-height: 1.1; text-align: center;">Leave<br>Game</span>
                </button>
              ` : (
                isWaitlisted ? `
                  <button type="button" class="card-btn-white" style="background: #f3e8ff; border: 1.5px solid #d8b4fe; color: #7e22ce;" onclick="window.leaveWaitlist('${game.id}')" title="Leave Waiting List">
                    <span style="font-size: 14px;">⏳</span>
                    <span style="font-size: 10px; font-weight: 800; line-height: 1.1; text-align: center;">Waiting<br>#${waitlistPos}</span>
                  </button>
                ` : (
                  game.isPrivate ? `
                    <div style="background: rgba(255,255,255,0.06); border: 1.5px solid rgba(255,255,255,0.1); border-radius: 12px; min-width: 54px; height: 54px; padding: 0 8px; display: flex; flex-direction: column; align-items: center; justify-content: center; color: rgba(255,255,255,0.5);" title="Private Game • Invite Only">
                      <span style="font-size: 14px;">🔒</span>
                      <span style="font-size: 9px; font-weight: 800; margin-top: 2px; line-height: 1.1; text-align: center;">Private<br>Game</span>
                    </div>
                  ` : (
                    needsPlayers ? `
                      <button type="button" class="card-btn-white" style="background: #dcfce7; border: 1.5px solid #86efac; color: #166534;" onclick="window.joinGamePool('${game.id}')" title="Join Match">
                        <span style="font-size: 16px;">🏐</span>
                        <span style="font-size: 10px; font-weight: 800; margin-top: 2px; line-height: 1.1; text-align: center;">Join<br>Game</span>
                      </button>
                    ` : `
                      <button type="button" class="card-btn-white" style="background: #f3e8ff; border: 1.5px solid #d8b4fe; color: #7e22ce;" onclick="window.joinWaitlist('${game.id}')" title="Join Waiting List">
                        <span style="font-size: 14px;">⏳</span>
                        <span style="font-size: 11px; font-weight: 800; margin-top: 2px; line-height: 1.1; text-align: center;">Waiting</span>
                      </button>
                    `
                  )
                )
              )}
            </div>

            <!-- Right Group -->
            <div style="display: flex; align-items: center; gap: 8px;">
              <!-- Button 4: Edit -->
              <button type="button" class="card-btn-white" onclick="window.openEditMatchModal('${game.id}')" title="Edit Game">
                <span style="font-size: 16px;">✏️</span>
                <span style="font-size: 10px; font-weight: 700; margin-top: 2px;">Edit</span>
              </button>

              <!-- Button 5: Cancel Game (Host / Root) -->
              ${(isHost || isRoot) ? `
                <button type="button" class="card-btn-danger" onclick="window.deleteGame('${game.id}')" title="Cancel Game">
                  <span style="font-size: 14px;">❌</span>
                  <span style="font-size: 9px; font-weight: 800; line-height: 1.1; margin-top: 2px; text-align: center;">Cancel<br>Game</span>
                </button>
              ` : ''}
            </div>
          </div>
        </div>
      </div>
    `;
    } catch (cardErr) {
      console.error("Error rendering game card:", game?.id, cardErr);
      return "";
    }
  }).join("");

  container.innerHTML = cardsHtml;
}

window.renderMatches = renderMatches;

window.togglePlayerPoolCollapse = (gameId, event) => {
  if (event) event.stopPropagation();
  state.collapsedPools = state.collapsedPools || {};
  state.collapsedPools[gameId] = !state.collapsedPools[gameId];
  renderMatches();
};

window.toggleCardActionsMenu = (gameId, event) => {
  if (event) event.stopPropagation();
  const menu = document.getElementById(`card-menu-${gameId}`);
  if (!menu) return;
  const isShown = menu.style.display === "block";
  document.querySelectorAll(".card-dropdown-menu").forEach(m => m.style.display = "none");
  if (!isShown) {
    menu.style.display = "block";
  }
};

document.addEventListener("click", () => {
  document.querySelectorAll(".card-dropdown-menu").forEach(m => m.style.display = "none");
});

function renderLadder() {
  const container = document.getElementById("ladder-list");
  if (!container) return;

  const tier = state.selectedLadderTier;
  let filtered = [...state.players];
  if (tier !== "All") {
    filtered = filtered.filter(p => p.rating === tier);
  }

  // Sort by ELO, then Win Rate %, then Wins (matching iOS StatsManager.topPlayersLadder)
  filtered.sort((a, b) => {
    if (b.eloRating !== a.eloRating) return b.eloRating - a.eloRating;
    const totalA = a.wins + a.losses;
    const totalB = b.wins + b.losses;
    const rateA = totalA > 0 ? (a.wins / totalA) : 0;
    const rateB = totalB > 0 ? (b.wins / totalB) : 0;
    if (rateB !== rateA) return rateB - rateA;
    return b.wins - a.wins;
  });

  container.innerHTML = filtered.map((player, idx) => {
    const rank = idx + 1;
    const total = player.wins + player.losses;
    const pct = total > 0 ? Math.round((player.wins / total) * 100) : 0;
    const isCurrent = player.id === state.currentUser?.id;

    return `
      <div class="rank-row rank-${rank} ${isCurrent ? 'style="border-color: var(--primary); background: var(--primary-light);"' : ''}">
        <div class="rank-num">${rank === 1 ? '🥇' : rank === 2 ? '🥈' : rank === 3 ? '🥉' : '#' + rank}</div>
        ${renderAvatar(player.avatarEmoji, "lg", (player.consecutiveBackouts || 0) >= 3)}
        <div class="rank-info">
          <div class="rank-name">${player.name || "Beach Player"} ${player.nickname ? `"${player.nickname}"` : ""}</div>
          <div class="rank-sub">📍 ${player.homeBeach || "Main Beach"} • <span class="badge badge-tier-${String(player.rating || 'b').toLowerCase()}">${player.rating || "B"}</span></div>
        </div>
        <div class="rank-stats">
          <div class="rank-elo">${player.eloRating ?? 1500} ELO</div>
          <div class="rank-record">${player.wins || 0}W - ${player.losses || 0}L (${pct}%)</div>
        </div>
      </div>
    `;
  }).join("");
}

function renderPopularKids() {
  const container = document.getElementById("popular-list");
  if (!container) return;

  const sorted = [...state.players].sort((a, b) => {
    const connA = getUniqueConnectionsCount(a);
    const connB = getUniqueConnectionsCount(b);
    if (connB !== connA) return connB - connA;
    const matchesA = (a.wins || 0) + (a.losses || 0);
    const matchesB = (b.wins || 0) + (b.losses || 0);
    return matchesB - matchesA;
  });

  container.innerHTML = sorted.map((player, idx) => {
    const rank = idx + 1;
    const connections = getUniqueConnectionsCount(player);
    const isCurrent = player.id === state.currentUser?.id;
    const badgeTitle = getPopularKidsTitle(connections);

    return `
      <div class="rank-row ${isCurrent ? 'style="border-color: var(--accent); background: var(--accent-light);"' : ''}">
        <div class="rank-num">${rank === 1 ? '👑' : '#' + rank}</div>
        ${renderAvatar(player.avatarEmoji, "lg", (player.consecutiveBackouts || 0) >= 3)}
        <div class="rank-info">
          <div class="rank-name">${player.name}</div>
          <div class="rank-sub">${player.uniquePartnerIds?.length || 0} Partners • ${player.uniqueOpponentIds?.length || 0} Opponents</div>
        </div>
        <div class="rank-stats">
          <div style="font-size:16px; font-weight:800; color:var(--accent);">${connections} Connections</div>
          <div style="font-size:11px; font-weight:700; color:var(--text-muted);">${badgeTitle}</div>
        </div>
      </div>
    `;
  }).join("");
}

function renderProfile() {
  const user = state.currentUser;
  if (!user) return;

  // Avatar
  const avatarEl = document.getElementById("profile-avatar-display");
  if (avatarEl) {
    const isFlaker = (user.consecutiveBackouts || 0) >= 3;
    avatarEl.innerHTML = renderAvatar(user.avatarEmoji, "lg", isFlaker);
  }

  // Name, nickname, phone
  const nameEl = document.getElementById("profile-name-display");
  if (nameEl) nameEl.textContent = user.name || "Beach Player";

  const nickEl = document.getElementById("profile-nickname-display");
  if (nickEl) nickEl.textContent = user.nickname ? `@${user.nickname}` : "";

  const phoneEl = document.getElementById("profile-phone-display");
  if (phoneEl) phoneEl.textContent = user.phoneNumber ? `📱 ${user.phoneNumber}` : "";

  // Rating badge
  const ratingEl = document.getElementById("profile-rating-badge");
  if (ratingEl) ratingEl.textContent = `${user.rating || "B"} TIER`;

  // Stars & Flaker
  const starsEl = document.getElementById("profile-stars");
  if (starsEl) {
    starsEl.textContent = `⭐ ${formatStarRating(user)} (${user.starRatingCount || 0} reviews)`;
  }

  const flakerBadge = document.getElementById("profile-flaker-badge");
  if (flakerBadge) {
    flakerBadge.style.display = ((user.consecutiveBackouts || 0) >= 3) ? "block" : "none";
  }

  // Bio
  const bioEl = document.getElementById("profile-bio-display");
  if (bioEl) {
    bioEl.textContent = user.bio ? `"${user.bio}"` : '"Ready for some fun beach doubles on the sand!"';
  }

  // Popular kids highlight
  const connections = getUniqueConnectionsCount(user);
  const title = getPopularKidsTitle(connections);
  const popTitleEl = document.getElementById("profile-popular-title");
  if (popTitleEl) popTitleEl.textContent = title;
  const popCountEl = document.getElementById("profile-popular-count");
  if (popCountEl) popCountEl.textContent = `${connections} Players`;

  // Stats Grid
  const wins = user.wins || 0;
  const losses = user.losses || 0;
  const total = wins + losses;
  const pct = total > 0 ? Math.round((wins / total) * 100) : 0;

  const recEl = document.getElementById("profile-record-display");
  if (recEl) recEl.textContent = `${wins}W - ${losses}L`;

  const winrateEl = document.getElementById("profile-winrate-display");
  if (winrateEl) winrateEl.textContent = `${pct}%`;

  const eloEl = document.getElementById("profile-elo-display");
  if (eloEl) eloEl.textContent = `${user.eloRating || 1500}`;

  const beachEl = document.getElementById("profile-beach-display");
  if (beachEl) beachEl.textContent = user.homeBeach || "Main Beach";

  updatePushStatusBadge();

  // Demo Mode Profile Switcher - strictly restricted to 4087869405
  const demoCard = document.getElementById("demo-mode-card");
  const isRoot = isRootUser(user);
  if (demoCard) {
    if (isRoot) {
      demoCard.style.display = "block";
      const toggleEl = document.getElementById("demo-mode-toggle");
      if (toggleEl) toggleEl.checked = !!state.isDemoModeEnabled;
      const toggleContainer = document.getElementById("demo-mode-toggle-container");
      if (toggleContainer) toggleContainer.style.display = "flex";
      const switchBox = document.getElementById("demo-switch-box");
      if (switchBox) switchBox.style.display = state.isDemoModeEnabled ? "flex" : "none";
    } else if (state.isDemoModeEnabled) {
      // Demo mode was enabled by 4087869405, allow active switching
      demoCard.style.display = "block";
      const toggleContainer = document.getElementById("demo-mode-toggle-container");
      if (toggleContainer) toggleContainer.style.display = "none";
      const switchBox = document.getElementById("demo-switch-box");
      if (switchBox) switchBox.style.display = "flex";
    } else {
      demoCard.style.display = "none";
      const toggleContainer = document.getElementById("demo-mode-toggle-container");
      if (toggleContainer) toggleContainer.style.display = "none";
    }
  }

  // Populate Switch User dropdown
  const switchSelect = document.getElementById("switch-user-select");
  if (switchSelect) {
    switchSelect.innerHTML = state.players.map(p => 
      `<option value="${p.id}" ${p.id === user?.id ? "selected" : ""}>${p.name} (${p.rating})</option>`
    ).join("");
  }
}

window.openEditProfileModal = () => {
  const user = state.currentUser;
  if (!user) return;
  const modal = document.getElementById("edit-profile-modal");
  if (!modal) return;

  document.getElementById("edit-profile-name").value = user.name || "";
  document.getElementById("edit-profile-nickname").value = user.nickname || "";
  document.getElementById("edit-profile-phone").value = user.phoneNumber || "";
  document.getElementById("edit-profile-rating").value = user.rating || "B";

  const beachSelect = document.getElementById("edit-profile-beach");
  if (beachSelect) {
    const beachVal = user.homeBeach || "Main Beach";
    const optionExists = Array.from(beachSelect.options).some(o => o.value === beachVal);
    if (!optionExists && beachVal) {
      const opt = document.createElement("option");
      opt.value = beachVal;
      opt.textContent = beachVal;
      beachSelect.appendChild(opt);
    }
    beachSelect.value = beachVal;
  }

  document.getElementById("edit-profile-bio").value = user.bio || "";

  const currentAvatar = user.avatarEmoji || "slug";
  window.selectedEditProfileAvatar = currentAvatar;
  document.querySelectorAll("#edit-profile-avatars .avatar-btn").forEach(btn => {
    const btnAvatar = btn.dataset.avatar;
    const isSelected = (btnAvatar === currentAvatar) ||
                       (isSlugAvatar(btnAvatar) && isSlugAvatar(currentAvatar)) ||
                       (isMustangAvatar(btnAvatar) && isMustangAvatar(currentAvatar));
    btn.classList.toggle("selected", isSelected);
    btn.onclick = (e) => {
      e.stopPropagation();
      document.querySelectorAll("#edit-profile-avatars .avatar-btn").forEach(b => b.classList.remove("selected"));
      btn.classList.add("selected");
      window.selectedEditProfileAvatar = btn.dataset.avatar;
    };
  });

  modal.classList.add("active");
};

window.closeEditProfileModal = () => {
  const modal = document.getElementById("edit-profile-modal");
  if (modal) modal.classList.remove("active");
};

window.handleSaveEditProfile = (e) => {
  if (e) e.preventDefault();
  const user = state.currentUser;
  if (!user) return;

  const name = document.getElementById("edit-profile-name").value.trim();
  const nickname = document.getElementById("edit-profile-nickname").value.trim();
  const phoneNumber = document.getElementById("edit-profile-phone").value.trim();
  const rating = document.getElementById("edit-profile-rating").value;
  const homeBeach = document.getElementById("edit-profile-beach").value;
  const bio = document.getElementById("edit-profile-bio").value.trim();
  const avatarEmoji = window.selectedEditProfileAvatar || user.avatarEmoji || "slug";

  if (!name) {
    showToast("Please enter your name.");
    return;
  }

  user.name = name;
  user.nickname = nickname;
  user.phoneNumber = phoneNumber;
  user.rating = rating;
  user.homeBeach = homeBeach;
  user.bio = bio;
  user.avatarEmoji = avatarEmoji;

  const idx = state.players.findIndex(p => p.id === user.id);
  if (idx !== -1) {
    state.players[idx] = user;
  }

  state.saveLocal();
  savePlayerToFirestore(user);
  window.closeEditProfileModal();
  renderHeader();
  renderProfile();
  renderLadder();
  renderMatches();
  showToast("Profile updated & synced successfully!");
};

// PUSH NOTIFICATION HELPERS
export function updatePushStatusBadge() {
  const badge = document.getElementById("push-status-badge");
  const btn = document.getElementById("btn-enable-push");
  if (!badge) return;

  if (!("Notification" in window)) {
    badge.textContent = "Push: Not Supported";
    badge.style.background = "#fee2e2";
    badge.style.color = "#b91c1c";
    if (btn) btn.disabled = true;
    return;
  }

  if (Notification.permission === "granted") {
    badge.textContent = "Push: Active 🔔";
    badge.style.background = "#dcfce7";
    badge.style.color = "#15803d";
    if (btn) {
      btn.textContent = "Push Notifications Active ✅";
      btn.classList.replace("btn-primary", "btn-outline");
    }
  } else if (Notification.permission === "denied") {
    badge.textContent = "Push: Blocked 🚫";
    badge.style.background = "#fee2e2";
    badge.style.color = "#b91c1c";
    if (btn) btn.textContent = "Permission Blocked in Browser";
  } else {
    badge.textContent = "Push: Inactive";
    badge.style.background = "#e0f2fe";
    badge.style.color = "#0284c7";
  }
}

export async function triggerWebPushNotification(title, body) {
  if (!("Notification" in window)) return;
  if (Notification.permission === "granted") {
    try {
      if ("serviceWorker" in navigator) {
        const reg = await navigator.serviceWorker.getRegistration();
        if (reg && reg.showNotification) {
          reg.showNotification(title, {
            body,
            icon: "assets/slug.png",
            badge: "assets/slug.png",
            vibrate: [200, 100, 200],
            tag: "setmatch-alert"
          });
          return;
        }
      }
      new Notification(title, { body, icon: "assets/slug.png" });
    } catch (e) {
      console.warn("Notification error:", e);
    }
  }
}

window.enablePushNotifications = async () => {
  if (!("Notification" in window)) {
    showToast("Web Push notifications are not supported in this browser.");
    return;
  }

  const permission = await Notification.requestPermission();
  updatePushStatusBadge();
  if (permission === "granted") {
    triggerWebPushNotification("🏐 Notifications Enabled!", "You'll now receive instant alerts when your set games are locked.");
    showToast("Push notifications enabled! 🔔");
  } else {
    showToast("Notification permission was not granted.");
  }
};

window.sendTestNotification = () => {
  if (Notification.permission === "granted") {
    triggerWebPushNotification("🏐 Volleyball Match Alert", "Saturday Morning AA Doubles at Main Beach Court #2 is locked!");
    showToast("Test push notification dispatched!");
  } else {
    showToast("Please click 'Enable Browser Push' first!");
  }
};

// 30-Minute Upcoming Match Reminders (Web Parity)
export function checkUpcomingMatchReminders() {
  if (!state.currentUser || !("Notification" in window) || Notification.permission !== "granted") return;
  const now = Date.now();
  const myUpcomingGames = (state.games || []).filter(g => {
    if (g.status === "completed" || g.status === "canceled") return false;
    const isMember = (g.team1PlayerIds && g.team1PlayerIds.includes(state.currentUser.id)) ||
                     (g.team2PlayerIds && g.team2PlayerIds.includes(state.currentUser.id)) ||
                     g.hostPlayerId === state.currentUser.id;
    return isMember;
  });

  for (const game of myUpcomingGames) {
    if (!game.scheduledDate) continue;
    const gameTime = new Date(game.scheduledDate).getTime();
    if (isNaN(gameTime)) continue;
    const diffMins = Math.round((gameTime - now) / 60000);
    // Alert if match starts within 30 minutes (between 1 and 30 minutes away)
    if (diffMins > 0 && diffMins <= 30) {
      const storageKey = `match_reminded_30m_${game.id}`;
      if (!sessionStorage.getItem(storageKey)) {
        sessionStorage.setItem(storageKey, "true");
        triggerWebPushNotification(
          `⏰ Upcoming Match in ${diffMins} Minutes!`,
          `${game.title} at ${game.courtLocation} (${game.courtNumber || 'Court #1'}) starts soon. Time to head to the courts!`
        );
      }
    }
  }
}
setInterval(checkUpcomingMatchReminders, 60000);

// NAVIGATION
export function switchTab(tabId) {
  const normalizedId = (tabId === "ladder" || tabId === "popular") ? "ladders" : tabId;

  // If player isn't logged in, they cannot access Set games, Auto-Match, or Profile. Only Ladders is visible.
  if (!state.currentUser && normalizedId !== "ladders") {
    if (typeof window.showAuthModal === "function") {
      window.showAuthModal();
    }
    const activeTab = document.querySelector(".tab-content.active");
    if (!activeTab || activeTab.id !== "tab-ladders") {
      switchTab("ladders");
    }
    return;
  }

  document.querySelectorAll(".tab-content").forEach(el => el.classList.remove("active"));
  document.querySelectorAll(".nav-item").forEach(el => el.classList.remove("active"));

  const targetTab = document.getElementById(`tab-${normalizedId}`);
  const targetNav = document.getElementById(`nav-${normalizedId}`);

  if (targetTab) targetTab.classList.add("active");
  if (targetNav) targetNav.classList.add("active");

  // Track screen view in Firebase Analytics & Microsoft Clarity
  try {
    trackEvent("screen_view", {
      screen_name: normalizedId,
      page_title: normalizedId
    });
  } catch (e) {
    console.warn("trackEvent screen_view warning:", e);
  }

  try {
    if (normalizedId === "matches") renderMatches();
    if (normalizedId === "ladders") {
      renderLadder();
      renderPopularKids();
    }
    if (normalizedId === "profile") renderProfile();
  } catch (e) {
    console.error(`Error rendering tab ${normalizedId}:`, e);
  }
}

window.switchTab = switchTab;
window.renderProfile = renderProfile;
window.renderAvailabilityWindows = renderAvailabilityWindows;
window.renderHeader = renderHeader;
window.renderPickupQueue = () => window.renderInstantPickupModal && window.renderInstantPickupModal();
window.renderOpenGames = renderOpenGames;

window.switchLadderTab = (type) => {
  const topView = document.getElementById("ladder-top-players-view");
  const popView = document.getElementById("ladder-popular-kids-view");
  const segButtons = document.querySelectorAll("#ladder-type-segmented .ios-segmented-item");

  segButtons.forEach(btn => {
    btn.classList.toggle("active", btn.dataset.ladderTab === type);
  });

  if (type === "topPlayers") {
    if (topView) topView.style.display = "block";
    if (popView) popView.style.display = "none";
    renderLadder();
  } else {
    if (topView) topView.style.display = "none";
    if (popView) popView.style.display = "block";
    renderPopularKids();
  }
};

// AUTH MODAL & PHONE LOGIN HANDLERS
window.selectedSignupAvatarEmoji = "slug";

window.showAuthModal = () => {
  const modal = document.getElementById("auth-modal");
  if (modal) modal.classList.add("active");
};

window.closeAuthModal = () => {
  const modal = document.getElementById("auth-modal");
  if (modal) modal.classList.remove("active");
};

window.switchAuthMode = (mode) => {
  const loginForm = document.getElementById("login-form");
  const signupForm = document.getElementById("signup-form");
  const tabLogin = document.getElementById("tab-btn-login");
  const tabSignup = document.getElementById("tab-btn-signup");

  if (mode === "login") {
    if (loginForm) loginForm.style.display = "block";
    if (signupForm) signupForm.style.display = "none";
    if (tabLogin) tabLogin.classList.add("active");
    if (tabSignup) tabSignup.classList.remove("active");
  } else {
    if (loginForm) loginForm.style.display = "none";
    if (signupForm) signupForm.style.display = "block";
    if (tabSignup) tabSignup.classList.add("active");
    if (tabLogin) tabLogin.classList.remove("active");
    
    const loginVal = document.getElementById("login-phone")?.value;
    if (loginVal && document.getElementById("signup-phone")) {
      document.getElementById("signup-phone").value = loginVal;
    }
  }
};

window.fillDemoPhone = (phone) => {
  const input = document.getElementById("login-phone");
  const pwInput = document.getElementById("login-password");
  if (input) input.value = phone;
  if (pwInput) pwInput.value = "volleyball123";
  window.handlePhoneLogin(new Event("submit"));
};

window.selectSignupAvatar = (el, emoji) => {
  document.querySelectorAll("[data-signup-avatar]").forEach(b => b.classList.remove("selected"));
  el.classList.add("selected");
  window.selectedSignupAvatarEmoji = emoji;
};

window.handlePhoneLogin = (e) => {
  if (e) e.preventDefault();
  const phone = document.getElementById("login-phone")?.value || "";
  const password = document.getElementById("login-password")?.value || "";
  const cleaned = phone.replace(/\D/g, "");
  const errEl = document.getElementById("login-error");

  if (!cleaned) {
    if (errEl) {
      errEl.textContent = "Please enter your phone number.";
      errEl.style.display = "block";
    }
    return;
  }

  if (!password) {
    if (errEl) {
      errEl.textContent = "Please enter your password.";
      errEl.style.display = "block";
    }
    return;
  }

  // Find player by phone number digits or raw match
  const player = state.players.find(p => {
    const pCleaned = (p.phoneNumber || "").replace(/\D/g, "");
    return (pCleaned && pCleaned === cleaned) || p.phoneNumber === phone;
  });

  if (player) {
    if (player.password && player.password !== password) {
      if (errEl) {
        errEl.textContent = "Incorrect password. Please try again.";
        errEl.style.display = "block";
      }
      return;
    }
    state.currentUser = player;
    if (!isRootUser(player)) {
      state.isDemoModeEnabled = false;
      try {
        localStorage.removeItem("setgames_demo_mode");
      } catch (e) {}
    }
    state.saveLocal();
    setUserAnalyticsIdentity(player);
    trackEvent("login", { method: "phone", tier: player.rating || "Unrated" });
    if (errEl) errEl.style.display = "none";
    window.closeAuthModal();
    renderHeader();
    renderProfile();
    renderMatches();
    showToast(`Welcome back, ${player.nickname || player.name}!`);
  } else {
    if (errEl) {
      errEl.innerHTML = `No player found with ${phone}. <a href="#" style="color: var(--accent); text-decoration: underline; font-weight: bold;" onclick="window.switchAuthMode('signup')">Sign up as New Player</a> in 10 seconds!`;
      errEl.style.display = "block";
    }
  }
};

window.handlePhoneSignUp = (e) => {
  if (e) e.preventDefault();
  const phone = document.getElementById("signup-phone")?.value.trim() || "";
  const password = document.getElementById("signup-password")?.value.trim() || "";
  const name = document.getElementById("signup-name")?.value.trim() || "Beach Player";
  const rating = document.getElementById("signup-rating")?.value || "Intermediate";
  const homeBeach = document.getElementById("signup-beach")?.value || "Main Beach";
  const avatar = window.selectedSignupAvatarEmoji || "slug";

  if (!phone) {
    showToast("Please enter your mobile phone number.");
    return;
  }

  if (!password) {
    showToast("Please create a password for your account.");
    return;
  }

  const baseElo = rating === "AA" ? 2100 : rating === "A" ? 1800 : rating === "B" ? 1550 : 1350;
  const newPlayerId = (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') 
    ? crypto.randomUUID().toUpperCase() 
    : deterministicUUID("player-" + Date.now());
  const newPlayer = {
    id: newPlayerId,
    name,
    nickname: name.split(" ")[0],
    phoneNumber: phone,
    password,
    rating,
    eloRating: baseElo,
    homeBeach,
    avatarEmoji: avatar,
    wins: 0,
    losses: 0,
    streak: 0,
    pointsScored: 0,
    pointsAllowed: 0,
    uniquePartnerIds: [],
    uniqueOpponentIds: []
  };

  state.players.push(newPlayer);
  state.currentUser = newPlayer;
  state.isDemoModeEnabled = false;
  try {
    localStorage.removeItem("setgames_demo_mode");
  } catch (e) {}
  state.saveLocal();
  savePlayerToFirestore(newPlayer);
  setUserAnalyticsIdentity(newPlayer);
  trackEvent("sign_up", { method: "phone", tier: newPlayer.rating, beach: newPlayer.homeBeach });

  window.closeAuthModal();
  renderHeader();
  renderProfile();
  renderLadder();
  renderMatches();
  showToast(`Welcome to Volleyball Match, ${newPlayer.name}! 🏐`);
};

window.handleLogout = () => {
  state.currentUser = null;
  state.isDemoModeEnabled = false;
  try {
    localStorage.removeItem("setgames_demo_mode");
    localStorage.removeItem("setgames_current_user_id");
  } catch (e) {}
  state.saveLocal();
  renderHeader();
  renderLadder();
  renderPopularKids();
  switchTab("ladders");
  window.showAuthModal();
  showToast("Logged out successfully.");
};

window.handleDeleteProfile = () => {
  if (!state.currentUser) return;
  const user = state.currentUser;
  const userName = user.nickname ? `${user.name} (${user.nickname})` : user.name;
  
  if (!confirm(`Are you sure you want to permanently delete your profile (${userName})?\n\nThis will remove your player record, ratings, and stats from the game. This action cannot be undone.`)) {
    return;
  }

  const userId = user.id;

  // 1. Remove user from all games and waitlists, auto-promoting waitlisted players
  state.games.forEach(game => {
    let changed = false;
    if (game.waitlistPlayerIds && game.waitlistPlayerIds.includes(userId)) {
      game.waitlistPlayerIds = game.waitlistPlayerIds.filter(id => id !== userId);
      changed = true;
    }
    const wasInTeam1 = game.team1PlayerIds && game.team1PlayerIds.includes(userId);
    const wasInTeam2 = game.team2PlayerIds && game.team2PlayerIds.includes(userId);
    if (wasInTeam1 || wasInTeam2) {
      game.team1PlayerIds = (game.team1PlayerIds || []).filter(id => id !== userId);
      game.team2PlayerIds = (game.team2PlayerIds || []).filter(id => id !== userId);
      changed = true;

      // Auto-promote waitlist
      const currentTotal = (game.team1PlayerIds?.length || 0) + (game.team2PlayerIds?.length || 0);
      const maxP = game.maxPlayers || 4;
      if (game.waitlistPlayerIds && game.waitlistPlayerIds.length > 0 && currentTotal < maxP) {
        const promotedId = game.waitlistPlayerIds.shift();
        if ((game.team1PlayerIds?.length || 0) <= (game.team2PlayerIds?.length || 0)) {
          game.team1PlayerIds.push(promotedId);
        } else {
          game.team2PlayerIds.push(promotedId);
        }
      }
    }
    if (game.hostPlayerId === userId) {
      game.hostPlayerId = (game.team1PlayerIds?.[0] || game.team2PlayerIds?.[0] || null);
      changed = true;
    }
    if (changed) {
      saveGameToFirestore(game);
    }
  });

  // 2. Remove user from state.players
  state.players = state.players.filter(p => p.id !== userId);

  // 3. Delete player from Firestore
  deletePlayerFromFirestore(userId);

  // 4. Clear current user & storage
  state.currentUser = null;
  state.isDemoModeEnabled = false;
  try {
    localStorage.removeItem("setgames_demo_mode");
    localStorage.removeItem("setgames_current_user_id");
  } catch (e) {}
  state.saveLocal();

  // 5. Update UI & show login
  renderHeader();
  renderLadder();
  renderPopularKids();
  switchTab("ladders");
  window.showAuthModal();
  showToast("Your profile has been permanently deleted.");
};

// GLOBAL ACTION HANDLERS (available on window)
window.joinGame = window.joinGamePool;

window.leaveGame = (gameId) => {
  const game = state.games.find(g => g.id === gameId);
  if (!game || !state.currentUser) return;

  const userId = state.currentUser.id;

  // If user was simply waitlisted, remove from waitlist without penalty
  if (game.waitlistPlayerIds && game.waitlistPlayerIds.includes(userId)) {
    window.leaveWaitlist(gameId);
    return;
  }

  const wasInTeam1 = game.team1PlayerIds?.includes(userId);
  const wasInTeam2 = game.team2PlayerIds?.includes(userId);
  if (!wasInTeam1 && !wasInTeam2) return;

  game.team1PlayerIds = (game.team1PlayerIds || []).filter(id => id !== userId);
  game.team2PlayerIds = (game.team2PlayerIds || []).filter(id => id !== userId);

  // Auto-promote first player from waitlist if spots opened
  let promotedPlayerName = null;
  if (!game.waitlistPlayerIds) game.waitlistPlayerIds = [];
  const currentTotal = (game.team1PlayerIds?.length || 0) + (game.team2PlayerIds?.length || 0);
  const maxP = game.maxPlayers || 4;
  if (game.waitlistPlayerIds.length > 0 && currentTotal < maxP) {
    const promotedId = game.waitlistPlayerIds.shift();
    if ((game.team1PlayerIds?.length || 0) <= (game.team2PlayerIds?.length || 0)) {
      if (!game.team1PlayerIds) game.team1PlayerIds = [];
      game.team1PlayerIds.push(promotedId);
    } else {
      if (!game.team2PlayerIds) game.team2PlayerIds = [];
      game.team2PlayerIds.push(promotedId);
    }
    const promotedPlayer = state.players.find(p => p.id === promotedId);
    promotedPlayerName = promotedPlayer ? (promotedPlayer.nickname || promotedPlayer.name) : "A waitlisted player";
  }

  // If host leaves, reassign host if another player remains
  if (game.hostPlayerId === userId) {
    game.hostPlayerId = (game.team1PlayerIds[0] || game.team2PlayerIds[0] || null);
  }

  // Increment consecutive backouts & check flaker flag (3x in a row)
  state.currentUser.consecutiveBackouts = (state.currentUser.consecutiveBackouts || 0) + 1;
  const isFlaker = state.currentUser.consecutiveBackouts >= 3;
  savePlayerToFirestore(state.currentUser);

  state.saveLocal();
  saveGameToFirestore(game);
  renderMatches();
  renderLadder();
  renderPopularKids();
  renderHeader();

  if (isFlaker) {
    showToast(`You backed out 3x in a row: flagged as Flaker (F) and your rating was lowered by 1 point! Complete a match to restore it.`);
  } else if (promotedPlayerName) {
    showToast(`You left ${game.title}. ${promotedPlayerName} was auto-promoted from the waitlist into your spot!`);
  } else {
    showToast(`You left ${game.title}. (Backed out ${state.currentUser.consecutiveBackouts}/3 times)`);
  }
};

// Format Default Game Title: e.g. "Saturday 9/5/26 5PM"
export function formatDefaultGameTitle(dateObj) {
  const d = dateObj instanceof Date ? dateObj : new Date(dateObj);
  if (isNaN(d.getTime())) return "Beach Game";
  
  const days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
  const dayName = days[d.getDay()];
  const month = d.getMonth() + 1;
  const day = d.getDate();
  const year = String(d.getFullYear()).slice(-2);
  
  let hours = d.getHours();
  const minutes = d.getMinutes();
  const ampm = hours >= 12 ? "PM" : "AM";
  hours = hours % 12;
  hours = hours ? hours : 12;
  
  const timeStr = minutes === 0 ? `${hours}${ampm}` : `${hours}:${String(minutes).padStart(2, "0")}${ampm}`;
  return `${dayName} ${month}/${day}/${year} ${timeStr}`;
}

// Tier Dropdown Multi-Select
window.toggleTierDropdown = (type) => {
  const menu = document.getElementById(`${type}-tier-dropdown-menu`);
  const btn = document.getElementById(`${type}-tier-dropdown-btn`);
  if (!menu || !btn) return;

  const isOpen = menu.classList.contains("show");
  
  // Close any other open dropdowns
  document.querySelectorAll(".tier-dropdown-menu").forEach(m => m.classList.remove("show"));
  document.querySelectorAll(".tier-dropdown-trigger").forEach(b => b.classList.remove("open"));

  if (!isOpen) {
    menu.classList.add("show");
    btn.classList.add("open");
  }
};

window.updateTierDropdownDisplay = (type) => {
  const displayEl = document.getElementById(`${type}-tier-selected-display`);
  if (!displayEl) return;

  const checkedBoxes = Array.from(document.querySelectorAll(`input[name='${type}-tier-cb']:checked`));
  
  if (checkedBoxes.length === 0) {
    displayEl.innerHTML = `<span style="color:var(--text-muted); font-size:13px;">Select at least 1 tier</span>`;
    return;
  }

  const chipsHtml = checkedBoxes.map(cb => {
    const val = cb.value;
    const lower = val.toLowerCase();
    return `<span class="tier-chip tier-${lower}">${val}</span>`;
  }).join(" ");

  const countText = `<span style="color:var(--text-muted); font-size:13px; margin-left:4px;">(${checkedBoxes.length} selected)</span>`;
  displayEl.innerHTML = chipsHtml + countText;
};

document.addEventListener("click", (e) => {
  if (!e.target.closest(".tier-dropdown-container")) {
    document.querySelectorAll(".tier-dropdown-menu").forEach(m => m.classList.remove("show"));
    document.querySelectorAll(".tier-dropdown-trigger").forEach(b => b.classList.remove("open"));
  }
});

// Create Game
window.openCreateMatchModal = () => {
  if (!state.currentUser) {
    window.showAuthModal();
    return;
  }
  const modal = document.getElementById("create-match-modal");
  const dateInput = document.getElementById("create-date");
  const tierSelect = document.getElementById("create-tier");

  if (tierSelect) tierSelect.value = state.currentUser.rating || "B";

  // Pre-check user's current rating tier by default if not set
  if (state.currentUser && state.currentUser.rating) {
    const currentRating = state.currentUser.rating;
    document.querySelectorAll("input[name='create-tier-cb']").forEach(cb => {
      cb.checked = (cb.value === currentRating);
    });
  }
  window.updateTierDropdownDisplay('create');

  const d = new Date(Date.now() + 86400000);
  d.setMinutes(0, 0, 0);

  if (dateInput) {
    const year = d.getFullYear();
    const month = String(d.getMonth() + 1).padStart(2, "0");
    const day = String(d.getDate()).padStart(2, "0");
    const hours = String(d.getHours()).padStart(2, "0");
    const mins = String(d.getMinutes()).padStart(2, "0");
    dateInput.value = `${year}-${month}-${day}T${hours}:${mins}`;
  }

  modal.classList.add("active");
};

window.closeCreateMatchModal = () => {
  const modal = document.getElementById("create-match-modal");
  if (modal) modal.classList.remove("active");
};

window.handleCreateMatch = (e) => {
  e.preventDefault();
  if (!state.currentUser) return;
  const checkedBoxes = Array.from(document.querySelectorAll("input[name='create-tier-cb']:checked"));
  const allowedRatings = checkedBoxes.map(cb => cb.value);
  const targetRating = allowedRatings[0] || (state.currentUser?.rating || "B");
  const isLevelLocked = document.getElementById("create-level-locked").checked;
  const isPrivate = document.getElementById("create-is-private") ? document.getElementById("create-is-private").checked : false;
  const maxPlayers = parseInt(document.getElementById("create-max-players")?.value) || 4;
  const format = document.getElementById("create-format").value;
  const courtLocation = document.getElementById("create-beach").value;
  const courtNumber = document.getElementById("create-court").value.trim() || "Court #1";
  const scheduledDateInput = document.getElementById("create-date").value;
  const scheduledDate = new Date(scheduledDateInput).toISOString();
  const notes = document.getElementById("create-notes").value.trim();

  const defaultTitle = formatDefaultGameTitle(new Date(scheduledDateInput));
  const newGame = {
    id: "game-" + Date.now(),
    title: defaultTitle,
    targetRating,
    allowedRatings: allowedRatings.length > 0 ? allowedRatings : [targetRating],
    isLevelLocked,
    isPrivate,
    maxPlayers,
    format,
    hostPlayerId: state.currentUser.id,
    courtLocation,
    courtNumber,
    scheduledDate,
    status: "scheduled",
    isAutoMatched: false,
    matchedOptionName: "Host Scheduled",
    notes,
    team1PlayerIds: [state.currentUser.id],
    team2PlayerIds: [],
    submittedRatings: {},
    setScores: []
  };

  state.games.unshift(newGame);
  state.saveLocal();
  saveGameToFirestore(newGame);
  window.closeCreateMatchModal();
  renderMatches();
  showToast(`Game hosted: ${newGame.title}!`);
};

window.closeAdminActionsModal = () => {
  const m = document.getElementById("admin-actions-modal");
  if (m) m.classList.remove("active");
};

window.toggleCardAdminMenu = (gameId) => {
  const game = state.games.find(g => g.id === gameId);
  if (!game) return;

  const currentUserId = state.currentUser ? state.currentUser.id : null;
  const isHost = currentUserId && (
    game.hostPlayerId === currentUserId ||
    (game.team1PlayerIds && game.team1PlayerIds[0] === currentUserId)
  );
  const isMember = currentUserId && (
    (game.team1PlayerIds && game.team1PlayerIds.includes(currentUserId)) ||
    (game.team2PlayerIds && game.team2PlayerIds.includes(currentUserId)) ||
    (game.hostPlayerId === currentUserId)
  );
  const isRoot = state.currentUser && state.currentUser.isRoot;

  const container = document.getElementById("admin-actions-body");
  if (!container) return;

  container.innerHTML = `
    <button type="button" class="btn btn-outline" style="justify-content: flex-start; gap: 8px; font-weight: 700; color: #ea580c; border-color: #fdba74; padding: 10px 14px;" onclick="window.closeAdminActionsModal(); window.openRandomTeamsModalForGame('${game.id}')">
      <span style="font-size: 16px;">🎲</span>
      <span>Generate / Rotate Matches</span>
    </button>
    
    <button type="button" class="btn btn-outline" style="justify-content: flex-start; gap: 8px; font-weight: 700; padding: 10px 14px;" onclick="window.closeAdminActionsModal(); window.openGameQRCodeModal('${game.id}')">
      <span style="font-size: 16px;">📱</span>
      <span>QR Code & Share Link</span>
    </button>

    ${isMember ? `
      <button type="button" class="btn btn-outline" style="justify-content: flex-start; gap: 8px; font-weight: 700; color: #0284c7; border-color: #bae6fd; padding: 10px 14px;" onclick="window.closeAdminActionsModal(); window.openMatchChatModal('${game.id}')">
        <span style="font-size: 16px;">💬</span>
        <span>Match Chat (${(game.messages || []).length})</span>
      </button>
    ` : ''}

    <button type="button" class="btn btn-outline" style="justify-content: flex-start; gap: 8px; font-weight: 700; padding: 10px 14px;" onclick="window.closeAdminActionsModal(); window.openEditMatchModal('${game.id}')">
      <span style="font-size: 16px;">✏️</span>
      <span>Edit Game Preferences</span>
    </button>

    ${(isHost || isRoot) && game.waitlistPlayerIds && game.waitlistPlayerIds.length > 0 ? `
      <div style="display: flex; flex-direction: column; gap: 4px; border-top: 1px solid rgba(255,255,255,0.1); padding-top: 6px; margin-top: 4px;">
        <div style="font-size: 11px; font-weight: 800; color: #c084fc; text-transform: uppercase; padding: 2px 4px;">Waiting Players (${game.waitlistPlayerIds.length})</div>
        ${game.waitlistPlayerIds.map((pid, idx) => {
          const p = state.getPlayer(pid);
          const pName = p ? (p.nickname || p.name) : `Player ${idx + 1}`;
          return `
            <button type="button" class="btn btn-outline" style="justify-content: flex-start; gap: 8px; font-weight: 700; color: #10b981; border-color: #6ee7b7; padding: 8px 12px;" onclick="window.closeAdminActionsModal(); window.promoteWaitlistPlayer('${game.id}', '${pid}')">
              <span>➕</span>
              <span>Add ${pName} to Game</span>
            </button>
          `;
        }).join('')}
      </div>
    ` : ''}

    ${(isHost || isRoot) && (game.spotsRemaining === 0 || ((game.team1PlayerIds?.length || 0) + (game.team2PlayerIds?.length || 0) >= (game.maxPlayers || 4))) ? `
      <button type="button" class="btn btn-outline" style="justify-content: flex-start; gap: 8px; font-weight: 700; color: #38bdf8; border-color: #7dd3fc; padding: 10px 14px;" onclick="window.closeAdminActionsModal(); window.addSpotToGame('${game.id}')">
        <span style="font-size: 16px;">➕</span>
        <span>+ Add Spot to Full Game</span>
      </button>
    ` : ''}

    ${(isHost || isRoot) ? `
      <button type="button" class="btn btn-outline" style="justify-content: flex-start; gap: 8px; font-weight: 700; color: #dc2626; border-color: #fca5a5; margin-top: 6px; padding: 10px 14px;" onclick="window.closeAdminActionsModal(); window.deleteGame('${game.id}');">
        <span style="font-size: 16px;">❌</span>
        <span>Cancel Game (Delete)</span>
      </button>
    ` : ''}
  `;

  const m = document.getElementById("admin-actions-modal");
  if (m) m.classList.add("active");
};

window.showGameDetailsModal = (gameId) => {
  window.openEditMatchModal(gameId);
};

// Edit Match (Participants)
window.openEditMatchModal = (gameId) => {
  const game = state.games.find(g => g.id === gameId);
  if (!game) return;
  const isMember = state.currentUser && (
    game.team1PlayerIds?.includes(state.currentUser.id) ||
    game.team2PlayerIds?.includes(state.currentUser.id) ||
    game.hostPlayerId === state.currentUser.id ||
    isRootUser(state.currentUser)
  );
  if (!isMember) {
    showToast("Only match participants can edit match preferences.");
    return;
  }

  document.getElementById("edit-game-id").value = gameId;
  document.getElementById("edit-title").value = game.title;
  
  const allowed = (game.allowedRatings && game.allowedRatings.length > 0) ? game.allowedRatings : [game.targetRating || "B"];
  document.querySelectorAll("input[name='edit-tier-cb']").forEach(cb => {
    cb.checked = allowed.includes(cb.value);
  });
  window.updateTierDropdownDisplay('edit');
  
  document.getElementById("edit-level-locked").checked = !!game.isLevelLocked;
  if (document.getElementById("edit-is-private")) {
    document.getElementById("edit-is-private").checked = !!game.isPrivate;
  }
  if (document.getElementById("edit-max-players")) {
    document.getElementById("edit-max-players").value = game.maxPlayers || 4;
  }
  document.getElementById("edit-format").value = game.format || "Best of 3 Sets (21-21-15)";
  document.getElementById("edit-beach").value = game.courtLocation || "Main Beach";
  document.getElementById("edit-court").value = game.courtNumber || "Court #1";
  document.getElementById("edit-notes").value = game.notes || "";
  
  const dateInput = document.getElementById("edit-date");
  if (dateInput) {
    const d = parseGameDate(game.scheduledDate);
    d.setMinutes(d.getMinutes() - d.getTimezoneOffset());
    dateInput.value = d.toISOString().slice(0, 16);
  }

  document.getElementById("edit-match-modal").classList.add("active");
};

window.closeEditMatchModal = () => {
  const modal = document.getElementById("edit-match-modal");
  if (modal) modal.classList.remove("active");
};

window.handleSaveMatchEdit = (e) => {
  e.preventDefault();
  const gameId = document.getElementById("edit-game-id").value;
  const game = state.games.find(g => g.id === gameId);
  if (!game) return;

  const checkedBoxes = Array.from(document.querySelectorAll("input[name='edit-tier-cb']:checked"));
  const allowedRatings = checkedBoxes.map(cb => cb.value);
  game.allowedRatings = allowedRatings.length > 0 ? allowedRatings : [game.targetRating || "B"];
  game.targetRating = game.allowedRatings[0] || "B";

  game.title = document.getElementById("edit-title").value.trim();
  game.isLevelLocked = document.getElementById("edit-level-locked").checked;
  if (document.getElementById("edit-is-private")) {
    game.isPrivate = document.getElementById("edit-is-private").checked;
  }
  game.maxPlayers = parseInt(document.getElementById("edit-max-players")?.value) || game.maxPlayers || 4;
  game.format = document.getElementById("edit-format").value;
  game.courtLocation = document.getElementById("edit-beach").value;
  game.courtNumber = document.getElementById("edit-court").value.trim();
  game.scheduledDate = new Date(document.getElementById("edit-date").value).toISOString();
  game.notes = document.getElementById("edit-notes").value.trim();

  state.saveLocal();
  saveGameToFirestore(game);
  window.closeEditMatchModal();
  renderMatches();
  showToast("Match preferences updated!");
};

// Cancel & Delete Game (Host or Root user)
window.deleteGame = (gameId) => {
  const game = state.games.find(g => g.id === gameId);
  if (!game) return;

  const isRoot = isRootUser(state.currentUser);
  const isHost = state.currentUser && (
    (game.hostPlayerId && game.hostPlayerId === state.currentUser.id) ||
    (game.team1PlayerIds?.[0] === state.currentUser.id)
  );
  if (!isRoot && !isHost) {
    showToast("Only the game host or Root user can cancel and delete this game.");
    return;
  }

  const promptMsg = isRoot 
    ? `As Root Admin, permanently delete "${game.title}" from the database?`
    : `Are you sure you want to cancel and delete "${game.title}" from the schedule?`;

  if (!confirm(promptMsg)) {
    return;
  }

  // Notify other players via APNs push
  const currentUid = state.currentUser?.id;
  const currentToken = state.currentUser?.deviceToken;
  const otherIds = [...new Set([...(game.team1PlayerIds || []), ...(game.team2PlayerIds || []), ...(game.waitlistPlayerIds || [])])].filter(id => id !== currentUid);
  const tokens = Array.from(new Set(otherIds.map(id => state.getPlayer(id)?.deviceToken).filter(t => t && typeof t === "string" && t.trim().length > 0 && t !== currentToken)));
  if (tokens.length > 0) {
    fetch("/api/send-push", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        tokens: tokens,
        title: "Volleyball Match Alert",
        body: `The host cancelled '${game.title || "Match"}'.`,
        gameId: game.id
      })
    }).catch(err => console.log("Push note:", err));
  }

  state.games = state.games.filter(g => g.id !== gameId);
  state.saveLocal();
  deleteGameFromFirestore(gameId);
  renderMatches();
  showToast("Match cancelled and deleted.");
};

window.deleteAllGames = async () => {
  if (!isRootUser(state.currentUser)) {
    showToast("Root privileges required.");
    return;
  }
  if (!confirm(`CAUTION: As Root Admin, are you sure you want to delete ALL ${state.games.length} games in the database? This cannot be undone.`)) {
    return;
  }
  const gamesToDelete = [...state.games];
  state.games = [];
  state.saveLocal();
  for (const g of gamesToDelete) {
    deleteGameFromFirestore(g.id);
  }
  renderMatches();
  showToast(`Deleted all ${gamesToDelete.length} games from database.`);
};

// ==========================================
// GAME QR CODE & CROSS-PLATFORM JOIN
// ==========================================
export function getGameShareUrl(gameId) {
  if (window.location.origin && window.location.origin.startsWith("http")) {
    return `${window.location.origin}${window.location.pathname}?gameId=${gameId}`;
  }
  return `https://volleyballmatch-13d66.web.app/?gameId=${gameId}`;
}

window.activeQRGameId = null;

window.openGameQRCodeModal = (gameId) => {
  const game = state.games.find(g => g.id === gameId);
  if (!game) return;
  window.activeQRGameId = gameId;

  const titleEl = document.getElementById("qr-modal-title");
  const detailsEl = document.getElementById("qr-modal-details");
  const urlEl = document.getElementById("qr-modal-url");
  const canvasEl = document.getElementById("qr-code-canvas");
  const fallbackImgEl = document.getElementById("qr-code-fallback-img");
  const modalEl = document.getElementById("modal-game-qr");

  if (titleEl) titleEl.textContent = game.title;
  if (detailsEl) {
    const d = parseGameDate(game.scheduledDate || game.scheduledTime);
    const formattedDate = d.toLocaleDateString("en-US", {
      weekday: "short",
      month: "short",
      day: "numeric",
      hour: "numeric",
      minute: "2-digit"
    });
    const courtLocation = game.courtLocation || "Main Beach";
    const courtDisplay = game.courtNumber
      ? (game.courtNumber.toLowerCase().includes("court") ? game.courtNumber : (game.courtNumber.startsWith("#") ? `Court ${game.courtNumber}` : `Court #${game.courtNumber}`))
      : "Court #1";
    detailsEl.textContent = `📍 ${courtLocation} • ${courtDisplay} • 📅 ${formattedDate}`;
  }

  const shareUrl = getGameShareUrl(game.id);
  if (urlEl) urlEl.textContent = shareUrl;

  // Render QR code using QRCode.js if available, else fallback to QR image service
  if (window.QRCode && canvasEl) {
    canvasEl.style.display = "block";
    if (fallbackImgEl) fallbackImgEl.style.display = "none";
    QRCode.toCanvas(canvasEl, shareUrl, {
      width: 220,
      margin: 1,
      color: {
        dark: "#0f172a",
        light: "#ffffff"
      }
    }, (error) => {
      if (error) {
        console.warn("QRCode canvas generation error, using fallback image:", error);
        if (fallbackImgEl) {
          canvasEl.style.display = "none";
          fallbackImgEl.style.display = "block";
          fallbackImgEl.src = `https://api.qrserver.com/v1/create-qr-code/?size=220x220&data=${encodeURIComponent(shareUrl)}`;
        }
      }
    });
  } else if (fallbackImgEl) {
    if (canvasEl) canvasEl.style.display = "none";
    fallbackImgEl.style.display = "block";
    fallbackImgEl.src = `https://api.qrserver.com/v1/create-qr-code/?size=220x220&data=${encodeURIComponent(shareUrl)}`;
  }

  const copyBtn = document.getElementById("btn-copy-qr-link");
  if (copyBtn) {
    copyBtn.innerHTML = "📋 Copy Share Link";
    copyBtn.style.color = "";
    copyBtn.style.borderColor = "";
  }

  if (modalEl) modalEl.classList.add("active");
};

window.closeGameQRCodeModal = () => {
  const modalEl = document.getElementById("modal-game-qr");
  if (modalEl) modalEl.classList.remove("active");
  window.activeQRGameId = null;
};

window.copyGameQRLink = () => {
  if (!window.activeQRGameId) return;
  const shareUrl = getGameShareUrl(window.activeQRGameId);
  navigator.clipboard.writeText(shareUrl).then(() => {
    const copyBtn = document.getElementById("btn-copy-qr-link");
    if (copyBtn) {
      copyBtn.innerHTML = "✓ Copied to Clipboard!";
      copyBtn.style.color = "#16a34a";
      copyBtn.style.borderColor = "#16a34a";
      setTimeout(() => {
        if (copyBtn) {
          copyBtn.innerHTML = "📋 Copy Share Link";
          copyBtn.style.color = "";
          copyBtn.style.borderColor = "";
        }
      }, 2500);
    }
    showToast("Share link copied to clipboard!");
  }).catch(() => {
    showToast("Unable to copy link to clipboard.");
  });
};

export function handleIncomingGameRoute() {
  const params = new URLSearchParams(window.location.search);
  const targetGameId = params.get("gameId") || params.get("id") || params.get("join");
  if (!targetGameId) return;

  const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream;

  if (isIOS) {
    const banner = document.getElementById("ios-app-banner");
    const link = document.getElementById("ios-app-link");
    if (banner && link) {
      link.href = `setgames://game?id=${targetGameId}`;
      banner.style.display = "flex";
      // Gentle attempt to open native iOS app
      setTimeout(() => {
        window.location.href = `setgames://game?id=${targetGameId}`;
      }, 300);
    }
  }

  const checkAndFocusGame = () => {
    const game = state.games.find(g => g.id === targetGameId || g.rawId === targetGameId);
    if (!game) return;

    if (window.switchTab) {
      window.switchTab("matches");
    }

    setTimeout(() => {
      const card = document.getElementById(`match-card-${game.id}`);
      if (card) {
        card.scrollIntoView({ behavior: "smooth", block: "center" });
        card.style.outline = "3px solid #f97316";
        card.style.boxShadow = "0 0 24px rgba(249, 115, 22, 0.4)";
        card.style.transition = "all 0.4s ease";
        setTimeout(() => {
          card.style.outline = "";
          card.style.boxShadow = "";
        }, 4000);
      }

      const allP = [...(game.team1PlayerIds || []), ...(game.team2PlayerIds || [])];
      const isMember = state.currentUser && allP.includes(state.currentUser.id);
      if (!isMember) {
        showToast(`Welcome! Tap '+ Join Player Pool' to join "${game.title}"!`);
      }
    }, 350);
  };

  if (state.games && state.games.length > 0) {
    checkAndFocusGame();
  } else {
    const interval = setInterval(() => {
      if (state.games && state.games.length > 0) {
        clearInterval(interval);
        checkAndFocusGame();
      }
    }, 300);
    setTimeout(() => clearInterval(interval), 5000);
  }
}

// ==========================================
// MATCH CHAT & ETA STATUS HANDLERS
// ==========================================
window.activeChatGameId = null;

window.openMatchChatModal = (gameId) => {
  const game = state.games.find(g => g.id === gameId);
  if (!game) return;

  const currentUserId = state.currentUser ? state.currentUser.id : null;
  const isMember = currentUserId && (
    (game.team1PlayerIds && game.team1PlayerIds.includes(currentUserId)) ||
    (game.team2PlayerIds && game.team2PlayerIds.includes(currentUserId)) ||
    (game.hostPlayerId === currentUserId)
  );

  if (!isMember) {
    showToast("Match Chat is only available to confirmed players in this game.");
    return;
  }

  window.activeChatGameId = gameId;
  const titleEl = document.getElementById("chat-match-title");
  if (titleEl) {
    titleEl.textContent = `${game.title} • ${game.courtLocation}`;
  }
  window.renderChatMessages();
  document.getElementById("match-chat-modal").classList.add("active");
  const input = document.getElementById("chat-input");
  if (input) {
    input.value = "";
    input.focus();
  }
};

window.closeMatchChatModal = () => {
  window.activeChatGameId = null;
  document.getElementById("match-chat-modal").classList.remove("active");
};

window.renderChatMessages = () => {
  const container = document.getElementById("chat-messages-container");
  if (!container || !window.activeChatGameId) return;

  const game = state.games.find(g => g.id === window.activeChatGameId);
  if (!game) return;

  const messages = game.messages || [];
  if (messages.length === 0) {
    container.innerHTML = `<div style="text-align:center; color:var(--text-muted); font-size:12px; margin:auto;">No messages yet.<br>Tap a quick response above or type a message below.</div>`;
    return;
  }

  container.innerHTML = messages.map(m => {
    const isMe = state.currentUser && m.senderId === state.currentUser.id;
    const timeStr = new Date(m.date).toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit" });
    return `
      <div style="display:flex; flex-direction:column; align-items:${isMe ? 'flex-end' : 'flex-start'}; margin-bottom:6px;">
        ${!isMe ? `<span style="font-size:11px; font-weight:700; color:var(--text-muted); margin-bottom:2px; margin-left:4px;">${m.senderName}</span>` : ''}
        <div style="max-width:80%; padding:9px 13px; border-radius:14px; font-size:13.5px; font-weight:500; word-break:break-word; line-height:1.4; ${isMe ? 'background:#ff6a00; color:#ffffff; box-shadow:0 1px 4px rgba(255,106,0,0.3);' : 'background:#ffffff; color:#0f172a; border:1px solid rgba(0,0,0,0.12); box-shadow:0 1px 3px rgba(0,0,0,0.05);'}">
          ${m.text}
        </div>
        <span style="font-size:10px; color:var(--text-muted); margin-top:2px; margin-right:${isMe ? '4px' : '0'}; margin-left:${!isMe ? '4px' : '0'};">${timeStr}</span>
      </div>
    `;
  }).join("");

  container.scrollTop = container.scrollHeight;
};

window.sendQuickChatMessage = (text) => {
  if (!window.activeChatGameId) return;
  window.postChatMessage(window.activeChatGameId, text);
};

window.handleSendChatMessage = (e) => {
  e.preventDefault();
  if (!window.activeChatGameId) return;
  const input = document.getElementById("chat-input");
  const text = input.value.trim();
  if (!text) return;
  input.value = "";
  window.postChatMessage(window.activeChatGameId, text);
};

window.postChatMessage = (gameId, text) => {
  const game = state.games.find(g => g.id === gameId);
  if (!game || !state.currentUser) return;

  if (!game.messages) {
    game.messages = [];
  }

  const senderName = state.currentUser.nickname || state.currentUser.name;
  const newMsg = {
    id: "msg_" + Date.now(),
    senderId: state.currentUser.id,
    senderName: senderName,
    text: text,
    date: new Date().toISOString(),
    origin: "web"
  };

  game.messages.push(newMsg);
  state.saveLocal();
  saveGameToFirestore(game);
  window.renderChatMessages();
  renderMatches();
  showToast(`Sent: "${text}"`);

  // Dispatch APNs push to match participants ($0 Serverless / Local Relay)
  try {
    const currentUid = state.currentUser.id;
    const currentToken = state.currentUser.deviceToken;
    const participantIds = [
      ...(game.team1PlayerIds || []),
      ...(game.team2PlayerIds || []),
      ...(game.waitlistPlayerIds || []),
      ...(game.hostPlayerId ? [game.hostPlayerId] : [])
    ].filter(id => id && id !== currentUid);

    const uniqueIds = Array.from(new Set(participantIds));
    const rawTokens = uniqueIds
      .map(id => state.getPlayer(id)?.deviceToken)
      .filter(t => t && typeof t === "string" && t.trim().length > 0 && t !== currentToken);
    const recipientTokens = Array.from(new Set(rawTokens));

    if (recipientTokens.length > 0) {
      fetch("/api/send-push", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          tokens: recipientTokens,
          title: "🏐 Volleyball Match Alert",
          body: `${senderName} (${game.title || "Match"}): "${text}"`,
          gameId: gameId,
          messageId: newMsg.id
        })
      }).catch(err => console.log("Push note:", err));
    }
  } catch (e) {
    console.warn("APNs push trigger notice:", e);
  }
};

// Rate Match Players (Post-Match 1-5 Stars)
window.openRateMatchModal = (gameId) => {
  const game = state.games.find(g => g.id === gameId);
  if (!game || !state.currentUser) return;

  const userId = state.currentUser.id;
  const peerIds = [...(game.team1PlayerIds || []), ...(game.team2PlayerIds || [])].filter(id => id !== userId);
  const peerPlayers = peerIds.map(id => state.getPlayer(id));

  const container = document.getElementById("rate-players-list");
  if (!container) return;

  if (peerPlayers.length === 0) {
    container.innerHTML = `<div style="text-align:center; color:var(--text-muted);">No other players in this match.</div>`;
  } else {
    container.innerHTML = peerPlayers.map(p => {
      const currentStar = (game.submittedRatings?.[userId]?.[p.id]) || 0;
      const starsHtml = [1, 2, 3, 4, 5].map(s => {
        const isFilled = s <= currentStar;
        return `<button type="button" style="background:none; border:none; font-size:24px; cursor:pointer; color:${isFilled ? '#eab308' : '#cbd5e1'}; padding:2px;" onclick="window.submitStarRating('${game.id}', '${p.id}', ${s})">★</button>`;
      }).join("");

      return `
        <div style="display:flex; align-items:center; justify-content:space-between; padding:12px; background:var(--bg); border-radius:12px; border:1px solid var(--border);">
          <div style="display:flex; align-items:center; gap:10px;">
            ${renderAvatar(p.avatarEmoji, "avatar-sm")}
            <div>
              <div style="font-weight:700; font-size:14px;">${p.nickname || p.name}</div>
              <div style="font-size:12px; color:var(--text-muted);">Overall: ⭐ ${formatStarRating(p)}</div>
            </div>
          </div>
          <div>${starsHtml}</div>
        </div>
      `;
    }).join("");
  }

  document.getElementById("rate-match-modal").classList.add("active");
};

window.closeRateMatchModal = () => {
  const modal = document.getElementById("rate-match-modal");
  if (modal) modal.classList.remove("active");
};

window.submitStarRating = (gameId, targetId, stars) => {
  const game = state.games.find(g => g.id === gameId);
  const targetPlayer = state.players.find(p => p.id === targetId);
  if (!game || !targetPlayer || !state.currentUser) return;

  if (!game.submittedRatings) game.submittedRatings = {};
  if (!game.submittedRatings[state.currentUser.id]) game.submittedRatings[state.currentUser.id] = {};

  game.submittedRatings[state.currentUser.id][targetId] = stars;
  targetPlayer.starRatingSum = (targetPlayer.starRatingSum || 0) + stars;
  targetPlayer.starRatingCount = (targetPlayer.starRatingCount || 0) + 1;

  state.saveLocal();
  saveGameToFirestore(game);
  savePlayerToFirestore(targetPlayer);

  window.openRateMatchModal(gameId); // Refresh modal view
  renderMatches();
  renderProfile();
  showToast(`Submitted rating of ${stars} ⭐ for ${targetPlayer.name}!`);
};

// Score Entry (Participants)
window.openScoreModal = (gameId) => {
  const game = state.games.find(g => g.id === gameId);
  if (!game) return;
  const isMember = state.currentUser && (
    game.team1PlayerIds?.includes(state.currentUser.id) ||
    game.team2PlayerIds?.includes(state.currentUser.id) ||
    game.hostPlayerId === state.currentUser.id
  );
  if (!isMember) {
    showToast("Only match participants can record scores.");
    return;
  }

  const modal = document.getElementById("score-modal");
  document.getElementById("score-game-id").value = gameId;
  document.getElementById("score-game-title").textContent = game.title;
  modal.classList.add("active");
};

window.closeScoreModal = () => {
  document.getElementById("score-modal").classList.remove("active");
};

window.submitScoreForm = (e) => {
  e.preventDefault();
  const gameId = document.getElementById("score-game-id").value;
  const winnerTeam = parseInt(document.getElementById("winning-team-select").value);
  const s1 = document.getElementById("score-set1").value.trim();
  const s2 = document.getElementById("score-set2").value.trim();
  const s3 = document.getElementById("score-set3").value.trim();

  const game = state.games.find(g => g.id === gameId);
  if (!game) return;

  const setScores = [s1, s2, s3].filter(s => s.length > 0);
  game.status = "completed";
  game.winnerTeam = winnerTeam;
  game.setScores = setScores;

  // Award win/loss stats
  const winners = winnerTeam === 1 ? game.team1PlayerIds : game.team2PlayerIds;
  const losers = winnerTeam === 1 ? game.team2PlayerIds : game.team1PlayerIds;

  winners.forEach(pid => {
    const p = state.players.find(x => x.id === pid);
    if (p) {
      p.wins += 1;
      p.streak = p.streak > 0 ? p.streak + 1 : 1;
      p.eloRating += 25;
      p.consecutiveBackouts = 0; // Reset flaker backout streak upon match completion
      savePlayerToFirestore(p);
    }
  });

  losers.forEach(pid => {
    const p = state.players.find(x => x.id === pid);
    if (p) {
      p.losses += 1;
      p.streak = p.streak < 0 ? p.streak - 1 : -1;
      p.eloRating = Math.max(1000, p.eloRating - 20);
      p.consecutiveBackouts = 0; // Reset flaker backout streak upon match completion
      savePlayerToFirestore(p);
    }
  });

  if (state.currentUser && (winners.includes(state.currentUser.id) || losers.includes(state.currentUser.id))) {
    state.currentUser.consecutiveBackouts = 0;
  }

  // Automatically delete the match and its messages when completed
  state.games = state.games.filter(g => g.id !== gameId);
  state.saveLocal();
  deleteGameFromFirestore(gameId);
  window.closeScoreModal();
  renderMatches();
  renderLadder();
  renderPopularKids();
  renderHeader();
  showToast("Match complete! Scores recorded, stats updated, and match cleared.");
};

window.handleSaveProfile = (e) => {
  e.preventDefault();
  const name = document.getElementById("profile-name").value.trim();
  const nickname = document.getElementById("profile-nickname").value.trim();
  const rating = document.getElementById("profile-rating").value;
  const homeBeach = document.getElementById("profile-beach").value;
  const selectedAvatarBtn = document.querySelector(".avatar-btn.selected");
  const avatarEmoji = selectedAvatarBtn ? selectedAvatarBtn.dataset.avatar : "slug";

  if (!name) return;

  if (state.currentUser) {
    state.currentUser.name = name;
    state.currentUser.nickname = nickname;
    state.currentUser.rating = rating;
    state.currentUser.homeBeach = homeBeach;
    state.currentUser.avatarEmoji = avatarEmoji;
  } else {
    const newPlayer = {
      id: "player-" + Date.now(),
      name,
      nickname,
      rating,
      eloRating: rating === "AA" ? 2100 : rating === "A" ? 1800 : rating === "B" ? 1550 : 1350,
      homeBeach,
      avatarEmoji,
      wins: 0,
      losses: 0,
      streak: 0,
      pointsScored: 0,
      pointsAllowed: 0,
      uniquePartnerIds: [],
      uniqueOpponentIds: []
    };
    state.players.push(newPlayer);
    state.currentUser = newPlayer;
  }

  state.saveLocal();
  savePlayerToFirestore(state.currentUser);
  renderHeader();
  showToast("Profile saved & synchronized with community!");
  switchTab("matches");
};

window.toggleDemoMode = (enabled) => {
  if (!isRootUser(state.currentUser)) {
    showToast("Only 4087869405 can enable demo mode.");
    return;
  }
  state.isDemoModeEnabled = Boolean(enabled);
  state.saveLocal();
  renderProfile();
  const demoBox = document.getElementById("quick-demo-accounts-box");
  if (demoBox) demoBox.style.display = state.isDemoModeEnabled ? "block" : "none";
  showToast(state.isDemoModeEnabled ? "Demo Mode enabled" : "Demo Mode disabled");
};

window.handleSwitchUser = () => {
  if (!isRootUser(state.currentUser) && !state.isDemoModeEnabled) {
    showToast("Only 4087869405 can enable demo mode.");
    return;
  }
  const select = document.getElementById("switch-user-select");
  const player = state.players.find(p => p.id === select.value);
  if (player) {
    state.currentUser = player;
    state.saveLocal();
    renderHeader();
    renderProfile();
    renderMatches();
    renderAvailabilityWindows();
    showToast(`Switched active profile to ${player.name}`);
  }
};

// ==========================================
// AUTO-MATCHMAKER (Matches iOS AutoMatchmakerView.swift & MatchmakingEngine.swift)
// ==========================================

const MM_OPTIONS = {
  smartAvailability: {
    tag: "RECOMMENDED",
    icon: "🗓️",
    title: "Smart Availability Matcher",
    sub: "Set recurring or upcoming free windows. The engine pairs 4 players of compatible tier and auto-confirms the match.",
    color: "#ea580c"
  },
  instantQueue: {
    tag: "FASTEST",
    icon: "⚡️",
    title: "Quick-Play Lobby",
    sub: "Drop into today's live morning or sunset waves. Fills 4-player lobbies and alerts you once full.",
    color: "#0284c7"
  },
  kingOfTheBeach: {
    tag: "ROTATING 2V2",
    icon: "👑",
    title: "King of the Beach (Solo Queue)",
    sub: "No partner required! 4 players rotate partners across 3 sets. Individual win/loss record tracked.",
    color: "#9333ea"
  },
  openBoard: {
    tag: "DYNAMIC",
    icon: "✨",
    title: "Open Court Compatibility Fill",
    sub: "Matches you with existing games missing 1 player based on 0-100% skill & schedule compatibility.",
    color: "#0d9488"
  }
};

window.selectedMatchmakerOption = "smartAvailability";

window.switchMatchmakerOption = (option) => {
  window.selectedMatchmakerOption = option;
  const config = MM_OPTIONS[option] || MM_OPTIONS.smartAvailability;

  document.querySelectorAll(".matchmaker-pill").forEach(pill => {
    pill.classList.toggle("active", pill.dataset.option === option);
  });

  const tag = document.getElementById("mm-banner-tag");
  const icon = document.getElementById("mm-banner-icon");
  const title = document.getElementById("mm-banner-title");
  const sub = document.getElementById("mm-banner-sub");

  if (tag) {
    tag.textContent = config.tag;
    tag.style.color = config.color;
    tag.style.background = `${config.color}22`;
  }
  if (icon) icon.textContent = config.icon;
  if (title) title.textContent = config.title;
  if (sub) sub.textContent = config.sub;

  document.querySelectorAll(".mm-section").forEach(sec => {
    sec.style.display = (sec.id === `mm-section-${option}`) ? "block" : "none";
  });

  if (option === "smartAvailability") renderAvailabilityWindows();
  if (option === "instantQueue") renderPickupQueue();
  if (option === "openBoard") renderOpenGames();
};

window.openAddAvailabilityModal = () => {
  if (!state.currentUser) {
    window.showAuthModal();
    return;
  }
  const modal = document.getElementById("add-availability-modal");
  const dateInput = document.getElementById("avail-date");
  if (dateInput && !dateInput.value) {
    const tomorrow = new Date(Date.now() + 86400000);
    dateInput.value = tomorrow.toISOString().split("T")[0];
  }
  if (modal) modal.classList.add("active");
};

window.closeAddAvailabilityModal = () => {
  const modal = document.getElementById("add-availability-modal");
  if (modal) modal.classList.remove("active");
};

// ==========================================================================
// INSTANT PICKUP LOBBY (Matches iOS InstantPickupSheet.swift)
// ==========================================================================
state.selectedPickupBeach = state.selectedPickupBeach || "Main Beach";
state.beachPickupQueues = state.beachPickupQueues || { "Main Beach": [], "Harbor Beach": [] };

window.openInstantPickupModal = () => {
  const modal = document.getElementById("instant-pickup-modal");
  if (modal) {
    modal.classList.add("active");
    window.renderInstantPickupModal();
  }
};

window.closeInstantPickupModal = () => {
  const modal = document.getElementById("instant-pickup-modal");
  if (modal) modal.classList.remove("active");
};

window.switchPickupBeach = (beach) => {
  state.selectedPickupBeach = beach;
  window.renderInstantPickupModal();
};

window.renderInstantPickupModal = () => {
  const beach = state.selectedPickupBeach || "Main Beach";
  state.beachPickupQueues = state.beachPickupQueues || { "Main Beach": [], "Harbor Beach": [] };
  const queue = state.beachPickupQueues[beach] || [];

  // Update beach selector pills
  const mainPill = document.getElementById("ip-beach-main");
  const harborPill = document.getElementById("ip-beach-harbor");
  if (mainPill) mainPill.classList.toggle("active", beach === "Main Beach");
  if (harborPill) harborPill.classList.toggle("active", beach === "Harbor Beach");

  // Update pill counts
  const mainCount = (state.beachPickupQueues["Main Beach"] || []).length;
  const harborCount = (state.beachPickupQueues["Harbor Beach"] || []).length;
  const mainBadge = document.getElementById("ip-count-main");
  const harborBadge = document.getElementById("ip-count-harbor");
  if (mainBadge) {
    mainBadge.style.display = mainCount > 0 ? "inline-block" : "none";
    mainBadge.textContent = mainCount;
  }
  if (harborBadge) {
    harborBadge.style.display = harborCount > 0 ? "inline-block" : "none";
    harborBadge.textContent = harborCount;
  }

  // Update Title & Badge
  const title = document.getElementById("ip-queue-beach-title");
  if (title) title.textContent = `Today's ${beach} Queue`;

  const badge = document.getElementById("ip-queue-count-badge");
  if (badge) badge.textContent = `${queue.length} / 4 Players`;

  // Update Progress Bar
  const progressBar = document.getElementById("ip-queue-progress-bar");
  if (progressBar) {
    progressBar.style.width = `${Math.min(100, (queue.length / 4) * 100)}%`;
  }

  // Render 4 Spots
  const container = document.getElementById("ip-spots-container");
  if (container) {
    let html = "";
    for (let i = 0; i < 4; i++) {
      if (i < queue.length) {
        const p = state.getPlayer(queue[i]);
        const avatar = p ? (p.avatarEmoji || "🏐") : "🏐";
        const nick = p ? (p.nickname || p.name) : `Player ${i + 1}`;
        const isMe = state.currentUser && state.currentUser.id === queue[i];
        html += `
          <button type="button" class="ip-spot-card" onclick="window.removeInstantPickupPlayer(${i})" title="Click to remove">
            <div class="ip-spot-circle filled">
              <span>${avatar}</span>
              <span class="ip-remove-badge">&times;</span>
            </div>
            <div class="ip-spot-label">${isMe ? "You" : nick}</div>
          </button>
        `;
      } else {
        html += `
          <button type="button" class="ip-spot-card" onclick="window.handleInstantPickupSpotClick(${i})" title="Click to join Spot ${i + 1}">
            <div class="ip-spot-circle empty">+</div>
            <div class="ip-spot-label">Spot ${i + 1}</div>
          </button>
        `;
      }
    }
    container.innerHTML = html;
  }

  // Update Toggle Button
  const toggleBtn = document.getElementById("ip-queue-toggle-btn");
  if (toggleBtn) {
    const inQueue = state.currentUser && queue.includes(state.currentUser.id);
    if (inQueue) {
      toggleBtn.innerHTML = "<span>✕</span><span>Leave Matchmaking Queue</span>";
      toggleBtn.style.background = "#dc2626";
    } else {
      toggleBtn.innerHTML = "<span>⚡️</span><span>Enter Matchmaking Queue</span>";
      toggleBtn.style.background = "#0284c7";
    }
  }

  // Update Auto-Fill Button Text & Visibility (Admin only)
  const autoBtn = document.getElementById("ip-queue-autofill-btn");
  if (autoBtn) {
    const isRoot = isRootUser(state.currentUser);
    if (!isRoot) {
      autoBtn.style.display = "none";
    } else {
      autoBtn.style.display = "block";
      autoBtn.innerHTML = queue.length === 0 ? "<span>👥</span><span>Quick-Fill 4 Players (Test)</span>" : "<span>👥</span><span>Auto-Fill Remaining Spots</span>";
    }
  }

  // Update One-Line Weather Snapshot for Main and Harbor
  const weatherEl = document.getElementById("ip-weather-snapshot-text");
  if (weatherEl) {
    const now = new Date();
    const mainW = weatherService.getCached("Main Beach", now) || weatherService.getFallback("Main Beach", now);
    const harborW = weatherService.getCached("Harbor Beach", now) || weatherService.getFallback("Harbor Beach", now);

    const mTemp = mainW ? mainW.tempF : 73;
    const mUV = mainW ? Math.round(mainW.uvIndex) : 5;
    const mWind = mainW ? mainW.windMph : 13;

    const hTemp = harborW ? harborW.tempF : 73;
    const hUV = harborW ? Math.round(harborW.uvIndex) : 5;
    const hWind = harborW ? harborW.windMph : 10;

    weatherEl.textContent = `Main: ${mTemp}F, UV-${mUV}, ${mWind}mph. Harbor: ${hTemp}F, UV-${hUV}, ${hWind}mph`;

    weatherService.getForecast("Main Beach", now).then(() => {
      weatherService.getForecast("Harbor Beach", now).then(() => {
        const m = weatherService.getCached("Main Beach", now);
        const h = weatherService.getCached("Harbor Beach", now);
        const el = document.getElementById("ip-weather-snapshot-text");
        if (m && h && el) {
          el.textContent = `Main: ${m.tempF}F, UV-${Math.round(m.uvIndex)}, ${m.windMph}mph. Harbor: ${h.tempF}F, UV-${Math.round(h.uvIndex)}, ${h.windMph}mph`;
        }
      });
    });
  }
};

window.handleInstantPickupSpotClick = (index) => {
  const beach = state.selectedPickupBeach || "Main Beach";
  state.beachPickupQueues = state.beachPickupQueues || { "Main Beach": [], "Harbor Beach": [] };
  const queue = state.beachPickupQueues[beach] || [];

  if (!state.currentUser) {
    window.showAuthModal();
    return;
  }

  const inQueue = queue.includes(state.currentUser.id);
  if (!inQueue) {
    queue.push(state.currentUser.id);
    state.beachPickupQueues[beach] = queue;
    state.saveLocal();
    showToast(`Joined ${beach} queue (${queue.length}/4)`);
    window.renderInstantPickupModal();
    if (queue.length >= 4) {
      window.handleInstantPickupFilled(beach);
    }
  } else {
    // Already in queue: fill spot with next available player
    const available = (state.players || []).filter(p => !queue.includes(p.id));
    if (available.length > 0) {
      const p = available[0];
      queue.push(p.id);
      state.beachPickupQueues[beach] = queue;
      state.saveLocal();
      showToast(`Added ${p.name} to ${beach} queue (${queue.length}/4)`);
      window.renderInstantPickupModal();
      if (queue.length >= 4) {
        window.handleInstantPickupFilled(beach);
      }
    } else {
      showToast("All available players are already in queue!");
    }
  }
};

window.removeInstantPickupPlayer = (index) => {
  const beach = state.selectedPickupBeach || "Main Beach";
  state.beachPickupQueues = state.beachPickupQueues || { "Main Beach": [], "Harbor Beach": [] };
  const queue = state.beachPickupQueues[beach] || [];
  if (index >= 0 && index < queue.length) {
    const removedId = queue.splice(index, 1)[0];
    state.beachPickupQueues[beach] = queue;
    state.saveLocal();
    const p = state.getPlayer(removedId);
    showToast(`Removed ${p ? p.name : "player"} from queue.`);
    window.renderInstantPickupModal();
  }
};

window.toggleInstantPickupQueue = () => {
  if (!state.currentUser) {
    window.showAuthModal();
    return;
  }
  const beach = state.selectedPickupBeach || "Main Beach";
  state.beachPickupQueues = state.beachPickupQueues || { "Main Beach": [], "Harbor Beach": [] };
  const queue = state.beachPickupQueues[beach] || [];
  const uid = state.currentUser.id;
  const inQueue = queue.includes(uid);

  if (inQueue) {
    state.beachPickupQueues[beach] = queue.filter(id => id !== uid);
    showToast(`Left ${beach} matchmaking queue.`);
  } else {
    queue.push(uid);
    state.beachPickupQueues[beach] = queue;
    showToast(`Entered ${beach} matchmaking queue (${queue.length}/4)`);
  }
  state.saveLocal();
  window.renderInstantPickupModal();

  if (state.beachPickupQueues[beach].length >= 4) {
    window.handleInstantPickupFilled(beach);
  }
};

window.fillInstantPickupQueue = () => {
  if (!isRootUser(state.currentUser)) {
    showToast("Quick-Fill is only available for admins.");
    return;
  }
  const beach = state.selectedPickupBeach || "Main Beach";
  state.beachPickupQueues = state.beachPickupQueues || { "Main Beach": [], "Harbor Beach": [] };
  const queue = state.beachPickupQueues[beach] || [];

  if (state.currentUser && !queue.includes(state.currentUser.id)) {
    queue.push(state.currentUser.id);
  }

  const available = (state.players || []).filter(p => !queue.includes(p.id));
  for (const p of available) {
    if (queue.length >= 4) break;
    queue.push(p.id);
  }

  state.beachPickupQueues[beach] = queue;
  state.saveLocal();
  window.renderInstantPickupModal();

  if (queue.length >= 4) {
    window.handleInstantPickupFilled(beach);
  } else {
    showToast(`Queue updated (${queue.length}/4). Need more players.`);
  }
};

window.handleInstantPickupFilled = (beach) => {
  const queue = state.beachPickupQueues[beach] || [];
  const players = queue.splice(0, 4);
  state.beachPickupQueues[beach] = queue;

  const targetRating = state.currentUser ? (state.currentUser.rating || "B") : "B";
  const fastGame = {
    id: "pickup-" + Date.now(),
    title: "Instant Pickup 2v2",
    targetRating: targetRating,
    courtLocation: beach,
    courtNumber: "Court #1",
    scheduledDate: new Date(Date.now() + 1800000).toISOString(),
    status: "scheduled",
    isAutoMatched: true,
    matchedOptionName: "Quick-Play Lobby",
    team1PlayerIds: [players[0], players[3]],
    team2PlayerIds: [players[1], players[2]],
    team1Score: 0,
    team2Score: 0,
    setScores: []
  };

  state.games.unshift(fastGame);
  state.saveLocal();
  saveGameToFirestore(fastGame);

  window.closeInstantPickupModal();
  switchTab("matches");

  triggerWebPushNotification("⚡️ Pickup Lobby Full (4/4)!", `Your instant pickup game at ${beach} is locked and starting soon!`);
  showToast(`⚡️ Pickup lobby full! Game scheduled at ${beach}! Taking you to Game Details...`);

  setTimeout(() => {
    const card = document.getElementById(`match-card-${fastGame.id}`);
    if (card) {
      card.scrollIntoView({ behavior: "smooth", block: "center" });
      card.style.outline = "3px solid #0284c7";
      card.style.boxShadow = "0 0 16px rgba(2, 132, 199, 0.4)";
      setTimeout(() => {
        card.style.outline = "";
        card.style.boxShadow = "";
      }, 3000);
    }
  }, 400);
};

window.handleCreateKingOfBeach = () => {
  if (!state.currentUser) {
    window.showAuthModal();
    return;
  }
  const user = state.currentUser;
  const opponents = (state.players || []).filter(p => p.id !== user.id).sort(() => 0.5 - Math.random()).slice(0, 3);
  if (opponents.length < 3) {
    showToast("Need at least 3 other players in the community to form a King of the Beach rotation.");
    return;
  }
  const allFour = [user, ...opponents];
  const kingGame = {
    id: "king-" + Date.now(),
    title: "King of the Beach Session",
    targetRating: user.rating || "B",
    format: "kingOfTheBeach",
    status: "scheduled",
    scheduledDate: new Date(Date.now() + 3 * 3600000).toISOString(),
    courtLocation: user.homeBeach || "Main Beach",
    courtNumber: "Court #1",
    team1PlayerIds: [allFour[0].id, allFour[1].id],
    team2PlayerIds: [allFour[2].id, allFour[3].id],
    team1Score: 0,
    team2Score: 0,
    isAutoMatched: true,
    matchedOptionName: "King of the Beach",
    notes: "Individual 4-player rotation across 3 sets."
  };
  state.games.unshift(kingGame);
  state.saveLocal();
  saveGameToFirestore(kingGame);
  showToast(`Created King of the Beach 4-player rotation with ${opponents.map(p => p.nickname || p.name).join(", ")}!`);
  switchTab("matches");
};

export function calculateCompatibility(player, game) {
  if (!player || !game) return 85;
  const tierScores = {
    novice: 1, nov: 1,
    intermediate: 2, int: 2,
    b: 3,
    a: 4,
    aa: 5,
    open: 6
  };
  const playerLevel = tierScores[(player.rating || "B").toLowerCase()] || 3;
  const allowed = (game.allowedRatings && game.allowedRatings.length > 0) ? game.allowedRatings : [game.targetRating || "B"];
  const allowedLevels = allowed.map(r => tierScores[(r || "B").toLowerCase()] || 3);
  const diffs = allowedLevels.map(l => Math.abs(playerLevel - l));
  const minDiff = Math.min(...diffs);

  let score = 100;
  if (minDiff === 0) score = 98;
  else if (minDiff === 1) score = 82;
  else if (minDiff === 2) score = 55;
  else score = 25;

  const spotsRemaining = Math.max(0, (game.maxPlayers || 4) - ((game.team1PlayerIds || []).length + (game.team2PlayerIds || []).length));
  if (spotsRemaining === 1) {
    score = Math.min(100, score + 2);
  }
  return score;
}

export function renderOpenGames() {
  const container = document.getElementById("open-games-list");
  if (!container) return;

  const openGames = (state.games || []).filter(g => {
    const maxP = g.maxPlayers || 4;
    const currentP = (g.team1PlayerIds || []).length + (g.team2PlayerIds || []).length;
    return g.status === "scheduled" && currentP < maxP;
  });

  if (openGames.length === 0) {
    container.innerHTML = `
      <div class="match-card" style="text-align: center; padding: 24px 16px; color: var(--text-muted);">
        <div style="font-weight: 700; font-size: 14px; color: #0f172a; margin-bottom: 4px;">All scheduled games are currently full!</div>
        <div style="font-size: 12px;">Use Option A or B above to auto-create a new set.</div>
      </div>
    `;
    return;
  }

  container.innerHTML = openGames.map(game => {
    const compat = state.currentUser ? calculateCompatibility(state.currentUser, game) : 85;
    const maxP = game.maxPlayers || 4;
    const currentP = (game.team1PlayerIds || []).length + (game.team2PlayerIds || []).length;
    const missing = Math.max(0, maxP - currentP);
    let dateFormatted = "Upcoming";
    try {
      const d = parseGameDate(game.scheduledDate);
      dateFormatted = d.toLocaleDateString("en-US", { weekday: "short", month: "short", day: "numeric" }) + " at " + d.toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit" });
    } catch (e) {
      dateFormatted = String(game.scheduledDate || "Upcoming");
    }
    const targetRating = game.targetRating || "B";
    const compatColor = compat >= 80 ? "#16a34a" : "#ea580c";
    const compatBg = compat >= 80 ? "rgba(22, 163, 74, 0.12)" : "rgba(234, 88, 12, 0.12)";

    return `
      <div class="match-card" style="margin-bottom: 12px; padding: 14px;">
        <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 8px;">
          <div>
            <div style="font-size: 16px; font-weight: 800; color: #0f172a;">${game.title}</div>
            <div style="font-size: 12px; color: var(--text-muted); margin-top: 2px;">📅 ${dateFormatted}</div>
          </div>
          <div style="text-align: right; background: ${compatBg}; padding: 4px 8px; border-radius: 8px;">
            <div style="font-size: 11px; font-weight: 900; color: ${compatColor};">${compat}% MATCH</div>
            <div style="font-size: 9px; color: var(--text-muted);">Rating & Schedule</div>
          </div>
        </div>

        <div style="display: flex; justify-content: space-between; align-items: center; font-size: 12px; margin-bottom: 12px;">
          <div style="color: var(--text-muted); font-weight: 600;">📍 ${game.courtLocation || "Main Beach"} • ${game.courtNumber || "Court #1"}</div>
          <span class="badge" style="background: var(--accent-light); color: var(--accent); font-weight: 800; font-size: 11px;">${targetRating}</span>
        </div>

        <div style="display: flex; justify-content: space-between; align-items: center; border-top: 1px solid var(--border); padding-top: 10px;">
          <div style="font-size: 12px; font-weight: 700; color: #ea580c;">Missing: ${missing} Player(s)</div>
          <button type="button" class="btn btn-sm" style="background: #0d9488; color: #fff; font-weight: 700; border-radius: 999px; padding: 6px 14px; font-size: 12px;" onclick="window.handleAutoFillOpenGame('${game.id}')">
            Auto-Fill & Join
          </button>
        </div>
      </div>
    `;
  }).join("");
}

window.handleAutoFillOpenGame = (gameId) => {
  if (!state.currentUser) {
    window.showAuthModal();
    return;
  }
  const uid = state.currentUser.id;
  const game = (state.games || []).find(g => g.id === gameId);
  if (!game) return;

  const t1 = game.team1PlayerIds || [];
  const t2 = game.team2PlayerIds || [];
  if (t1.includes(uid) || t2.includes(uid)) {
    showToast("You are already in this game!");
    return;
  }
  if (t1.length < 2) {
    t1.push(uid);
    game.team1PlayerIds = t1;
  } else if (t2.length < 2) {
    t2.push(uid);
    game.team2PlayerIds = t2;
  } else {
    showToast("This game is already full.");
    return;
  }
  state.saveLocal();
  saveGameToFirestore(game);
  showToast(`You joined ${game.title} at ${game.courtLocation}!`);
  renderOpenGames();
  renderMatches();
};

window.handleRunAutoMatch = () => {
  if (!state.currentUser) {
    window.showAuthModal();
    return;
  }
  const slots = state.availabilitySlots || [];
  const players = state.players || [];
  const playerLookup = new Map(players.map(p => [p.id, p]));

  const tierScores = {
    novice: 1, nov: 1,
    intermediate: 2, int: 2,
    b: 3,
    a: 4,
    aa: 5,
    open: 6
  };
  const tierFromScore = (score) => {
    if (score <= 1) return "Novice";
    if (score === 2) return "Intermediate";
    if (score === 3) return "B";
    if (score === 4) return "A";
    if (score === 5) return "AA";
    return "Open";
  };

  const slotsByDayBeach = new Map();
  for (const slot of slots) {
    if (slot.isMatched) continue;
    const dateStr = (slot.date || "").split("T")[0];
    const key = `${dateStr}_${slot.preferredBeach || "Main Beach"}`;
    if (!slotsByDayBeach.has(key)) slotsByDayBeach.set(key, []);
    slotsByDayBeach.get(key).push(slot);
  }

  let addedCount = 0;
  for (const [key, groupSlots] of slotsByDayBeach) {
    if (groupSlots.length < 4) continue;

    const sortedSlots = [...groupSlots].sort((s1, s2) => {
      const p1 = playerLookup.get(s1.playerId);
      const p2 = playerLookup.get(s2.playerId);
      const l1 = tierScores[(p1?.rating || "B").toLowerCase()] || 3;
      const l2 = tierScores[(p2?.rating || "B").toLowerCase()] || 3;
      return l1 - l2;
    });

    let index = 0;
    while (index + 3 < sortedSlots.length) {
      const candidateSlots = sortedSlots.slice(index, index + 4);
      const candidatePlayers = candidateSlots.map(s => playerLookup.get(s.playerId)).filter(Boolean);

      if (candidatePlayers.length === 4) {
        const scores = candidatePlayers.map(p => tierScores[(p.rating || "B").toLowerCase()] || 3);
        const minScore = Math.min(...scores);
        const maxScore = Math.max(...scores);

        if (maxScore - minScore <= 2) {
          const sortedByElo = [...candidatePlayers].sort((a, b) => (b.eloRating || 1500) - (a.eloRating || 1500));
          const avgLevel = Math.round(scores.reduce((a, b) => a + b, 0) / 4);
          const matchedTier = tierFromScore(avgLevel);

          const autoGame = {
            id: "match-" + Date.now() + "-" + Math.random().toString(36).substr(2, 4),
            title: `${matchedTier} Beach Doubles Set`,
            targetRating: matchedTier,
            format: "bestOfThree",
            status: "scheduled",
            scheduledDate: candidateSlots[0].startTime || candidateSlots[0].date,
            courtLocation: candidateSlots[0].preferredBeach || "Main Beach",
            courtNumber: `Court #${Math.floor(Math.random() * 6) + 1}`,
            team1PlayerIds: [sortedByElo[0].id, sortedByElo[3].id],
            team2PlayerIds: [sortedByElo[1].id, sortedByElo[2].id],
            isAutoMatched: true,
            matchedOptionName: "Smart Availability Matcher",
            team1Score: 0,
            team2Score: 0,
            setScores: []
          };
          state.games.unshift(autoGame);
          saveGameToFirestore(autoGame);
          addedCount++;

          const matchedIds = new Set(candidatePlayers.map(p => p.id));
          for (const s of state.availabilitySlots) {
            if (matchedIds.has(s.playerId) && !s.isMatched) {
              s.isMatched = true;
              saveSlotToFirestore(s);
            }
          }
          index += 4;
          continue;
        }
      }
      index += 1;
    }
  }

  state.saveLocal();
  renderAvailabilityWindows();
  if (addedCount > 0) {
    showToast(`Successfully matched ${addedCount} balanced set game(s)!`);
  } else {
    showToast("No full 4-player match found yet. Add more availability windows.");
  }
};

export function deduplicateSlots(slots) {
  if (!Array.isArray(slots)) return [];
  const seenIds = new Set();
  const seenKeys = new Set();
  const result = [];

  for (const s of slots) {
    if (!s) continue;
    if (s.id && seenIds.has(s.id)) continue;

    const dateClean = typeof s.date === "string" ? s.date.split("T")[0] : "";
    let startClean = typeof s.startTime === "string" ? s.startTime : "";
    if (startClean.includes("T")) {
      try {
        const d = new Date(startClean);
        if (!isNaN(d.getTime())) {
          startClean = d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", hour12: false });
        }
      } catch (e) {}
    }
    let endClean = typeof s.endTime === "string" ? s.endTime : "";
    if (endClean.includes("T")) {
      try {
        const d = new Date(endClean);
        if (!isNaN(d.getTime())) {
          endClean = d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", hour12: false });
        }
      } catch (e) {}
    }

    const playerKey = s.rawPlayerId || s.playerId || "";
    const beachKey = (s.preferredBeach || "Main Beach").trim().toLowerCase();
    const compositeKey = `${playerKey}|${dateClean}|${startClean}|${endClean}|${beachKey}`;

    if (seenKeys.has(compositeKey)) {
      // Duplicate slot found! Clean up from Firestore in background if id exists
      if (s.id) {
        deleteSlotFromFirestore(s.id).catch(() => {});
      }
      continue;
    }

    if (s.id) seenIds.add(s.id);
    seenKeys.add(compositeKey);
    result.push(s);
  }
  return result;
}
window.deduplicateSlots = deduplicateSlots;

export function renderAvailabilityWindows() {
  const container = document.getElementById("avail-slots-list");
  const countEl = document.getElementById("avail-slots-count");
  const titleEl = document.getElementById("avail-slots-title");
  if (!container) return;

  // Ensure state slots are deduplicated
  state.availabilitySlots = deduplicateSlots(state.availabilitySlots || []);

  const currentUser = state.currentUser;
  if (!currentUser) {
    if (countEl) countEl.textContent = "0";
    container.innerHTML = `
      <div style="text-align: center; color: var(--text-muted); font-size: 13px; padding: 24px 0;">
        <div style="font-size: 28px; margin-bottom: 6px;">🔒</div>
        <div style="font-weight: 700; color: #0f172a; margin-bottom: 4px;">Log In Required</div>
        <div style="font-size: 12px; margin-bottom: 12px;">Log in or create an account to post your availability and get auto-matched.</div>
        <button type="button" class="btn btn-primary btn-sm" onclick="window.showAuthModal()">Log In / Sign Up</button>
      </div>
    `;
    return;
  }

  const isRoot = isRootUser(currentUser);
  if (titleEl) {
    titleEl.textContent = isRoot ? `ALL COMMUNITY AVAILABILITY WINDOWS (${visibleSlotsLength(currentUser, isRoot)})` : `YOUR ACTIVE AVAILABILITY WINDOWS (${visibleSlotsLength(currentUser, isRoot)})`;
  }

  const slots = state.availabilitySlots;
  const visibleSlots = slots.filter(s => {
    if (isRoot) return true;
    return currentUser && (s.playerId === currentUser.id || (currentUser.phoneNumber && s.playerId === currentUser.phoneNumber));
  });

  if (countEl) countEl.textContent = `${visibleSlots.length}`;

  if (visibleSlots.length === 0) {
    container.innerHTML = `
      <div style="text-align: center; color: var(--text-muted); font-size: 12px; padding: 14px 0;">
        ${isRoot ? "No community availability windows active." : "No free windows set yet. Tap 'Add Free Window' to tell the engine when you can play."}
      </div>
    `;
    return;
  }

  container.innerHTML = visibleSlots.map(slot => {
    const isOwner = currentUser && (slot.playerId === currentUser.id || (currentUser.phoneNumber && slot.playerId === currentUser.phoneNumber));
    const canDelete = isRoot || isOwner;
    const creator = state.getPlayer(slot.playerId);
    const creatorName = creator ? (creator.nickname || creator.name) : "Player";
    const tiers = (slot.acceptedTiers && slot.acceptedTiers.length > 0) ? slot.acceptedTiers.join(", ") : "All Tiers";

    let dateDisplay = slot.date;
    if (typeof dateDisplay === 'string' && dateDisplay.includes('T')) {
      try {
        const d = new Date(dateDisplay);
        if (!isNaN(d.getTime())) {
          dateDisplay = d.toLocaleDateString(undefined, { weekday: 'short', month: 'short', day: 'numeric' });
        }
      } catch (e) {}
    }

    let startDisplay = slot.startTime;
    if (typeof startDisplay === 'string' && startDisplay.includes('T')) {
      try {
        const s = new Date(startDisplay);
        if (!isNaN(s.getTime())) {
          startDisplay = s.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' });
        }
      } catch (e) {}
    }

    let endDisplay = slot.endTime;
    if (typeof endDisplay === 'string' && endDisplay.includes('T')) {
      try {
        const e = new Date(endDisplay);
        if (!isNaN(e.getTime())) {
          endDisplay = e.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' });
        }
      } catch (e) {}
    }

    return `
      <div class="avail-slot-card" style="display: flex; justify-content: space-between; align-items: center; padding: 10px 12px; background: var(--card-bg, #ffffff); border: 1px solid var(--border, #e2e8f0); border-radius: 10px; margin-bottom: 8px;">
        <div style="display: flex; flex-direction: column; gap: 3px;">
          <div style="display: flex; align-items: center; gap: 6px;">
            <span style="font-weight: 700; font-size: 13px; color: #0f172a;">📅 ${dateDisplay}</span>
            ${slot.isMatched ? '<span style="font-size: 10px; font-weight: 800; background: #dcfce7; color: #15803d; padding: 1px 6px; border-radius: 999px;">MATCHED</span>' : ''}
          </div>
          ${isRoot ? `<div style="font-size: 11px; font-weight: 600; color: #64748b;">👤 Created by: <strong>${creatorName}</strong></div>` : ''}
          <div style="font-size: 12px; color: var(--text-muted);">⏰ ${startDisplay} – ${endDisplay} • 📍 ${slot.preferredBeach || "Main Beach"}</div>
          <div style="font-size: 11px; color: #ea580c; font-weight: 600;">🏐 Skill: ${tiers}</div>
        </div>
        <div>
          ${canDelete ? `
            <button type="button" class="btn btn-sm btn-delete-slot" style="background: #fee2e2; color: #dc2626; border: 1px solid #fca5a5; font-weight: 700; padding: 5px 10px; font-size: 11px; border-radius: 6px; cursor: pointer;" onclick="window.deleteAvailabilitySlot('${slot.id}')">
              🗑️ Delete
            </button>
          ` : ''}
        </div>
      </div>
    `;
  }).join("");
}

function visibleSlotsLength(currentUser, isRoot) {
  const slots = state.availabilitySlots || [];
  return slots.filter(s => {
    if (isRoot) return true;
    return currentUser && (s.playerId === currentUser.id || (currentUser.phoneNumber && s.playerId === currentUser.phoneNumber));
  }).length;
}

window.deleteAvailabilitySlot = async (slotId) => {
  const user = state.currentUser;
  if (!user) {
    showToast("Please log in first.");
    return;
  }
  const slot = (state.availabilitySlots || []).find(s => s.id === slotId);
  if (!slot) {
    showToast("Availability window not found.");
    return;
  }

  const isRoot = isRootUser(user);
  const isOwner = slot.playerId === user.id || (user.phoneNumber && slot.playerId === user.phoneNumber);
  if (!isRoot && !isOwner) {
    showToast("Permission denied: You cannot delete this availability window.");
    return;
  }

  if (!confirm("Are you sure you want to delete this availability window?")) {
    return;
  }

  state.availabilitySlots = (state.availabilitySlots || []).filter(s => s.id !== slotId);
  state.saveLocal();
  renderAvailabilityWindows();
  await deleteSlotFromFirestore(slotId);
  showToast("Availability window deleted.");
};
window.handleDeleteSlot = window.deleteAvailabilitySlot;

let isSavingAvailability = false;

window.handleSaveAvailability = async (e) => {
  if (e) {
    e.preventDefault();
    if (e.stopPropagation) e.stopPropagation();
  }
  if (isSavingAvailability) return;
  isSavingAvailability = true;

  const submitBtn = document.getElementById("avail-submit-btn");
  if (submitBtn) {
    submitBtn.disabled = true;
    submitBtn.textContent = "Saving...";
  }

  try {
    if (!state.currentUser) {
      showToast("Please log in to post an availability window.");
      return;
    }

    const date = document.getElementById("avail-date").value;
    const start = document.getElementById("avail-start").value;
    const end = document.getElementById("avail-end").value;
    let beach = document.getElementById("avail-beach").value;
    if (beach === "Custom Court") {
      const custom = document.getElementById("avail-custom-beach")?.value?.trim();
      beach = custom || "Custom Court";
    }

    const checkedTiers = Array.from(document.querySelectorAll("input[name='avail-tier']:checked")).map(el => el.value);

    // Guard against duplicate slots (same player, date, startTime, endTime, preferredBeach)
    const isDuplicate = (state.availabilitySlots || []).some(s => {
      const isSamePlayer = (s.playerId === state.currentUser.id) || (state.currentUser.phoneNumber && s.playerId === state.currentUser.phoneNumber);
      const isSameDate = (s.date === date || (typeof s.date === "string" && s.date.startsWith(date)));
      const isSameStart = s.startTime === start;
      const isSameEnd = s.endTime === end;
      const isSameBeach = (s.preferredBeach || "Main Beach").trim().toLowerCase() === (beach || "Main Beach").trim().toLowerCase();
      return isSamePlayer && isSameDate && isSameStart && isSameEnd && isSameBeach;
    });

    if (isDuplicate) {
      showToast("This availability window is already added.");
      window.closeAddAvailabilityModal();
      return;
    }

    const slot = {
      id: (typeof crypto !== "undefined" && crypto.randomUUID) ? crypto.randomUUID() : ("slot-" + Date.now()),
      playerId: state.currentUser.id,
      date,
      startTime: start,
      endTime: end,
      preferredBeach: beach,
      acceptedTiers: checkedTiers,
      allowPlusMinusOneTier: document.getElementById("avail-plusminus")?.checked !== false,
      isRecurringWeekly: document.getElementById("avail-recurring")?.checked === true,
      isMatched: false,
      createdAt: new Date().toISOString()
    };

    state.availabilitySlots.unshift(slot);
    state.availabilitySlots = deduplicateSlots(state.availabilitySlots);
    state.saveLocal();
    await saveSlotToFirestore(slot);
    trackEvent("create_availability", {
      beach: slot.preferredBeach,
      tiers: slot.acceptedTiers ? slot.acceptedTiers.join(",") : ""
    });
    window.closeAddAvailabilityModal();
    renderAvailabilityWindows();
    showToast("Free window saved! Matchmaker is searching for partners.");
  } finally {
    if (submitBtn) {
      submitBtn.disabled = false;
      submitBtn.textContent = "Save Window";
    }
    setTimeout(() => {
      isSavingAvailability = false;
    }, 600);
  }
};

// INITIALIZATION & REAL-TIME FIRESTORE LISTENERS
// ==========================================
// KING OF THE COURT & RANDOM GENERATOR MODAL
// ==========================================
window.currentGeneratedMatches = [];
window.randomGeneratorMode = 'king'; // 'king' or 'mixer'
window.currentRandomPoolPlayers = ["Player 1", "Player 2", "Player 3", "Player 4"];
window.selectedCourtNumbers = new Set([1]);

window.getSelectedCourts = () => {
  if (!window.selectedCourtNumbers || window.selectedCourtNumbers.size === 0) {
    return [1];
  }
  return Array.from(window.selectedCourtNumbers).sort((a, b) => a - b);
};

window.courtForIndex = (index) => {
  const courts = window.getSelectedCourts();
  if (index < courts.length) {
    return courts[index];
  }
  return courts[index % courts.length];
};

window.toggleCourtsDropdown = () => {
  const menu = document.getElementById("rt-courts-dropdown-menu");
  if (!menu) return;
  const isHidden = menu.style.display === "none" || !menu.style.display;
  menu.style.display = isHidden ? "block" : "none";
  if (isHidden) {
    window.renderCourtsCheckboxGrid();
  }
};

window.renderCourtsCheckboxGrid = () => {
  const grid = document.getElementById("rt-courts-checkbox-grid");
  if (!grid) return;
  let html = "";
  for (let num = 1; num <= 18; num++) {
    const isChecked = window.selectedCourtNumbers && window.selectedCourtNumbers.has(num);
    html += `
      <label style="display: flex; align-items: center; gap: 6px; padding: 4px 6px; border-radius: 6px; font-size: 12px; cursor: pointer; background: ${isChecked ? 'rgba(255, 106, 0, 0.12)' : 'var(--bg-input, #f1f5f9)'}; border: 1px solid ${isChecked ? 'rgba(255, 106, 0, 0.4)' : 'transparent'};">
        <input type="checkbox" style="cursor: pointer; accent-color: var(--accent);" value="${num}" ${isChecked ? 'checked' : ''} onchange="window.toggleCourtCheckbox(${num})">
        <span style="font-weight: ${isChecked ? '700' : '500'}; color: var(--text-main);">#${num}</span>
      </label>
    `;
  }
  grid.innerHTML = html;
  window.updateCourtsDropdownUI();
};

window.toggleCourtCheckbox = (num) => {
  if (!window.selectedCourtNumbers) window.selectedCourtNumbers = new Set([1]);
  if (window.selectedCourtNumbers.has(num)) {
    if (window.selectedCourtNumbers.size > 1) {
      window.selectedCourtNumbers.delete(num);
    }
  } else {
    window.selectedCourtNumbers.add(num);
  }
  window.renderCourtsCheckboxGrid();
  window.renderRandomPoolPlayers();
  if (window.currentGeneratedMatches && window.currentGeneratedMatches.length > 0) {
    window.handleGenerateRandomTeams(new Event("submit"));
  }
};

window.selectNeededCourts = () => {
  const count = window.currentRandomPoolPlayers ? window.currentRandomPoolPlayers.length : 4;
  const needed = Math.max(1, window.randomGeneratorMode === 'king' ? Math.floor(count / 4) : 1);
  const start = window.getSelectedCourts()[0] || 1;
  const newSet = new Set();
  for (let i = 0; i < needed; i++) {
    newSet.add(Math.min(18, start + i));
  }
  window.selectedCourtNumbers = newSet;
  window.renderCourtsCheckboxGrid();
  window.renderRandomPoolPlayers();
  if (window.currentGeneratedMatches && window.currentGeneratedMatches.length > 0) {
    window.handleGenerateRandomTeams(new Event("submit"));
  }
};

window.selectAllCourts = () => {
  const set = new Set();
  for (let i = 1; i <= 18; i++) set.add(i);
  window.selectedCourtNumbers = set;
  window.renderCourtsCheckboxGrid();
  window.renderRandomPoolPlayers();
  if (window.currentGeneratedMatches && window.currentGeneratedMatches.length > 0) {
    window.handleGenerateRandomTeams(new Event("submit"));
  }
};

window.resetCourts = () => {
  window.selectedCourtNumbers = new Set([1]);
  window.renderCourtsCheckboxGrid();
  window.renderRandomPoolPlayers();
  if (window.currentGeneratedMatches && window.currentGeneratedMatches.length > 0) {
    window.handleGenerateRandomTeams(new Event("submit"));
  }
};

window.updateCourtsDropdownUI = () => {
  const courts = window.getSelectedCourts();
  const label = courts.length <= 3 
    ? courts.map(n => `Court #${n}`).join(", ") 
    : `${courts.length} Courts (#${courts.slice(0, 2).join(", ")}...)`;
  const btnText = document.getElementById("rt-courts-btn-text");
  if (btnText) btnText.textContent = label;
  const labelSpan = document.getElementById("rt-selected-courts-label");
  if (labelSpan) labelSpan.textContent = label;
};

document.addEventListener("click", (e) => {
  const grp = document.getElementById("rt-court-num-group");
  const menu = document.getElementById("rt-courts-dropdown-menu");
  if (grp && menu && !grp.contains(e.target)) {
    menu.style.display = "none";
  }
});

window.setRandomGeneratorMode = (m) => {
  window.randomGeneratorMode = m;
  const isKing = m === 'king';

  document.getElementById("rt-mode-king")?.classList.toggle("active", isKing);
  document.getElementById("rt-mode-king")?.classList.toggle("btn-outline", !isKing);
  document.getElementById("rt-mode-mixer")?.classList.toggle("active", !isKing);
  document.getElementById("rt-mode-mixer")?.classList.toggle("btn-outline", isKing);

  const descEl = document.getElementById("rt-mode-desc");
  if (descEl) {
    const courts = window.getSelectedCourts();
    descEl.textContent = isKing
      ? `4 Players per court (e.g. 8 players = 2 courts). Assigned Courts: ${courts.map(c => `Court #${c}`).join(", ")}. Each court plays 3 rotating sets with live individual score tracking!`
      : "Continuous social rotations across all players with an equitable resting queue.";
  }

  const numGroup = document.getElementById("rt-num-games-group");
  if (numGroup) numGroup.style.display = isKing ? "none" : "block";

  const btnGen = document.getElementById("rt-generate-btn");
  if (btnGen) {
    btnGen.innerHTML = isKing
      ? "👑 Generate King of the Court Tournament"
      : "🎲 Generate Mixer Rotations";
  }

  const btnAddMatch = document.getElementById("rt-btn-add-match");
  if (btnAddMatch) {
    btnAddMatch.style.display = isKing ? "none" : "block";
  }

  window.renderRandomPoolPlayers();
  if (window.currentGeneratedMatches && window.currentGeneratedMatches.length > 0) {
    window.handleGenerateRandomTeams(new Event("submit"));
  }
};

window.renderRandomPoolPlayers = () => {
  const container = document.getElementById("rt-players-list");
  const countEl = document.getElementById("rt-player-count");
  const total = window.currentRandomPoolPlayers.length;
  if (countEl) countEl.textContent = total;

  window.updateCourtsDropdownUI();

  // Validation badge
  const badgeEl = document.getElementById("rt-validation-badge");
  if (badgeEl) {
    if (total < 4) {
      badgeEl.textContent = "Need 4+ Players";
      badgeEl.style.color = "#ef4444";
    } else if (window.randomGeneratorMode === 'king' && total % 4 !== 0) {
      badgeEl.textContent = `${total % 4} on Bye/Rest`;
      badgeEl.style.color = "#f59e0b";
    } else {
      badgeEl.textContent = "Ready ✓";
      badgeEl.style.color = "#22c55e";
    }
  }

  // Summary card
  const summaryCard = document.getElementById("rt-court-summary-card");
  if (summaryCard) {
    if (window.randomGeneratorMode === 'king') {
      const courts = Math.floor(total / 4);
      if (courts >= 1) {
        let lines = `<strong>🏟️ ${courts} Court${courts > 1 ? 's' : ''} Needed (${courts * 4} Players)</strong>`;
        for (let c = 0; c < courts; c++) {
          const cPlayers = window.currentRandomPoolPlayers.slice(c * 4, (c + 1) * 4);
          const cNum = window.courtForIndex(c);
          lines += `<div style="margin-top: 2px; color: var(--text-muted);">• Court #${cNum}: ${cPlayers.join(", ")}</div>`;
        }
        if (total % 4 !== 0) {
          const rest = window.currentRandomPoolPlayers.slice(courts * 4);
          lines += `<div style="margin-top: 4px; color: #ef4444; font-weight: 600;">⚠️ ${total % 4} Alternate/Bye: ${rest.join(", ")}</div>`;
        }
        summaryCard.innerHTML = lines;
        summaryCard.style.display = "block";
      } else {
        summaryCard.innerHTML = "⚠️ Need at least 4 players (4 per court) to start King of the Court.";
        summaryCard.style.display = "block";
      }
    } else {
      summaryCard.style.display = "none";
    }
  }

  if (!container) return;

  container.innerHTML = window.currentRandomPoolPlayers.map((pName, idx) => {
    const courtNum = window.courtForIndex(Math.floor(idx / 4));
    return `
      <div style="display: flex; align-items: center; gap: 8px;">
        <span style="display: inline-flex; align-items: center; justify-content: center; width: 22px; height: 22px; border-radius: 50%; background: var(--accent-light); color: var(--accent); font-size: 10px; font-weight: 800;">${idx + 1}</span>
        <input type="text" class="form-input" style="padding: 4px 8px; font-size: 13px; flex: 1;" value="${pName}" onchange="window.currentRandomPoolPlayers[${idx}] = this.value.trim()">
        ${window.randomGeneratorMode === 'king' ? `
          <span style="font-size: 10px; font-weight: 700; background: rgba(255, 106, 0, 0.12); color: var(--accent); padding: 2px 6px; border-radius: 999px;">Court #${courtNum}</span>
        ` : ''}
        ${window.currentRandomPoolPlayers.length > 4 ? `
          <button type="button" class="btn btn-outline btn-sm" style="color: #ef4444; border-color: #fca5a5; padding: 2px 8px; font-size: 11px;" onclick="window.removePlayerFromRandomPool(${idx})">✕</button>
        ` : ''}
      </div>
    `;
  }).join("");
};

window.addPlayerToRandomPool = () => {
  const input = document.getElementById("rt-add-player-input");
  if (!input) return;
  const val = input.value.trim();
  if (!val) return;
  window.currentRandomPoolPlayers.push(val);
  input.value = "";
  const numInput = document.getElementById("rt-num-games");
  if (numInput && parseInt(numInput.value) < window.currentRandomPoolPlayers.length) {
    numInput.value = window.currentRandomPoolPlayers.length;
  }
  window.renderRandomPoolPlayers();
};

window.removePlayerFromRandomPool = (idx) => {
  if (window.currentRandomPoolPlayers.length <= 4) return;
  window.currentRandomPoolPlayers.splice(idx, 1);
  window.renderRandomPoolPlayers();
};

window.openRandomTeamsModal = (initialPlayers, initialCourt, initialFormat, initialCourtNumber) => {
  if (!state.currentUser) {
    window.showAuthModal();
    return;
  }
  window.currentEditingGameId = null;
  if (initialPlayers && initialPlayers.length >= 4) {
    window.currentRandomPoolPlayers = [...initialPlayers];
  } else {
    window.currentRandomPoolPlayers = ["Player 1", "Player 2", "Player 3", "Player 4"];
  }
  if (initialCourt) {
    const courtSelect = document.getElementById("rt-court");
    if (courtSelect) courtSelect.value = initialCourt;
  }
  if (initialCourtNumber) {
    const num = parseInt(String(initialCourtNumber).replace(/\D/g, '')) || 1;
    window.selectedCourtNumbers = new Set([Math.min(18, Math.max(1, num))]);
  } else {
    window.selectedCourtNumbers = new Set([1]);
  }
  window.updateCourtsDropdownUI();
  const isKing = initialFormat && (initialFormat.toLowerCase().includes("king"));
  window.setRandomGeneratorMode(isKing ? 'king' : 'king');

  document.getElementById("rt-results-container").style.display = "none";
  window.currentGeneratedMatches = [];
  document.getElementById("random-teams-modal").classList.add("active");
};

window.openRandomTeamsModalForGame = (gameId) => {
  const game = state.games.find(g => g.id === gameId);
  if (!game) return;
  const pids = [...(game.team1PlayerIds || []), ...(game.team2PlayerIds || [])];
  const seen = {};
  const names = pids.map(id => {
    const p = state.getPlayer(id);
    const base = p ? (p.nickname || p.name) : "Player";
    seen[base] = (seen[base] || 0) + 1;
    return seen[base] > 1 ? `${base} (${seen[base]})` : base;
  });
  while (names.length < 4) {
    names.push(`Player ${names.length + 1}`);
  }
  window.openRandomTeamsModal(names, game.courtLocation, game.format, game.courtNumber);
  window.currentEditingGameId = gameId;
};

window.closeRandomTeamsModal = () => {
  document.getElementById("random-teams-modal").classList.remove("active");
};

// Calculate individual player standings for King of the Court
function calculateKingStandings(courtPlayers, courtMatches) {
  const standings = {};
  courtPlayers.forEach(p => {
    standings[p] = { name: p, wins: 0, losses: 0, pointsFor: 0, pointsAgainst: 0 };
  });

  courtMatches.forEach(m => {
    if (!m.s1 || !m.s2) return;
    const s1 = parseInt(m.s1);
    const s2 = parseInt(m.s2);
    if (isNaN(s1) || isNaN(s2)) return;

    const t1Won = s1 > s2;
    const t2Won = s2 > s1;

    m.team1.forEach(p => {
      if (!standings[p]) standings[p] = { name: p, wins: 0, losses: 0, pointsFor: 0, pointsAgainst: 0 };
      standings[p].pointsFor += s1;
      standings[p].pointsAgainst += s2;
      if (t1Won) standings[p].wins++;
      else if (t2Won) standings[p].losses++;
    });

    m.team2.forEach(p => {
      if (!standings[p]) standings[p] = { name: p, wins: 0, losses: 0, pointsFor: 0, pointsAgainst: 0 };
      standings[p].pointsFor += s2;
      standings[p].pointsAgainst += s1;
      if (t2Won) standings[p].wins++;
      else if (t1Won) standings[p].losses++;
    });
  });

  return Object.values(standings).sort((a, b) => {
    if (a.wins !== b.wins) return b.wins - a.wins;
    const diffA = a.pointsFor - a.pointsAgainst;
    const diffB = b.pointsFor - b.pointsAgainst;
    if (diffA !== diffB) return diffB - diffA;
    return b.pointsFor - a.pointsFor;
  });
}

function renderGeneratedMatches() {
  const list = document.getElementById("rt-matches-list");
  if (!list) return;

  if (window.randomGeneratorMode === 'king') {
    const courtCount = Math.floor(window.currentRandomPoolPlayers.length / 4);
    let html = "";
    for (let c = 0; c < courtCount; c++) {
      const assignedCourtNum = window.courtForIndex(c);
      const courtPlayers = window.currentRandomPoolPlayers.slice(c * 4, (c + 1) * 4);
      const courtMatches = window.currentGeneratedMatches.filter(m => m.courtNumber === `Court #${assignedCourtNum}`);
      const standings = calculateKingStandings(courtPlayers, courtMatches);

      html += `
        <div style="background: var(--bg-card); border: 1.5px solid rgba(255, 106, 0, 0.3); border-radius: 12px; padding: 12px 14px;">
          <!-- Court Header -->
          <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
            <div style="font-size: 13px; font-weight: 800; color: var(--accent);">
              👑 COURT #${assignedCourtNum} (PLAYERS ${c * 4 + 1}–${(c + 1) * 4})
            </div>
            ${standings[0] && standings[0].wins > 0 ? `
              <span style="font-size: 11px; font-weight: 700; color: var(--accent); background: rgba(255, 106, 0, 0.12); padding: 2px 8px; border-radius: 999px;">
                King: ${standings[0].name} 👑
              </span>
            ` : ''}
          </div>

          <!-- Individual Standings Table -->
          <div style="background: rgba(0,0,0,0.03); border: 1px solid var(--border); border-radius: 8px; padding: 6px 8px; margin-bottom: 12px;">
            <div style="display: flex; justify-content: space-between; font-size: 10px; font-weight: 800; color: var(--text-muted); padding-bottom: 4px; border-bottom: 1px solid var(--border);">
              <span>RANK / PLAYER</span>
              <span style="display: flex; gap: 14px;">
                <span style="width: 38px; text-align: right;">W-L</span>
                <span style="width: 32px; text-align: right;">PTS</span>
                <span style="width: 38px; text-align: right;">DIFF</span>
              </span>
            </div>
            <div style="display: flex; flex-direction: column; gap: 4px; margin-top: 4px;">
              ${standings.map((st, sIdx) => {
                const diff = st.pointsFor - st.pointsAgainst;
                const diffStr = diff > 0 ? `+${diff}` : `${diff}`;
                const diffColor = diff > 0 ? '#22c55e' : (diff < 0 ? '#ef4444' : 'var(--text-muted)');
                const rankLabels = ['👑 1st', '🥈 2nd', '🥉 3rd', '4th'];
                return `
                  <div style="display: flex; justify-content: space-between; align-items: center; font-size: 12px; padding: 2px 0; ${sIdx === 0 ? 'color: var(--accent); font-weight: 700;' : ''}">
                    <span style="display: flex; gap: 6px; align-items: center;">
                      <span style="font-size: 10px; font-weight: 800;">${rankLabels[sIdx]}</span>
                      <span>${st.name}</span>
                    </span>
                    <span style="display: flex; gap: 14px; font-weight: 600;">
                      <span style="width: 38px; text-align: right;">${st.wins}W-${st.losses}L</span>
                      <span style="width: 32px; text-align: right; font-weight: 700;">${st.pointsFor}</span>
                      <span style="width: 38px; text-align: right; color: ${diffColor};">${diffStr}</span>
                    </span>
                  </div>
                `;
              }).join("")}
            </div>
          </div>

          <!-- Rotating Sets for Court -->
          <div style="display: flex; flex-direction: column; gap: 8px;">
            ${courtMatches.map((m) => {
              const globalIdx = window.currentGeneratedMatches.findIndex(gm => gm.matchNumber === m.matchNumber);
              return `
                <div style="background: var(--bg-card); border: 1px solid var(--border); border-radius: 8px; padding: 8px 10px;">
                  <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 4px;">
                    <span style="font-size: 10px; font-weight: 800; color: var(--accent);">SET ${m.setNumber} • ${m.courtNumber}</span>
                    ${m.isCompleted ? '<span style="font-size: 9px; color: #22c55e; font-weight: 700;">SCORED ✓</span>' : ''}
                  </div>
                  <div style="display: flex; justify-content: space-between; align-items: center; font-size: 12px; font-weight: 700; margin-bottom: 6px;">
                    <span>${m.team1[0]} & ${m.team1[1]}</span>
                    <span style="color: var(--text-muted); font-size: 10px; padding: 0 4px;">VS</span>
                    <span>${m.team2[0]} & ${m.team2[1]}</span>
                  </div>
                  <div style="display: flex; align-items: center; gap: 8px;">
                    <input type="number" id="rt-s1-${globalIdx}" class="form-input" style="width: 55px; padding: 3px 6px; font-size: 12px; text-align: center;" placeholder="T1" value="${m.s1 || ''}" onchange="window.updateGeneratedScore(${globalIdx})">
                    <span>–</span>
                    <input type="number" id="rt-s2-${globalIdx}" class="form-input" style="width: 55px; padding: 3px 6px; font-size: 12px; text-align: center;" placeholder="T2" value="${m.s2 || ''}" onchange="window.updateGeneratedScore(${globalIdx})">
                    <span style="font-size: 10px; color: var(--text-muted); margin-left: auto;">Best of 1 (21)</span>
                  </div>
                </div>
              `;
            }).join("")}
          </div>
        </div>
      `;
    }

    list.innerHTML = html;
  } else {
    // Continuous Social Mixer HTML
    list.innerHTML = window.currentGeneratedMatches.map((m, idx) => `
      <div style="background: var(--bg-card); border: 1px solid var(--border); border-radius: 10px; padding: 10px 12px;">
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom: 6px;">
          <span style="font-size: 11px; font-weight: 800; color: #a855f7;">MATCH ${m.matchNumber}</span>
          ${m.isCompleted ? '<span style="font-size: 10px; color: #22c55e; font-weight: 700;">SCORED ✓</span>' : ''}
        </div>
        <div style="display: flex; justify-content: space-between; align-items: center; font-size: 13px; font-weight: 700; margin-bottom: 6px;">
          <span style="color: var(--text-main);">${m.team1[0]} & ${m.team1[1]}</span>
          <span style="color: var(--text-muted); font-size: 11px; padding: 0 4px;">VS</span>
          <span style="color: var(--text-main);">${m.team2[0]} & ${m.team2[1]}</span>
        </div>
        ${m.resting && m.resting.length > 0 ? `
          <div style="font-size: 11px; color: var(--text-muted); margin-bottom: 8px;">
            ⏸ Resting: ${m.resting.join(", ")}
          </div>
        ` : ''}
        <div style="display: flex; align-items: center; gap: 8px;">
          <input type="number" id="rt-s1-${idx}" class="form-input" style="width: 65px; padding: 4px 6px; font-size: 12px; text-align: center;" placeholder="T1 Pts" value="${m.s1 || ''}" onchange="window.updateGeneratedScore(${idx})">
          <span>–</span>
          <input type="number" id="rt-s2-${idx}" class="form-input" style="width: 65px; padding: 4px 6px; font-size: 12px; text-align: center;" placeholder="T2 Pts" value="${m.s2 || ''}" onchange="window.updateGeneratedScore(${idx})">
          <span style="font-size: 11px; color: var(--text-muted); margin-left: auto;">Best of 1 (21)</span>
        </div>
      </div>
    `).join("");
  }
}

window.updateGeneratedScore = (idx) => {
  const m = window.currentGeneratedMatches[idx];
  if (!m) return;
  const s1Val = document.getElementById(`rt-s1-${idx}`)?.value.trim();
  const s2Val = document.getElementById(`rt-s2-${idx}`)?.value.trim();
  m.s1 = s1Val;
  m.s2 = s2Val;
  m.isCompleted = (s1Val.length > 0 && s2Val.length > 0);
  renderGeneratedMatches();
};

window.handleGenerateRandomTeams = (e) => {
  if (e) e.preventDefault();
  const players = window.currentRandomPoolPlayers
    .map(p => p.trim())
    .filter(p => p.length > 0);

  if (players.length < 4) {
    showToast("Please provide at least 4 players in the pool.");
    return;
  }

  if (window.randomGeneratorMode === 'king') {
    const courtCount = Math.floor(players.length / 4);
    const matches = [];
    let globalIdx = 1;

    // 3 rounds interleaved across courts: all courts play Set 1 simultaneously, then Set 2, then Set 3
    for (let round = 1; round <= 3; round++) {
      for (let c = 0; c < courtCount; c++) {
        const courtPlayers = players.slice(c * 4, (c + 1) * 4);
        const assignedCourtNum = window.courtForIndex(c);
        const courtName = `Court #${assignedCourtNum}`;

        let team1, team2;
        if (round === 1) {
          // Set 1: P0 & P1 vs P2 & P3
          team1 = [courtPlayers[0], courtPlayers[1]];
          team2 = [courtPlayers[2], courtPlayers[3]];
        } else if (round === 2) {
          // Set 2: P0 & P2 vs P1 & P3
          team1 = [courtPlayers[0], courtPlayers[2]];
          team2 = [courtPlayers[1], courtPlayers[3]];
        } else {
          // Set 3: P0 & P3 vs P1 & P2
          team1 = [courtPlayers[0], courtPlayers[3]];
          team2 = [courtPlayers[1], courtPlayers[2]];
        }

        matches.push({
          matchNumber: globalIdx++,
          courtGroup: assignedCourtNum,
          courtNumber: courtName,
          setNumber: round,
          team1: team1,
          team2: team2,
          s1: "",
          s2: "",
          isCompleted: false
        });
      }
    }

    window.currentGeneratedMatches = matches;
    renderGeneratedMatches();
    document.getElementById("rt-results-container").style.display = "block";
    showToast(`Generated King of the Court across ${courtCount} court(s)!`);
  } else {
    // Continuous Social Mixer
    const numGames = parseInt(document.getElementById("rt-num-games")?.value) || Math.max(4, players.length);
    const playCounts = {};
    const partnerHistory = {};
    players.forEach(p => {
      playCounts[p] = 0;
      partnerHistory[p] = new Set();
    });

    const matches = [];
    const courts = window.getSelectedCourts();

    for (let i = 0; i < numGames; i++) {
      const sorted = [...players]
        .sort(() => Math.random() - 0.5)
        .sort((a, b) => playCounts[a] - playCounts[b]);

      const picked = sorted.slice(0, 4);
      const byes = sorted.slice(4);

      const splits = [
        { t1: [picked[0], picked[1]], t2: [picked[2], picked[3]] },
        { t1: [picked[0], picked[2]], t2: [picked[1], picked[3]] },
        { t1: [picked[0], picked[3]], t2: [picked[1], picked[2]] }
      ];

      let bestSplit = splits[0];
      let minRepeats = 999;

      splits.forEach(s => {
        const r1 = (partnerHistory[s.t1[0]]?.has(s.t1[1]) ? 1 : 0) +
                   (partnerHistory[s.t2[0]]?.has(s.t2[1]) ? 1 : 0);
        if (r1 < minRepeats) {
          minRepeats = r1;
          bestSplit = s;
        }
      });

      let t1 = [...bestSplit.t1];
      let t2 = [...bestSplit.t2];
      if (Math.random() > 0.5) {
        const temp = t1;
        t1 = t2;
        t2 = temp;
      }

      picked.forEach(p => playCounts[p] = (playCounts[p] || 0) + 1);
      partnerHistory[t1[0]]?.add(t1[1]);
      partnerHistory[t1[1]]?.add(t1[0]);
      partnerHistory[t2[0]]?.add(t2[1]);
      partnerHistory[t2[1]]?.add(t2[0]);

      const assignedCourtNum = courts[i % courts.length];
      matches.push({
        matchNumber: i + 1,
        courtNumber: `Court #${assignedCourtNum}`,
        team1: t1,
        team2: t2,
        resting: byes,
        s1: "",
        s2: "",
        isCompleted: false
      });
    }

    window.currentGeneratedMatches = matches;
    renderGeneratedMatches();
    document.getElementById("rt-results-container").style.display = "block";
    showToast(`Generated ${numGames} matches across all ${players.length} players!`);
  }
};

window.addAnotherRandomMatch = () => {
  const players = window.currentRandomPoolPlayers
    .map(p => p.trim())
    .filter(p => p.length > 0);
  if (players.length < 4) return;

  const playCounts = {};
  players.forEach(p => playCounts[p] = 0);
  (window.currentGeneratedMatches || []).forEach(m => {
    playCounts[m.team1[0]] = (playCounts[m.team1[0]] || 0) + 1;
    playCounts[m.team1[1]] = (playCounts[m.team1[1]] || 0) + 1;
    playCounts[m.team2[0]] = (playCounts[m.team2[0]] || 0) + 1;
    playCounts[m.team2[1]] = (playCounts[m.team2[1]] || 0) + 1;
  });

  const sorted = [...players]
    .sort(() => Math.random() - 0.5)
    .sort((a, b) => playCounts[a] - playCounts[b]);

  const picked = sorted.slice(0, 4);
  const byes = sorted.slice(4);

  const courts = window.getSelectedCourts();
  const assignedCourtNum = courts[(window.currentGeneratedMatches || []).length % courts.length];
  window.currentGeneratedMatches.push({
    matchNumber: window.currentGeneratedMatches.length + 1,
    courtNumber: `Court #${assignedCourtNum}`,
    team1: [picked[0], picked[1]],
    team2: [picked[2], picked[3]],
    resting: byes,
    s1: "",
    s2: "",
    isCompleted: false
  });

  renderGeneratedMatches();
  showToast(`Appended Match ${window.currentGeneratedMatches.length}!`);
};

window.saveGeneratedMatchesToSchedule = () => {
  if (!window.currentGeneratedMatches || window.currentGeneratedMatches.length === 0) return;

  function resolvePlayerId(name) {
    const found = state.players.find(p => 
      p.name.toLowerCase() === name.toLowerCase() || 
      (p.nickname && p.nickname.toLowerCase() === name.toLowerCase())
    );
    return found ? found.id : "guest_" + name.toLowerCase().replace(/[^a-z0-9]/g, "");
  }

  if (window.currentEditingGameId) {
    const parentGame = state.games.find(g => g.id === window.currentEditingGameId);
    if (parentGame) {
      const subMatches = window.currentGeneratedMatches.map((m, idx) => {
        const s1 = (m.s1 !== undefined && m.s1 !== "" && m.s1 !== null) ? parseInt(m.s1) : null;
        const s2 = (m.s2 !== undefined && m.s2 !== "" && m.s2 !== null) ? parseInt(m.s2) : null;
        const isComp = Boolean(s1 !== null && s2 !== null && !isNaN(s1) && !isNaN(s2));
        const winner = isComp ? (s1 > s2 ? 1 : 2) : null;
        return {
          id: "sub_" + Date.now() + "_" + idx,
          matchNumber: m.matchNumber || idx + 1,
          courtNumber: m.courtNumber || "Court #1",
          setNumber: m.setNumber || idx + 1,
          team1PlayerIds: [resolvePlayerId(m.team1[0]), resolvePlayerId(m.team1[1])],
          team2PlayerIds: [resolvePlayerId(m.team2[0]), resolvePlayerId(m.team2[1])],
          restingPlayerIds: (m.resting || []).map(resolvePlayerId),
          team1Score: s1,
          team2Score: s2,
          isCompleted: isComp,
          winningTeam: winner
        };
      });

      parentGame.subMatches = subMatches;
      saveGameToFirestore(parentGame);
      state.saveLocal();
      window.closeRandomTeamsModal();
      window.currentEditingGameId = null;
      renderMatches();
      showToast(`Saved ${subMatches.length} matches to ${parentGame.title}!`);
      return;
    }
  }

  const court = document.getElementById("rt-court").value;
  const now = new Date();

  window.currentGeneratedMatches.forEach((m, idx) => {
    const scheduledTime = new Date(now.getTime() + idx * 30 * 60000).toISOString();
    const t1Ids = [resolvePlayerId(m.team1[0]), resolvePlayerId(m.team1[1])];
    const t2Ids = [resolvePlayerId(m.team2[0]), resolvePlayerId(m.team2[1])];

    const hasScore = m.s1 && m.s2;
    const s1 = parseInt(m.s1) || 0;
    const s2 = parseInt(m.s2) || 0;

    const isKing = window.randomGeneratorMode === 'king';
    const title = isKing
      ? `King of Court (${m.courtNumber}) - Set ${m.setNumber}`
      : `Round Robin Match #${m.matchNumber}`;

    const newGame = {
      id: "game_rr_" + Date.now() + "_" + idx,
      title: title,
      targetRating: state.currentUser?.rating || "B",
      format: isKing ? "King of Beach (Rotating 3 Sets)" : "1 Set to 21 (Cap 25)",
      status: hasScore ? "completed" : "scheduled",
      scheduledDate: scheduledTime,
      courtLocation: court,
      courtNumber: m.courtNumber || "Court #1",
      team1PlayerIds: t1Ids,
      team2PlayerIds: t2Ids,
      setScores: hasScore ? [`${s1}-${s2}`] : [],
      winningTeam: hasScore ? (s1 > s2 ? 1 : 2) : null,
      notes: `${m.team1[0]} & ${m.team1[1]} vs ${m.team2[0]} & ${m.team2[1]} • ${m.courtNumber || 'Court #1'}`,
      hostPlayerId: state.currentUser?.id || t1Ids[0],
      isLevelLocked: false
    };

    state.games.unshift(newGame);
    saveGameToFirestore(newGame);
  });

  state.saveLocal();
  window.closeRandomTeamsModal();
  renderMatches();
  showToast(`Saved ${window.currentGeneratedMatches.length} sets to schedule!`);
};

function setupBottomNav() {
  document.querySelectorAll(".nav-item").forEach(item => {
    item.onclick = (e) => {
      const tab = item.dataset.tab;
      if (tab) switchTab(tab);
    };
  });
}

function initApp() {
  // 1. Hook navigation listeners first so tabs are ALWAYS clickable
  setupBottomNav();

  // 2. Safely render each component so an issue in one cannot block others
  try { renderHeader(); } catch (e) { console.error("renderHeader error:", e); }
  try { renderLadder(); } catch (e) { console.error("renderLadder error:", e); }
  try { renderPopularKids(); } catch (e) { console.error("renderPopularKids error:", e); }

  try {
    if (state.currentUser) {
      renderMatches();
      renderProfile();
      switchTab("matches");
    } else {
      switchTab("ladders");
    }
  } catch (e) {
    console.error("Initial tab switch error:", e);
    try { switchTab("ladders"); } catch (_) {}
  }

  // Backdrop click to close auth modal for guest browsing
  document.getElementById("auth-modal")?.addEventListener("click", (e) => {
    if (e.target.id === "auth-modal") {
      window.closeAuthModal();
    }
  });

  // Re-verify bottom navigation click handlers
  setupBottomNav();

  // Ladder filter pills
  document.querySelectorAll(".ladder-filter .filter-chip").forEach(chip => {
    chip.addEventListener("click", () => {
      document.querySelectorAll(".ladder-filter .filter-chip").forEach(c => c.classList.remove("active"));
      chip.classList.add("active");
      state.selectedLadderTier = chip.dataset.tier;
      renderLadder();
    });
  });

  // Avatar selector clicks
  document.querySelectorAll(".avatar-btn").forEach(btn => {
    btn.addEventListener("click", () => {
      document.querySelectorAll(".avatar-btn").forEach(b => b.classList.remove("selected"));
      btn.classList.add("selected");
    });
  });

  // Form submit listeners
  document.getElementById("edit-profile-form")?.addEventListener("submit", window.handleSaveEditProfile);
  document.getElementById("profile-form")?.addEventListener("submit", window.handleSaveProfile);
  document.getElementById("score-form")?.addEventListener("submit", window.submitScoreForm);


  // Hook Real-time Cloud Listeners
  subscribeToPlayers((remotePlayers) => {
    if (remotePlayers && remotePlayers.length > 0) {
      state.players = remotePlayers;
      if (state.currentUser) {
        const currentId = String(state.currentUser.id).toLowerCase();
        const found = remotePlayers.find(p => String(p.id).toLowerCase() === currentId);
        if (found) {
          state.currentUser = found;
        } else {
          // Keep existing currentUser — don't wipe session just because Firestore
          // returned a player list that doesn't yet contain the current user.
          console.warn("[Auth] Current user not found in remote players list — keeping local session. userId:", state.currentUser.id);
        }
      }
      state.saveLocal();
      renderHeader();
      renderLadder();
      renderPopularKids();
      renderMatches();
    }
  });

  let hasCompletedInitialGamesSyncWeb = false;
  function playChatNotificationSound() {
    try {
      const ctx = new (window.AudioContext || window.webkitAudioContext)();
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = "sine";
      osc.frequency.setValueAtTime(587.33, ctx.currentTime);
      osc.frequency.setValueAtTime(880, ctx.currentTime + 0.08);
      gain.gain.setValueAtTime(0.15, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.25);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + 0.25);
    } catch (e) {}
  }

  subscribeToGames((remoteGames) => {
    const list = Array.isArray(remoteGames) ? remoteGames : [];
    if (list.length > 0 && hasCompletedInitialGamesSyncWeb && state.currentUser) {
      const userId = state.currentUser.id;
      list.forEach(remoteGame => {
        const inTeam1 = remoteGame.team1PlayerIds && remoteGame.team1PlayerIds.includes(userId);
        const inTeam2 = remoteGame.team2PlayerIds && remoteGame.team2PlayerIds.includes(userId);
        const inWaitlist = remoteGame.waitlistPlayerIds && remoteGame.waitlistPlayerIds.includes(userId);
        const isHost = remoteGame.hostPlayerId === userId;
        if (inTeam1 || inTeam2 || inWaitlist || isHost) {
          const oldGame = state.games.find(g => g.id === remoteGame.id);
          const oldMsgIds = new Set((oldGame?.messages || []).map(m => m.id));
          const newMsgs = (remoteGame.messages || []).filter(m => m.senderId !== userId && !oldMsgIds.has(m.id));
          newMsgs.forEach(msg => {
            playChatNotificationSound();
            triggerWebPushNotification(`💬 ${msg.senderName} (${remoteGame.title})`, `"${msg.text}"`);
            showToast(`💬 ${msg.senderName} (${remoteGame.title}): "${msg.text}"`);
          });
        }
      });
    }
    hasCompletedInitialGamesSyncWeb = true;
    const validGames = list.filter(g => {
      const s = String(g.status || "").trim().toLowerCase();
      return s !== "canceled";
    });
    state.games = validGames;
    state.saveLocal();
    renderMatches();
    if (window.activeChatGameId) {
      window.renderChatMessages();
    }
    handleIncomingGameRoute();
  });

  subscribeToSlots((remoteSlots) => {
    state.availabilitySlots = deduplicateSlots(Array.isArray(remoteSlots) ? remoteSlots : []);
    state.saveLocal();
    renderAvailabilityWindows();
  });

  // Handle incoming deep link or game route from QR scan
  handleIncomingGameRoute();
}

if (document.readyState === "loading") {
  window.addEventListener("DOMContentLoaded", initApp);
} else {
  initApp();
}
