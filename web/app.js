import { 
  savePlayerToFirestore, 
  deletePlayerFromFirestore,
  saveGameToFirestore, 
  deleteGameFromFirestore,
  saveSlotToFirestore, 
  deleteSlotFromFirestore,
  saveTournamentToFirestore,
  deleteTournamentFromFirestore,
  subscribeToPlayers, 
  subscribeToGames, 
  subscribeToSlots,
  subscribeToTournaments,
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
  // Auto-expire games that are more than 2 hours past their scheduled time
  const gameDate = parseGameDate(game.scheduledDate);
  const twoHoursAfter = new Date(gameDate.getTime() + 2 * 60 * 60 * 1000);
  if (new Date() > twoHoursAfter) return false;
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

export function getPlayerConnections(player, timeframe = "allTime") {
  if (!player) return { partners: new Set(), opponents: new Set(), partnersCount: 0, opponentsCount: 0, total: 0 };
  const partners = new Set();
  const opponents = new Set();
  const pid = String(player.id || "").toLowerCase();
  const pName = String(player.name || "").trim().toLowerCase();

  // Helper to test if another ID/name matches this player
  const isMe = (otherId) => {
    if (!otherId) return false;
    const str = String(otherId).toLowerCase();
    if (str === pid) return true;
    if (isSamePlayer(otherId, player.id)) return true;
    const otherP = state.players.find(x => String(x.id).toLowerCase() === str);
    if (otherP && pName && String(otherP.name || "").trim().toLowerCase() === pName) return true;
    return false;
  };

  const isTimeframeFiltered = timeframe === "month" || timeframe === "year";
  const cutoffDays = timeframe === "month" ? 30 : 365;
  const cutoffTime = Date.now() - cutoffDays * 24 * 60 * 60 * 1000;

  // 1. Include explicit stored IDs ONLY if all-time
  if (!isTimeframeFiltered) {
    if (Array.isArray(player.uniquePartnerIds)) {
      player.uniquePartnerIds.forEach(id => {
        if (id && !isMe(id)) partners.add(String(id));
      });
    }
    if (Array.isArray(player.uniqueOpponentIds)) {
      player.uniqueOpponentIds.forEach(id => {
        if (id && !isMe(id)) opponents.add(String(id));
      });
    }
  }

  // 2. Scan completed games and sub-matches in state.games (only completed / played matches)
  if (Array.isArray(state.games)) {
    for (const g of state.games) {
      if (isTimeframeFiltered) {
        const gTime = parseGameDate(g.scheduledDate).getTime();
        if (gTime < cutoffTime) continue;
      }

      const isGameCompleted = g.status === "completed";
      const subMatches = (Array.isArray(g.subMatches) && g.subMatches.length > 0) 
        ? g.subMatches 
        : (g.team1PlayerIds ? [g] : []);
      
      for (const m of subMatches) {
        const hasScores = (m.team1Score != null && m.team2Score != null && (Number(m.team1Score) > 0 || Number(m.team2Score) > 0));
        const isMatchCompleted = Boolean(m.isCompleted || isGameCompleted || hasScores);

        // Do not count unplayed/scheduled matches
        if (!isMatchCompleted) continue;

        const t1 = Array.isArray(m.team1PlayerIds) ? m.team1PlayerIds : [];
        const t2 = Array.isArray(m.team2PlayerIds) ? m.team2PlayerIds : [];

        const isT1 = t1.some(id => isMe(id));
        const isT2 = t2.some(id => isMe(id));

        if (isT1) {
          t1.forEach(id => { if (!isMe(id)) partners.add(String(id)); });
          t2.forEach(id => { if (!isMe(id)) opponents.add(String(id)); });
        } else if (isT2) {
          t2.forEach(id => { if (!isMe(id)) partners.add(String(id)); });
          t1.forEach(id => { if (!isMe(id)) opponents.add(String(id)); });
        }
      }
    }
  }

  const allConnections = new Set([...partners, ...opponents]);
  return {
    partners,
    opponents,
    partnersCount: partners.size,
    opponentsCount: opponents.size,
    total: allConnections.size
  };
}

export function getUniqueConnectionsCount(player) {
  return getPlayerConnections(player).total;
}

export function getPopularKidsTitle(connections) {
  if (connections >= 30) return "👑 The Mayor";
  if (connections >= 20) return "🌟 Beach Legend";
  if (connections >= 12) return "🤝 Social Catalyst";
  if (connections >= 5) return "☀️ Dune Cruiser";
  return "🐚 Fresh Footprint";
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
        // Expire cache entries older than 30 minutes
        const age = Date.now() - (parsed._fetchedAt || 0);
        if (age > 30 * 60 * 1000) {
          sessionStorage.removeItem(`wb_weather_${key}`);
          return null;
        }
        this.cache[key] = parsed;
        return parsed;
      }
    } catch (e) {}
    return null;
  },

  setCached(court, rawDate, forecast) {
    const key = this.getCacheKey(court, rawDate);
    const entry = { ...forecast, _fetchedAt: Date.now() };
    this.cache[key] = entry;
    try {
      sessionStorage.setItem(`wb_weather_${key}`, JSON.stringify(entry));
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
    // Use NOAA National Blend of Models (NBM) — more accurate for US coastal locations
    const baseParams = `latitude=${coords.lat}&longitude=${coords.lon}&hourly=temperature_2m,uv_index,wind_speed_10m,wind_gusts_10m,weather_code&temperature_unit=fahrenheit&wind_speed_unit=mph&timezone=auto&past_days=7&forecast_days=14`;
    const nbmUrl = `https://api.open-meteo.com/v1/forecast?${baseParams}&models=ncep_nbm_conus`;
    const defaultUrl = `https://api.open-meteo.com/v1/forecast?${baseParams}`;

    let res = await fetch(nbmUrl);
    // Fall back to default model if NBM fails or errors
    if (!res.ok || (await res.clone().json().then(d => d.error).catch(() => false))) {
      res = await fetch(defaultUrl);
    }
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
  },

  async getWeeklyForecast(court) {
    const coords = this.getCoordinates(court);
    const cleanCourt = String(court || "Main Beach").trim().toLowerCase().replace(/\s+/g, "-");
    const cacheKey = `weekly_${cleanCourt}`;
    try {
      const stored = sessionStorage.getItem(`wb_weather_${cacheKey}`);
      if (stored) {
        const parsed = JSON.parse(stored);
        if (Date.now() - (parsed._fetchedAt || 0) < 30 * 60 * 1000) {
          return parsed.days;
        }
      }
    } catch (_) {}

    const url = `https://api.open-meteo.com/v1/forecast?latitude=${coords.lat}&longitude=${coords.lon}&daily=weather_code,temperature_2m_max,temperature_2m_min,uv_index_max,wind_speed_10m_max,sunrise,sunset&hourly=temperature_2m,uv_index,wind_speed_10m,weather_code&temperature_unit=fahrenheit&wind_speed_unit=mph&timezone=auto&forecast_days=7`;

    try {
      const res = await fetch(url);
      if (!res.ok) throw new Error(`Status ${res.status}`);
      const data = await res.json();
      const days = this.parseWeeklyResponse(data, court);
      try {
        sessionStorage.setItem(`wb_weather_${cacheKey}`, JSON.stringify({ days, _fetchedAt: Date.now() }));
      } catch (_) {}
      return days;
    } catch (err) {
      console.warn("Failed to fetch weekly forecast, using fallback:", err);
      return this.getWeeklyFallback(court);
    }
  },

  formatTimeLabel(isoStr, fallback = "7:00 AM") {
    if (!isoStr) return fallback;
    try {
      const timePart = isoStr.split("T")[1];
      if (!timePart) return fallback;
      const [hStr, mStr] = timePart.split(":");
      let h = parseInt(hStr, 10);
      const m = mStr || "00";
      if (isNaN(h)) return fallback;
      const ampm = h >= 12 ? "PM" : "AM";
      h = h % 12 || 12;
      return `${h}:${m} ${ampm}`;
    } catch (_) {
      return fallback;
    }
  },

  parseWeeklyResponse(data, court) {
    const daily = data.daily || {};
    const times = daily.time || [];
    const hourly = data.hourly || {};
    const hTimes = hourly.time || [];
    const days = [];

    for (let i = 0; i < times.length && i < 7; i++) {
      const dateStr = times[i];
      const [year, month, dayNum] = dateStr.split("-").map(Number);
      const d = new Date(year, month - 1, dayNum, 12, 0, 0);

      const dayName = i === 0 ? "Today" : (i === 1 ? "Tomorrow" : d.toLocaleDateString("en-US", { weekday: "short" }));
      const dateFormatted = d.toLocaleDateString("en-US", { month: "short", day: "numeric" });
      const fullDayTitle = d.toLocaleDateString("en-US", { weekday: "long", month: "short", day: "numeric" });

      const tempMax = Math.round(daily.temperature_2m_max?.[i] ?? 74);
      const tempMin = Math.round(daily.temperature_2m_min?.[i] ?? 56);
      const tempAvg = Math.round((tempMax + tempMin) / 2);
      const windMax = Math.round(daily.wind_speed_10m_max?.[i] ?? 8);
      const uvMax = Math.round((daily.uv_index_max?.[i] ?? 4.0) * 10) / 10;
      const code = daily.weather_code?.[i] ?? 0;
      const { emoji, text } = this.interpretWeatherCode(code);

      // Sunrise & Sunset Parsing
      const rawSunrise = daily.sunrise?.[i] || "";
      const rawSunset = daily.sunset?.[i] || "";
      const sunriseTime = this.formatTimeLabel(rawSunrise, "6:56 AM");
      const sunsetTime = this.formatTimeLabel(rawSunset, "7:04 PM");

      // Daytime hourly window: sunrise hour to sunset hour
      let startHour = 7;
      let endHour = 19;
      if (rawSunrise && rawSunrise.includes("T")) {
        const sh = parseInt(rawSunrise.split("T")[1]?.split(":")[0], 10);
        if (!isNaN(sh)) startHour = Math.max(5, Math.min(8, sh));
      }
      if (rawSunset && rawSunset.includes("T")) {
        const eh = parseInt(rawSunset.split("T")[1]?.split(":")[0], 10);
        if (!isNaN(eh)) endHour = Math.max(17, Math.min(21, eh));
      }

      const daylightHours = [];
      for (let hIdx = 0; hIdx < hTimes.length; hIdx++) {
        const hTimeStr = hTimes[hIdx];
        if (!hTimeStr.startsWith(dateStr)) continue;
        const hourPart = parseInt(hTimeStr.split("T")[1]?.split(":")[0], 10);
        if (isNaN(hourPart)) continue;

        if (hourPart >= startHour && hourPart <= endHour) {
          const hTemp = Math.round(hourly.temperature_2m?.[hIdx] ?? tempAvg);
          const hWind = Math.round(hourly.wind_speed_10m?.[hIdx] ?? 6);
          const hUv = Math.round((hourly.uv_index?.[hIdx] ?? 2.0) * 10) / 10;
          const hCode = hourly.weather_code?.[hIdx] ?? code;
          const hInterp = this.interpretWeatherCode(hCode);
          const ampm = hourPart >= 12 ? "PM" : "AM";
          const hour12 = hourPart % 12 || 12;

          daylightHours.push({
            timeStr: hTimeStr,
            hour24: hourPart,
            hourLabel: `${hour12} ${ampm}`,
            temp: hTemp,
            windMph: hWind,
            uvIndex: hUv,
            conditionEmoji: hInterp.emoji,
            conditionText: hInterp.text
          });
        }
      }

      days.push({
        courtLocation: court,
        dateIndex: i,
        dateStr,
        dayName,
        dateFormatted,
        fullDayTitle,
        tempMax,
        tempMin,
        tempAvg,
        windMax,
        uvMax,
        conditionEmoji: emoji,
        conditionText: text,
        sunrise: sunriseTime,
        sunset: sunsetTime,
        daylightHours
      });
    }

    if (days.length === 0) return this.getWeeklyFallback(court);
    return days;
  },

  getWeeklyFallback(court) {
    const days = [];
    const baseTemps = [72, 70, 75, 78, 82, 69, 71];
    const baseWinds = [7, 9, 8, 12, 16, 6, 8];
    const baseUVs = [3.8, 4.2, 3.5, 4.8, 5.2, 3.2, 3.9];
    const emojis = ["☀️", "🌤️", "☀️", "🌤️", "💨", "☀️", "🌤️"];
    const texts = ["Sunny", "Mostly Sunny", "Clear", "Partly Cloudy", "Breezy & Sunny", "Clear", "Sunny"];

    for (let i = 0; i < 7; i++) {
      const d = new Date();
      d.setDate(d.getDate() + i);
      const dateStr = d.toISOString().split("T")[0];
      const tMax = baseTemps[i];
      const tMin = tMax - 16;

      // Realistic daylight hourly curve: 7 AM to 7 PM
      const daylightHours = [];
      const sampleTemps = [60, 63, 67, 70, 72, 74, 75, 76, 74, 72, 70, 67, 63];
      const sampleWinds = [4, 5, 6, 7, 8, 9, 10, 11, 12, 10, 8, 6, 5];
      const sampleUvs = [0.5, 1.2, 2.2, 3.4, 4.2, 4.8, 5.0, 4.5, 3.5, 2.5, 1.5, 0.6, 0.1];
      const hours = [7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19];

      for (let h = 0; h < hours.length; h++) {
        const hour24 = hours[h];
        const ampm = hour24 >= 12 ? "PM" : "AM";
        const hour12 = hour24 % 12 || 12;
        daylightHours.push({
          timeStr: `${dateStr}T${String(hour24).padStart(2, '0')}:00`,
          hour24,
          hourLabel: `${hour12} ${ampm}`,
          temp: sampleTemps[h],
          windMph: Math.min(baseWinds[i] + (sampleWinds[h] - 8), 20),
          uvIndex: Math.round(sampleUvs[h] * 10) / 10,
          conditionEmoji: sampleWinds[h] > 11 ? "💨" : (hour24 === 19 ? "🌅" : emojis[i]),
          conditionText: sampleWinds[h] > 11 ? "Breezy" : (hour24 === 19 ? "Sunset" : texts[i])
        });
      }

      days.push({
        courtLocation: court,
        dateIndex: i,
        dateStr,
        dayName: i === 0 ? "Today" : (i === 1 ? "Tomorrow" : d.toLocaleDateString("en-US", { weekday: "short" })),
        dateFormatted: d.toLocaleDateString("en-US", { month: "short", day: "numeric" }),
        fullDayTitle: d.toLocaleDateString("en-US", { weekday: "long", month: "short", day: "numeric" }),
        tempMax: tMax,
        tempMin: tMin,
        tempAvg: Math.round((tMax + tMin) / 2),
        windMax: baseWinds[i],
        uvMax: baseUVs[i],
        conditionEmoji: emojis[i],
        conditionText: texts[i],
        sunrise: "6:56 AM",
        sunset: "7:04 PM",
        daylightHours
      });
    }
    return days;
  }
};
window.weatherService = weatherService;

// ==========================================
// VOLLEYBALL? WEATHER & SUITABILITY MODULE
// ==========================================

window.volleyballCriteria = {
  minTemp: 60,
  maxTemp: 80,
  maxWind: 10,
  maxUV: 4.0
};

window.selectedVolleyballDayIndex = 0;
window.currentVolleyballWeeklyData = [];

export function loadVolleyballCriteria() {
  try {
    const saved = localStorage.getItem("vb_weather_criteria");
    if (saved) {
      const parsed = JSON.parse(saved);
      if (parsed.minTemp !== undefined) window.volleyballCriteria.minTemp = Number(parsed.minTemp);
      if (parsed.maxTemp !== undefined) window.volleyballCriteria.maxTemp = Number(parsed.maxTemp);
      if (parsed.maxWind !== undefined) window.volleyballCriteria.maxWind = Number(parsed.maxWind);
      if (parsed.maxUV !== undefined) window.volleyballCriteria.maxUV = Number(parsed.maxUV);
    }
  } catch (e) {}
}

export function saveVolleyballCriteria() {
  try {
    localStorage.setItem("vb_weather_criteria", JSON.stringify(window.volleyballCriteria));
  } catch (e) {}
}

export function evaluateVolleyballSuitability(day, criteria = window.volleyballCriteria) {
  const issues = [];
  const warnings = [];

  // Wind speed check
  if (day.windMax > criteria.maxWind + 3) {
    issues.push(`Too windy (${day.windMax} mph)`);
  } else if (day.windMax > criteria.maxWind) {
    warnings.push(`Breezy (${day.windMax} mph)`);
  }

  // Temperature check
  if (day.tempMax > criteria.maxTemp) {
    issues.push(`Too hot (${day.tempMax}°F)`);
  } else if (day.tempAvg < criteria.minTemp - 6) {
    issues.push(`Too cold (${day.tempAvg}°F)`);
  } else if (day.tempAvg < criteria.minTemp) {
    warnings.push(`Chilly (${day.tempAvg}°F)`);
  }

  // UV index check
  if (day.uvMax > criteria.maxUV + 2.5) {
    warnings.push(`High UV (${day.uvMax})`);
  } else if (day.uvMax > criteria.maxUV) {
    warnings.push(`Elevated UV (${day.uvMax})`);
  }

  // Severe weather
  const textLower = (day.conditionText || "").toLowerCase();
  if (textLower.includes("rain") || textLower.includes("storm") || textLower.includes("drizzle")) {
    issues.push(`Rain (${day.conditionText})`);
  }

  let status = "good";
  let statusText = "Good for Volleyball";
  let statusEmoji = "🟢";
  let badgeClass = "ok";
  let summaryTip = "Prime beach conditions: Low wind drift, comfortable temperatures, and great ball control.";

  if (issues.length > 0) {
    status = "poor";
    statusEmoji = "🔴";
    statusText = issues.join(" • ");
    badgeClass = "bad";
    if (issues.some(i => i.toLowerCase().includes("wind"))) {
      summaryTip = "High wind: Ball floats quickly off coastal gusts. Focus on low, aggressive sets.";
    } else if (issues.some(i => i.toLowerCase().includes("hot"))) {
      summaryTip = "Hot sand alert: Sand socks and plenty of electrolytes recommended.";
    } else if (issues.some(i => i.toLowerCase().includes("rain"))) {
      summaryTip = "Inclement weather: Slick volleyballs and wet courts.";
    } else {
      summaryTip = "Cold conditions: Warm up thoroughly and wear windbreaker/thermal layers.";
    }
  } else if (warnings.length > 0) {
    status = "fair";
    statusEmoji = "🟡";
    statusText = warnings.join(" • ");
    badgeClass = "warn";
    if (warnings.some(w => w.toLowerCase().includes("breezy") || w.toLowerCase().includes("wind"))) {
      summaryTip = "Moderate ocean breeze: Slight ball drift on deep float serves.";
    } else if (warnings.some(w => w.toLowerCase().includes("uv"))) {
      summaryTip = "Sun safety: Apply SPF 30+ sunscreen and wear UV-rated sunglasses.";
    } else {
      summaryTip = "Fair playing conditions: Crisp sets possible with minor adjustments.";
    }
  }

  return {
    status,
    statusEmoji,
    statusText,
    badgeClass,
    issues,
    warnings,
    summaryTip
  };
}

export function evaluateHourlySuitability(hour, criteria = window.volleyballCriteria) {
  const issues = [];
  const warnings = [];

  // Wind speed check
  if (hour.windMph > criteria.maxWind + 3) {
    issues.push(`Too windy (${hour.windMph} mph)`);
  } else if (hour.windMph > criteria.maxWind) {
    warnings.push(`Breezy (${hour.windMph} mph)`);
  }

  // Temperature check
  if (hour.temp > criteria.maxTemp) {
    issues.push(`Too hot (${hour.temp}°F)`);
  } else if (hour.temp < criteria.minTemp - 4) {
    issues.push(`Too cold (${hour.temp}°F)`);
  } else if (hour.temp < criteria.minTemp) {
    warnings.push(`Chilly (${hour.temp}°F)`);
  } else if (hour.temp > criteria.maxTemp - 2) {
    warnings.push(`Warm (${hour.temp}°F)`);
  }

  // UV index check
  if (hour.uvIndex > criteria.maxUV + 2.5) {
    issues.push(`High UV (${hour.uvIndex})`);
  } else if (hour.uvIndex > criteria.maxUV) {
    warnings.push(`Moderate UV (${hour.uvIndex})`);
  }

  // Weather condition check
  const textLower = (hour.conditionText || "").toLowerCase();
  if (textLower.includes("rain") || textLower.includes("storm") || textLower.includes("drizzle")) {
    issues.push(`Rain`);
  }

  let status = "green";
  let label = "Good to Play";
  let tip = "Optimal conditions: Low wind drift, comfortable temp, crisp sets.";

  if (issues.length > 0) {
    status = "red";
    label = issues[0];
    tip = issues.join(" • ");
  } else if (warnings.length > 0) {
    status = "yellow";
    label = warnings[0];
    tip = warnings.join(" • ");
  }

  return { status, label, tip, issues, warnings };
}

export function calculateBestPlayingWindow(daylightHours, criteria = window.volleyballCriteria) {
  if (!daylightHours || daylightHours.length === 0) return null;

  const evaluated = daylightHours.map(h => ({
    hour: h,
    eval: evaluateHourlySuitability(h, criteria)
  }));

  // Find longest contiguous run of green hours
  let bestStart = -1;
  let bestLen = 0;
  let curStart = -1;
  let curLen = 0;

  for (let i = 0; i < evaluated.length; i++) {
    if (evaluated[i].eval.status === "green") {
      if (curStart === -1) curStart = i;
      curLen++;
      if (curLen > bestLen) {
        bestLen = curLen;
        bestStart = curStart;
      }
    } else {
      curStart = -1;
      curLen = 0;
    }
  }

  if (bestLen >= 2) {
    const windowHours = evaluated.slice(bestStart, bestStart + bestLen).map(e => e.hour);
    const startH = windowHours[0];
    const endH = windowHours[windowHours.length - 1];
    const avgTemp = Math.round(windowHours.reduce((sum, h) => sum + h.temp, 0) / windowHours.length);
    const maxWind = Math.max(...windowHours.map(h => h.windMph));
    const maxUv = Math.max(...windowHours.map(h => h.uvIndex));

    return {
      windowText: `${startH.hourLabel} – ${endH.hourLabel}`,
      status: "green",
      score: bestLen * 10 + (25 - maxWind),
      summaryText: `${avgTemp}°F • 💨 ${maxWind} mph • ☀️ UV ${maxUv}`,
      badgeTitle: "Best Time to Play",
      tip: "Optimal wind, UV, and comfortable temperature"
    };
  }

  // Look for green or yellow
  bestStart = -1;
  bestLen = 0;
  curStart = -1;
  curLen = 0;
  for (let i = 0; i < evaluated.length; i++) {
    if (evaluated[i].eval.status !== "red") {
      if (curStart === -1) curStart = i;
      curLen++;
      if (curLen > bestLen) {
        bestLen = curLen;
        bestStart = curStart;
      }
    } else {
      curStart = -1;
      curLen = 0;
    }
  }

  if (bestLen >= 1) {
    const windowHours = evaluated.slice(bestStart, bestStart + bestLen).map(e => e.hour);
    const startH = windowHours[0];
    const endH = windowHours[windowHours.length - 1];
    const avgTemp = Math.round(windowHours.reduce((sum, h) => sum + h.temp, 0) / windowHours.length);
    const maxWind = Math.max(...windowHours.map(h => h.windMph));
    const maxUv = Math.max(...windowHours.map(h => h.uvIndex));

    return {
      windowText: `${startH.hourLabel} – ${endH.hourLabel}`,
      status: "yellow",
      score: bestLen * 5,
      summaryText: `${avgTemp}°F • 💨 ${maxWind} mph (Breeze)`,
      badgeTitle: "Playable Window",
      tip: "Playable window with manageable breeze"
    };
  }

  return {
    windowText: "Poor All Day",
    status: "red",
    score: 0,
    summaryText: "Challenging wind, heat, or rain",
    badgeTitle: "Not Recommended",
    tip: "Indoor play advised"
  };
}

window.selectedVolleyballHourIndex = null;

window.selectedDayHourlyIndices = window.selectedDayHourlyIndices || {};

export function renderSingleDayCardHtml(day, dayIdx, criteria = window.volleyballCriteria) {
  if (!day) return "";
  const daylightHours = day.daylightHours || [];
  const bestWindow = calculateBestPlayingWindow(daylightHours, criteria) || {
    windowText: "Poor All Day",
    status: "red",
    score: 0,
    summaryText: "High wind or extreme temps",
    badgeTitle: "Not Recommended"
  };

  // Determine selected hour index for this day
  window.selectedDayHourlyIndices = window.selectedDayHourlyIndices || {};
  let selectedHourIdx = window.selectedDayHourlyIndices[dayIdx];
  if (selectedHourIdx === undefined || selectedHourIdx === null || selectedHourIdx >= daylightHours.length) {
    const idealIdx = daylightHours.findIndex(h => evaluateHourlySuitability(h, criteria).status === "green");
    if (idealIdx >= 0) {
      selectedHourIdx = idealIdx;
    } else {
      const fairIdx = daylightHours.findIndex(h => evaluateHourlySuitability(h, criteria).status === "yellow");
      selectedHourIdx = fairIdx >= 0 ? fairIdx : 0;
    }
    window.selectedDayHourlyIndices[dayIdx] = selectedHourIdx;
  }

  const selectedHour = daylightHours[selectedHourIdx] || daylightHours[0];
  const evalSelected = selectedHour ? evaluateHourlySuitability(selectedHour, criteria) : null;

  // 1. Highlight Bar Chart HTML
  const barsHtml = daylightHours.map((h, hIdx) => {
    const hEval = evaluateHourlySuitability(h, criteria);
    const isSelected = hIdx === selectedHourIdx;
    const isMatch = hEval.status === "green";
    const isFair = hEval.status === "yellow";

    if (isMatch || isFair) {
      const heightPercent = isMatch ? Math.min(96, Math.max(48, (h.temp - 50) * 2.2 + 30)) : 38;
      const barColor = isMatch ? "linear-gradient(to top, #d97706, #fbbf24)" : "linear-gradient(to top, #854d0e, #ca8a04)";
      const glow = isMatch ? "0 0 10px rgba(251, 191, 36, 0.5)" : "none";
      const borderStyle = isSelected ? "outline: 2.5px solid #38bdf8; box-shadow: 0 0 12px rgba(56, 189, 248, 0.85);" : "";
      return `
        <div class="sf-col" onclick="window.selectDayHourlyCard(${dayIdx}, ${hIdx})" title="${h.hourLabel}: ${hEval.label}">
          <div class="sf-bar-inner" style="height: ${heightPercent}%; background: ${barColor}; box-shadow: ${glow}; ${borderStyle}"></div>
        </div>
      `;
    } else {
      const dotStyle = isSelected ? "background: #38bdf8; transform: scale(1.6); box-shadow: 0 0 8px #38bdf8;" : "";
      return `
        <div class="sf-col" onclick="window.selectDayHourlyCard(${dayIdx}, ${hIdx})" title="${h.hourLabel}: ${hEval.label}">
          <div class="sf-dot-inner" style="${dotStyle}"></div>
        </div>
      `;
    }
  }).join("");

  // Axis markers
  const axisStep = Math.max(1, Math.floor(daylightHours.length / 6));
  const markers = [];
  for (let i = 0; i < daylightHours.length; i += axisStep) {
    markers.push(daylightHours[i].hourLabel.replace(' ', ''));
  }
  const lastHourStr = daylightHours.length > 0 ? daylightHours[daylightHours.length - 1].hourLabel.replace(' ', '') : '';
  if (lastHourStr && !markers.includes(lastHourStr)) {
    markers.push(lastHourStr);
  }
  const axisHtml = markers.map(m => `<span>${m}</span>`).join("");

  // 2. Daylight Hourly Grid Cards HTML
  const hourlyCardsHtml = daylightHours.map((h, hIdx) => {
    const hEval = evaluateHourlySuitability(h, criteria);
    const isSelected = hIdx === selectedHourIdx;
    const dotClass = hEval.status === "green" ? "vb-dot-green" : (hEval.status === "yellow" ? "vb-dot-yellow" : "vb-dot-red");

    return `
      <div class="vb-hour-card status-${hEval.status} ${isSelected ? 'selected' : ''}" onclick="window.selectDayHourlyCard(${dayIdx}, ${hIdx})" title="${h.hourLabel}: ${hEval.label} (${h.temp}°F, ${h.windMph} mph, UV ${h.uvIndex})">
        <span class="vb-hour-label">${h.hourLabel}</span>
        <span class="vb-hour-emoji">${h.conditionEmoji}</span>
        <span class="vb-dot ${dotClass}"></span>
        <span class="vb-hour-temp">${h.temp}°</span>
        <span class="vb-hour-wind">💨 ${h.windMph}m</span>
        <span class="vb-hour-uv">UV ${h.uvIndex}</span>
      </div>
    `;
  }).join("");

  // 3. Selected Hour Callout HTML
  let calloutHtml = "";
  if (selectedHour && evalSelected) {
    const statusText = evalSelected.status === "green"
      ? "Great for Volleyball"
      : (evalSelected.status === "yellow" ? "Fair Playing Window" : "Unfavorable (" + evalSelected.label + ")");
    const dotEmoji = evalSelected.status === "green" ? "🟢" : (evalSelected.status === "yellow" ? "🟡" : "🔴");
    const statusColor = evalSelected.status === "green" ? "#4ade80" : (evalSelected.status === "yellow" ? "#facc15" : "#f87171");

    const tempClass = selectedHour.temp >= criteria.minTemp && selectedHour.temp <= criteria.maxTemp ? "ok" : "bad";
    const windClass = selectedHour.windMph <= criteria.maxWind ? "ok" : (selectedHour.windMph <= criteria.maxWind + 3 ? "warn" : "bad");
    const uvClass = selectedHour.uvIndex <= criteria.maxUV ? "ok" : "warn";

    calloutHtml = `
      <div class="vb-hour-callout-box">
        <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 12px;">
          <span style="font-size: 32px; line-height: 1;">${selectedHour.conditionEmoji}</span>
          <div style="flex: 1;">
            <div style="font-size: 14px; font-weight: 800; color: #ffffff;">
              ${selectedHour.hourLabel}: <span style="color: ${statusColor}; font-weight: 800;">${dotEmoji} ${statusText}</span>
            </div>
            <div style="font-size: 12px; color: #cbd5e1; margin-top: 3px; font-weight: 500; line-height: 1.4;">
              ${evalSelected.tip}
            </div>
          </div>
        </div>

        <div style="display: flex; gap: 8px; flex-wrap: wrap;">
          <span class="vb-metric-chip ${tempClass}">
            🌡️ <b>${selectedHour.temp}°F</b>
          </span>
          <span class="vb-metric-chip ${windClass}">
            💨 <b>${selectedHour.windMph} mph</b>
          </span>
          <span class="vb-metric-chip ${uvClass}">
            ☀️ <b>UV ${selectedHour.uvIndex}</b>
          </span>
        </div>
      </div>
    `;
  }

  return `
    <div id="vb-full-day-${dayIdx}" class="vb-full-day-card">
      <!-- Header with Sunrise / Sunset & Best Time Window -->
      <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 12px; flex-wrap: wrap; gap: 8px;">
        <div>
          <div style="display: flex; align-items: center; gap: 8px;">
            <span style="font-size: 17px;">⏱️</span>
            <span style="font-size: 15px; font-weight: 800; color: #ffffff;">${day.fullDayTitle} • Sunrise to Sunset</span>
            ${dayIdx === 0 ? '<span style="font-size: 10px; font-weight: 900; background: #ea580c; color: #ffffff; padding: 2px 7px; border-radius: 6px; letter-spacing: 0.5px;">TODAY</span>' : ''}
          </div>
          <div style="display: flex; align-items: center; gap: 8px; margin-top: 6px; flex-wrap: wrap;">
            <span class="sun-summary-chip">🌅 Sunrise ${day.sunrise || "6:56 AM"}</span>
            <span class="sun-summary-chip">🌇 Sunset ${day.sunset || "7:03 PM"}</span>
          </div>
        </div>

        <!-- Best Playing Window Callout -->
        ${bestWindow ? `
          <div class="best-window-pill status-${bestWindow.status}">
            <span>🌟</span>
            <span><b>Best Time:</b> ${bestWindow.windowText}</span>
          </div>
        ` : ''}
      </div>

      <!-- CONDITIONS HIGHLIGHTED Section -->
      <div class="sf-chart-wrapper" style="margin-bottom: 14px; padding: 14px 10px 10px 10px;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
          <span style="font-size: 11px; font-weight: 800; color: rgba(255,255,255,0.85); display: flex; align-items: center; gap: 5px; letter-spacing: 0.5px;">
            <span>✨</span> CONDITIONS HIGHLIGHTED
          </span>
          <button type="button" class="btn btn-sm btn-outline" onclick="window.openSmartForecastsModal()" style="font-size: 10px; padding: 2px 8px; border-radius: 6px; color: #38bdf8; border-color: rgba(56,189,248,0.3); font-weight: 700; background: rgba(56,189,248,0.06);">
            Edit Conditions
          </button>
        </div>
        <div class="sf-timeline-bars" style="height: 65px;">
          ${barsHtml}
        </div>
        <div class="sf-timeline-axis" style="margin-top: 4px;">
          ${axisHtml}
        </div>
      </div>

      <!-- Daylight Hourly Cards Grid (Sunrise to Sunset) -->
      <div class="vb-hourly-track" style="margin-bottom: 12px;">
        ${hourlyCardsHtml}
      </div>

      <!-- Selected Hour Detail Callout -->
      ${calloutHtml}
    </div>
  `;
}

window.selectDayHourlyCard = function(dayIdx, hIdx) {
  window.selectedDayHourlyIndices = window.selectedDayHourlyIndices || {};
  window.selectedDayHourlyIndices[dayIdx] = hIdx;
  const day = window.currentVolleyballWeeklyData?.[dayIdx];
  if (day) {
    const cardEl = document.getElementById(`vb-full-day-${dayIdx}`);
    if (cardEl) {
      cardEl.outerHTML = renderSingleDayCardHtml(day, dayIdx, window.volleyballCriteria);
      return;
    }
  }
  if (window.currentVolleyballWeeklyData) {
    renderVolleyballDaysList(window.currentVolleyballWeeklyData);
  }
};

export function renderDaytimeHourlyChart(day) {
  // Maintained for backward compatibility; full cards are rendered in 7-day list
}

window.selectVolleyballHour = function(hIdx) {
  const dayIdx = window.selectedVolleyballDayIndex || 0;
  window.selectDayHourlyCard(dayIdx, hIdx);
};

export function syncVolleyballCriteriaToUI() {
  const c = window.volleyballCriteria;
  const tempMinInput = document.getElementById("vb-temp-min");
  const tempMaxInput = document.getElementById("vb-temp-max");
  const windMaxInput = document.getElementById("vb-wind-max");
  const uvMaxInput = document.getElementById("vb-uv-max");

  if (tempMinInput) tempMinInput.value = c.minTemp;
  if (tempMaxInput) tempMaxInput.value = c.maxTemp;
  if (windMaxInput) windMaxInput.value = c.maxWind;
  if (uvMaxInput) uvMaxInput.value = c.maxUV;

  const tempDisplay = document.getElementById("vb-temp-val-display");
  const windDisplay = document.getElementById("vb-wind-val-display");
  const uvDisplay = document.getElementById("vb-uv-val-display");
  const summaryDisplay = document.getElementById("vb-settings-summary");

  if (tempDisplay) tempDisplay.innerText = `${c.minTemp}°F – ${c.maxTemp}°F`;
  if (windDisplay) windDisplay.innerText = `Below ${c.maxWind} mph`;
  if (uvDisplay) uvDisplay.innerText = `Below ${Number(c.maxUV).toFixed(1)}`;
  if (summaryDisplay) summaryDisplay.innerText = `${c.minTemp}-${c.maxTemp}°F • <${c.maxWind} mph • UV <${c.maxUV}`;
}

window.updateVolleyballCriteriaFromUI = function() {
  const tempMinInput = document.getElementById("vb-temp-min");
  const tempMaxInput = document.getElementById("vb-temp-max");
  const windMaxInput = document.getElementById("vb-wind-max");
  const uvMaxInput = document.getElementById("vb-uv-max");

  let minT = Number(tempMinInput?.value ?? 60);
  let maxT = Number(tempMaxInput?.value ?? 80);
  if (minT > maxT) {
    minT = maxT - 2;
    if (tempMinInput) tempMinInput.value = minT;
  }

  window.volleyballCriteria = {
    minTemp: minT,
    maxTemp: maxT,
    maxWind: Number(windMaxInput?.value ?? 10),
    maxUV: Number(uvMaxInput?.value ?? 4.0)
  };

  saveVolleyballCriteria();
  syncVolleyballCriteriaToUI();

  if (window.currentVolleyballWeeklyData && window.currentVolleyballWeeklyData.length > 0) {
    renderVolleyballChart(window.currentVolleyballWeeklyData);
    renderVolleyballDaysList(window.currentVolleyballWeeklyData);
    updateVolleyballOverallPill(window.currentVolleyballWeeklyData);
    const selDay = window.currentVolleyballWeeklyData[window.selectedVolleyballDayIndex || 0] || window.currentVolleyballWeeklyData[0];
    renderDaytimeHourlyChart(selDay);
  }
};

window.resetVolleyballCriteria = function() {
  window.volleyballCriteria = {
    minTemp: 60,
    maxTemp: 80,
    maxWind: 10,
    maxUV: 4.0
  };
  saveVolleyballCriteria();
  syncVolleyballCriteriaToUI();

  if (window.currentVolleyballWeeklyData && window.currentVolleyballWeeklyData.length > 0) {
    renderVolleyballChart(window.currentVolleyballWeeklyData);
    renderVolleyballDaysList(window.currentVolleyballWeeklyData);
    updateVolleyballOverallPill(window.currentVolleyballWeeklyData);
    const selDay = window.currentVolleyballWeeklyData[window.selectedVolleyballDayIndex || 0] || window.currentVolleyballWeeklyData[0];
    renderDaytimeHourlyChart(selDay);
  }
};

window.toggleVolleyballSettings = function() {
  const body = document.getElementById("vb-settings-body");
  const chevron = document.getElementById("vb-settings-chevron");
  if (!body) return;
  const isHidden = body.style.display === "none" || !body.style.display;
  body.style.display = isHidden ? "block" : "none";
  if (chevron) {
    chevron.style.transform = isHidden ? "rotate(180deg)" : "rotate(0deg)";
  }
};

window.onVolleyballBeachChange = function() {
  window.renderVolleyballTab();
};

window.refreshVolleyballWeather = function() {
  const beachSelect = document.getElementById("vb-beach-select");
  const selectedBeach = beachSelect ? beachSelect.value : "Main Beach";
  const cleanCourt = String(selectedBeach).trim().toLowerCase().replace(/\s+/g, "-");
  try {
    sessionStorage.removeItem(`wb_weather_weekly_${cleanCourt}`);
  } catch (_) {}
  window.renderVolleyballTab();
};

window.selectVolleyballDay = function(index) {
  window.selectedVolleyballDayIndex = index;
  const targetCard = document.getElementById(`vb-full-day-${index}`);
  if (targetCard) {
    targetCard.scrollIntoView({ behavior: "smooth", block: "start" });
  }
};

export function renderVolleyballChart(days) {
  // Maintained for compatibility
}

export function renderVolleyballDaysList(days) {
  const container = document.getElementById("vb-days-list");
  if (!container || !days) return;

  const criteria = window.volleyballCriteria;
  container.innerHTML = days.map((day, idx) => renderSingleDayCardHtml(day, idx, criteria)).join("");
}

export function updateVolleyballOverallPill(days) {
  const pill = document.getElementById("vb-overall-pill");
  if (!pill || days.length === 0) return;

  const today = days[0];
  const evalRes = evaluateVolleyballSuitability(today);

  if (evalRes.status === "good") {
    pill.style.background = "rgba(34, 197, 94, 0.2)";
    pill.style.color = "#4ade80";
    pill.innerHTML = `🟢 Great Today (${today.tempAvg}°F, 💨${today.windMax}m)`;
  } else if (evalRes.status === "fair") {
    pill.style.background = "rgba(234, 179, 8, 0.2)";
    pill.style.color = "#facc15";
    pill.innerHTML = `🟡 Fair Today (${today.tempAvg}°F, 💨${today.windMax}m)`;
  } else {
    pill.style.background = "rgba(239, 68, 68, 0.2)";
    pill.style.color = "#f87171";
    pill.innerHTML = `🔴 Poor Today (${evalRes.statusText})`;
  }
}

window.renderVolleyballTab = async function() {
  loadVolleyballCriteria();
  syncVolleyballCriteriaToUI();

  const beachSelect = document.getElementById("vb-beach-select");
  const selectedBeach = beachSelect ? beachSelect.value : "Main Beach";

  const daysList = document.getElementById("vb-days-list");
  if (daysList) {
    daysList.innerHTML = `
      <div style="text-align: center; padding: 24px; color: rgba(255,255,255,0.6);">
        <div style="font-size: 28px;">⏳</div>
        <div style="margin-top: 8px; font-size: 13px; font-weight: 700;">Fetching 7-day coastal forecast...</div>
      </div>
    `;
  }

  const days = await weatherService.getWeeklyForecast(selectedBeach);
  window.currentVolleyballWeeklyData = days;

  renderVolleyballChart(days);
  renderVolleyballDaysList(days);
  updateVolleyballOverallPill(days);
  const selectedDay = days[window.selectedVolleyballDayIndex || 0] || days[0];
  renderDaytimeHourlyChart(selectedDay);
};

// ==========================================
// VOLLEYBALL? EMBEDDABLE WIDGET GENERATOR
// ==========================================

window.openVolleyballEmbedModal = function() {
  const modal = document.getElementById("vb-embed-modal");
  if (!modal) return;

  // Sync beach from main selector if available
  const beachSelect = document.getElementById("vb-beach-select");
  const embedBeachSelect = document.getElementById("embed-beach-select");
  if (beachSelect && embedBeachSelect) {
    embedBeachSelect.value = beachSelect.value;
  }

  window.updateEmbedCodePreview();
  modal.classList.add("active");
};

window.closeVolleyballEmbedModal = function() {
  const modal = document.getElementById("vb-embed-modal");
  if (modal) modal.classList.remove("active");
};

window.updateEmbedCodePreview = function() {
  const beachSelect = document.getElementById("embed-beach-select");
  const themeSelect = document.getElementById("embed-theme-select");
  const viewSelect = document.getElementById("embed-view-select");

  const beach = beachSelect ? beachSelect.value : "Main Beach";
  const theme = themeSelect ? themeSelect.value : "dark";
  const view = viewSelect ? viewSelect.value : "full";

  const minTemp = window.volleyballCriteria?.minTemp ?? 60;
  const maxTemp = window.volleyballCriteria?.maxTemp ?? 80;
  const maxWind = window.volleyballCriteria?.maxWind ?? 10;
  const maxUv = window.volleyballCriteria?.maxUV ?? 4.0;

  const origin = window.location.origin && window.location.origin !== "null" ? window.location.origin : "https://setgames.app";
  let pathname = window.location.pathname || "/";
  if (!pathname.endsWith("/")) {
    pathname = pathname.substring(0, pathname.lastIndexOf("/") + 1);
  }
  const baseWidgetUrl = `${origin}${pathname}widget.html`;
  const baseScriptUrl = `${origin}${pathname}widget.js`;

  const queryParams = new URLSearchParams({
    beach,
    theme,
    view,
    minTemp,
    maxTemp,
    maxWind,
    maxUv
  });

  const widgetUrl = `${baseWidgetUrl}?${queryParams.toString()}`;

  // Update live preview iframe
  const iframePreview = document.getElementById("embed-live-iframe");
  if (iframePreview) {
    iframePreview.src = `widget.html?${queryParams.toString()}`;
    iframePreview.style.height = view === "compact" ? "320px" : "380px";
  }

  // Update iframe embed snippet
  const iframeText = document.getElementById("embed-code-iframe");
  if (iframeText) {
    iframeText.value = `<iframe src="${widgetUrl}" width="100%" height="${view === 'compact' ? '340' : '520'}" style="border:none; border-radius:16px; overflow:hidden;" loading="lazy"></iframe>`;
  }

  // Update script embed snippet
  const scriptText = document.getElementById("embed-code-script");
  if (scriptText) {
    scriptText.value = `<div id="volleyball-weather-widget" data-beach="${beach}" data-theme="${theme}" data-view="${view}" data-min-temp="${minTemp}" data-max-temp="${maxTemp}" data-max-wind="${maxWind}" data-max-uv="${maxUv}"></div>\n<script src="${baseScriptUrl}" async></script>`;
  }
};

window.copyEmbedCode = async function(type) {
  const textarea = document.getElementById(type === "iframe" ? "embed-code-iframe" : "embed-code-script");
  const btn = document.getElementById(type === "iframe" ? "copy-btn-iframe" : "copy-btn-script");
  if (!textarea) return;

  try {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      await navigator.clipboard.writeText(textarea.value);
    } else {
      textarea.select();
      document.execCommand("copy");
    }

    if (btn) {
      const originalText = btn.innerHTML;
      btn.innerHTML = "✅ Copied!";
      btn.style.background = "#22c55e";
      btn.style.borderColor = "#22c55e";
      btn.style.color = "#ffffff";
      setTimeout(() => {
        btn.innerHTML = originalText;
        btn.style.background = "";
        btn.style.borderColor = "";
        btn.style.color = "";
      }, 2000);
    }
    showToast("Widget embed code copied to clipboard!");
  } catch (err) {
    textarea.select();
    showToast("Selected code: Press Cmd+C to copy");
  }
};

// ==========================================
// SMART FORECASTS SYSTEM (CARROT-INSPIRED)
// ==========================================

export const SMART_FORECAST_PRESETS = {
  prime: {
    name: "Prime Doubles",
    icon: "🏐",
    label: "BEACH VOLLEYBALL",
    sub: "Prime Doubles",
    minTemp: 65,
    maxTemp: 82,
    maxWind: 10,
    maxUV: 6.0
  },
  casual: {
    name: "Casual Sand",
    icon: "🏖️",
    label: "BEACH VOLLEYBALL",
    sub: "Casual Play",
    minTemp: 60,
    maxTemp: 86,
    maxWind: 14,
    maxUV: 8.0
  },
  windy: {
    name: "Windy Tolerant",
    icon: "🌪️",
    label: "BEACH VOLLEYBALL",
    sub: "Windy Ok",
    minTemp: 58,
    maxTemp: 88,
    maxWind: 18,
    maxUV: 9.0
  }
};

window.activeSmartPreset = "prime";

window.openSmartForecastsModal = function() {
  const modal = document.getElementById("vb-smart-forecasts-modal");
  if (!modal) return;

  // Initialize values from current criteria
  const crit = window.volleyballCriteria || { minTemp: 65, maxTemp: 82, maxWind: 10, maxUV: 6.0 };
  
  // Set slider values
  const minTempInput = document.getElementById("sf-slider-temp-min");
  const maxTempInput = document.getElementById("sf-slider-temp-max");
  const windInput = document.getElementById("sf-slider-wind");
  const uvInput = document.getElementById("sf-slider-uv");

  if (minTempInput) minTempInput.value = crit.minTemp;
  if (maxTempInput) maxTempInput.value = crit.maxTemp;
  if (windInput) windInput.value = crit.maxWind;
  if (uvInput) uvInput.value = crit.maxUV;

  window.syncSmartForecastDisplays(crit);
  window.renderSmartTimelinePreview();
  modal.classList.add("active");
};

window.closeSmartForecastsModal = function() {
  const modal = document.getElementById("vb-smart-forecasts-modal");
  if (modal) modal.classList.remove("active");
};

window.selectSmartPreset = function(presetKey) {
  const preset = SMART_FORECAST_PRESETS[presetKey];
  if (!preset) return;

  window.activeSmartPreset = presetKey;

  // Update preset buttons active state
  document.querySelectorAll(".sf-preset-chip").forEach(chip => {
    chip.classList.toggle("active", chip.id === `sf-preset-${presetKey}`);
  });

  // Update activity badge in equation row
  const iconEl = document.getElementById("sf-activity-icon");
  const nameEl = document.getElementById("sf-activity-name");
  const subEl = document.getElementById("sf-activity-sub");
  if (iconEl) iconEl.innerText = preset.icon;
  if (nameEl) nameEl.innerText = preset.label;
  if (subEl) subEl.innerText = preset.sub;

  // Update sliders
  const minTempInput = document.getElementById("sf-slider-temp-min");
  const maxTempInput = document.getElementById("sf-slider-temp-max");
  const windInput = document.getElementById("sf-slider-wind");
  const uvInput = document.getElementById("sf-slider-uv");

  if (minTempInput) minTempInput.value = preset.minTemp;
  if (maxTempInput) maxTempInput.value = preset.maxTemp;
  if (windInput) windInput.value = preset.maxWind;
  if (uvInput) uvInput.value = preset.maxUV;

  window.syncSmartForecastDisplays(preset);
  window.renderSmartTimelinePreview();
};

window.syncSmartForecastDisplays = function(crit) {
  // Update card value labels
  const tempVal = document.getElementById("sf-val-temp");
  const windVal = document.getElementById("sf-val-wind");
  const uvVal = document.getElementById("sf-val-uv");
  if (tempVal) tempVal.innerText = `${crit.minTemp}° - ${crit.maxTemp}°F`;
  if (windVal) windVal.innerText = `0 - ${crit.maxWind} mph`;
  if (uvVal) uvVal.innerText = `0 - ${Number(crit.maxUV).toFixed(1)}`;

  // Update slider displays
  const sTempDisp = document.getElementById("sf-slider-temp-disp");
  const sWindDisp = document.getElementById("sf-slider-wind-disp");
  const sUvDisp = document.getElementById("sf-slider-uv-disp");
  if (sTempDisp) sTempDisp.innerText = `${crit.minTemp}°F – ${crit.maxTemp}°F`;
  if (sWindDisp) sWindDisp.innerText = `Below ${crit.maxWind} mph`;
  if (sUvDisp) sUvDisp.innerText = `Below ${Number(crit.maxUV).toFixed(1)}`;
};

window.onSmartSliderChange = function() {
  const minTempInput = document.getElementById("sf-slider-temp-min");
  const maxTempInput = document.getElementById("sf-slider-temp-max");
  const windInput = document.getElementById("sf-slider-wind");
  const uvInput = document.getElementById("sf-slider-uv");

  let minT = Number(minTempInput?.value ?? 60);
  let maxT = Number(maxTempInput?.value ?? 80);
  if (minT > maxT) {
    minT = maxT - 2;
    if (minTempInput) minTempInput.value = minT;
  }

  const crit = {
    minTemp: minT,
    maxTemp: maxT,
    maxWind: Number(windInput?.value ?? 10),
    maxUV: Number(uvInput?.value ?? 4.0)
  };

  window.syncSmartForecastDisplays(crit);
  window.renderSmartTimelinePreview();
};

window.toggleSmartForecastEditor = function(field) {
  const drawer = document.getElementById("sf-sliders-drawer");
  if (drawer) {
    drawer.scrollIntoView({ behavior: "smooth", block: "nearest" });
  }
};

window.renderSmartTimelinePreview = function() {
  const container = document.getElementById("sf-timeline-container");
  const axis = document.getElementById("sf-timeline-axis");
  const dayLabel = document.getElementById("sf-timeline-day-label");
  const summaryEl = document.getElementById("sf-highlight-summary");
  if (!container) return;

  const minTempInput = document.getElementById("sf-slider-temp-min");
  const maxTempInput = document.getElementById("sf-slider-temp-max");
  const windInput = document.getElementById("sf-slider-wind");
  const uvInput = document.getElementById("sf-slider-uv");

  const criteria = {
    minTemp: Number(minTempInput?.value ?? 60),
    maxTemp: Number(maxTempInput?.value ?? 80),
    maxWind: Number(windInput?.value ?? 10),
    maxUV: Number(uvInput?.value ?? 4.0)
  };

  const days = window.currentVolleyballWeeklyData || [];
  const selectedDay = days[window.selectedVolleyballDayIndex || 0] || days[0];

  if (!selectedDay || !selectedDay.daylightHours || selectedDay.daylightHours.length === 0) {
    container.innerHTML = `<div style="padding: 10px; color: rgba(255,255,255,0.5); font-size: 11px;">Select a day to view timeline</div>`;
    return;
  }

  if (dayLabel) {
    dayLabel.innerText = selectedDay.dayName === "Today" ? "TODAY" : selectedDay.fullDayTitle.toUpperCase();
  }

  const daylight = selectedDay.daylightHours;
  let matchingCount = 0;
  let highlightedWindow = calculateBestPlayingWindow(daylight, criteria);

  // Render bars vs dots
  const colsHtml = daylight.map((hour, idx) => {
    const evalRes = evaluateHourlySuitability(hour, criteria);
    const isMatch = evalRes.status === "green";
    const isFair = evalRes.status === "yellow";

    if (isMatch) matchingCount++;

    if (isMatch || isFair) {
      // Calculate vertical bar height (40% to 95%)
      const heightPercent = isMatch ? Math.min(95, Math.max(50, (hour.temp - 50) * 2 + 30)) : 38;
      const barColor = isMatch ? "linear-gradient(to top, #d97706, #fbbf24)" : "linear-gradient(to top, #854d0e, #ca8a04)";
      const glow = isMatch ? "0 0 8px rgba(251, 191, 36, 0.5)" : "none";

      return `
        <div class="sf-col" title="${hour.hourLabel}: Met conditions (${hour.temp}°F, ${hour.windMph} mph, UV ${hour.uvIndex})">
          <div class="sf-bar-inner" style="height: ${heightPercent}%; background: ${barColor}; box-shadow: ${glow};"></div>
        </div>
      `;
    } else {
      // Muted dot
      return `
        <div class="sf-col" title="${hour.hourLabel}: Outside conditions (${hour.temp}°F, ${hour.windMph} mph, UV ${hour.uvIndex})">
          <div class="sf-dot-inner"></div>
        </div>
      `;
    }
  }).join("");

  container.innerHTML = colsHtml;

  // Render axis markers (e.g. 7, 9, 12, 3, 6, 7)
  if (axis && daylight.length > 0) {
    const step = Math.max(1, Math.floor(daylight.length / 5));
    const markers = [];
    for (let i = 0; i < daylight.length; i += step) {
      markers.push(daylight[i].hourLabel.replace(' ', ''));
    }
    const lastLabel = daylight[daylight.length - 1].hourLabel.replace(' ', '');
    if (!markers.includes(lastLabel)) markers.push(lastLabel);

    axis.innerHTML = markers.map(m => `<span>${m}</span>`).join("");
  }

  // Update summary
  if (summaryEl) {
    if (highlightedWindow && highlightedWindow.status !== "red") {
      summaryEl.style.display = "flex";
      summaryEl.innerHTML = `
        <span>🌟</span>
        <span><b>Highlighted Window:</b> ${highlightedWindow.windowText} • ${highlightedWindow.summaryText}</span>
      `;
    } else {
      summaryEl.style.display = "flex";
      summaryEl.innerHTML = `
        <span>⚠️</span>
        <span>Conditions not met on this day. Try adjusting temperature or wind sliders.</span>
      `;
    }
  }
};

window.applySmartForecastCriteria = function() {
  const minTempInput = document.getElementById("sf-slider-temp-min");
  const maxTempInput = document.getElementById("sf-slider-temp-max");
  const windInput = document.getElementById("sf-slider-wind");
  const uvInput = document.getElementById("sf-slider-uv");

  let minT = Number(minTempInput?.value ?? 60);
  let maxT = Number(maxTempInput?.value ?? 80);
  if (minT > maxT) {
    minT = maxT - 2;
  }

  window.volleyballCriteria = {
    minTemp: minT,
    maxTemp: maxT,
    maxWind: Number(windInput?.value ?? 10),
    maxUV: Number(uvInput?.value ?? 4.0)
  };

  saveVolleyballCriteria();
  syncVolleyballCriteriaToUI();

  if (window.currentVolleyballWeeklyData && window.currentVolleyballWeeklyData.length > 0) {
    renderVolleyballChart(window.currentVolleyballWeeklyData);
    renderVolleyballDaysList(window.currentVolleyballWeeklyData);
    updateVolleyballOverallPill(window.currentVolleyballWeeklyData);
    const selDay = window.currentVolleyballWeeklyData[window.selectedVolleyballDayIndex || 0] || window.currentVolleyballWeeklyData[0];
    renderDaytimeHourlyChart(selDay);
  }

  window.closeSmartForecastsModal();
  const preset = SMART_FORECAST_PRESETS[window.activeSmartPreset];
  const name = preset ? preset.name : "Custom";
  showToast(`✨ Beach Volleyball criteria applied (${name})!`);
};

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
    <span style="display:inline-flex; align-items:center; gap:4px; background:rgba(255,255,255,0.06); border:1px solid rgba(255,255,255,0.1); border-radius:20px; padding:2px 8px; font-size:11px; color:rgba(255,255,255,0.5);">
      ☀️ Loading...
    </span>
  `;
}

function buildWeatherLineHtml(gameId, w) {
  const windDir = w.windDirection || "NW";
  const uvIndex = Math.round(w.uvIndex ?? 0);
  const uvColor = (w.uvIndex ?? 0) >= 8 ? "#ef4444" : (w.uvIndex ?? 0) >= 6 ? "#f97316" : (w.uvIndex ?? 0) >= 3 ? "#f59e0b" : "#4ade80";
  return `
    <span onclick="event.stopPropagation(); window.toggleWeatherDetails('${gameId}')" title="Click for beach conditions" style="display:inline-flex; align-items:center; gap:4px; background:rgba(255,255,255,0.08); border:1px solid rgba(255,255,255,0.12); border-radius:20px; padding:2px 8px; font-size:11px; font-weight:700; color:#ffffff; cursor:pointer; white-space:nowrap;">
      <span>${w.conditionEmoji || '☀️'}</span>
      <span>${w.tempF}°F</span>
      <span style="color:rgba(255,255,255,0.5);">•</span>
      <span style="color:${uvColor};">UV ${uvIndex}</span>
      <span style="color:rgba(255,255,255,0.5);">•</span>
      <span>💨 ${w.windMph} mph ${windDir}</span>
    </span>
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
    let savedTourns = null;
    let savedNotifs = null;
    let savedUserId = null;
    try {
      savedPlayers = JSON.parse(localStorage.getItem("setgames_players"));
      savedGames = JSON.parse(localStorage.getItem("setgames_games"));
      savedSlots = JSON.parse(localStorage.getItem("setgames_slots"));
      savedTourns = JSON.parse(localStorage.getItem("setgames_tournaments"));
      savedNotifs = JSON.parse(localStorage.getItem("setgames_notifications"));
      savedUserId = localStorage.getItem("setgames_current_user_id");
    } catch (e) {
      console.warn("Storage read warning:", e);
    }

    this.players = (savedPlayers && savedPlayers.length > 0) ? savedPlayers : initialCommunityPlayers;
    this.games = Array.isArray(savedGames) ? savedGames.filter(isUpcomingGame) : [];
    this.availabilitySlots = deduplicateSlots(savedSlots || []);
    this.tournaments = deduplicateTournaments(Array.isArray(savedTourns) ? savedTourns : []);
    this.notifications = Array.isArray(savedNotifs) ? savedNotifs : [
      {
        id: "notif-welcome",
        title: "🏐 Welcome to Set Games!",
        message: "You'll receive match alerts, partner notifications, and score updates here.",
        type: "Match Confirmed",
        timestamp: new Date().toISOString(),
        isRead: false
      }
    ];
    this.pickupQueue = [];
    this.selectedLadderTier = "All";
    this.selectedLadderTimeframe = "month";
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
      localStorage.setItem("setgames_tournaments", JSON.stringify(this.tournaments));
      localStorage.setItem("setgames_notifications", JSON.stringify(this.notifications || []));
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
export function getCustomAvatarImage(avatarKey) {
  if (!avatarKey) return null;
  const s = String(avatarKey).trim().toLowerCase();
  if (s === "slug" || s === "🍌" || s.includes("slug")) return "slug.png";
  if (s === "derp_ball" || s === "avatar_derp_ball") return "avatar_derp_ball.png";
  if (s === "lobster" || s === "avatar_lobster") return "avatar_lobster.png";
  if (s === "sunburn" || s === "avatar_sunburn") return "avatar_sunburn.png";
  if (s === "net_stuck" || s === "avatar_net_stuck") return "avatar_net_stuck.png";
  if (s === "seagull" || s === "avatar_seagull") return "avatar_seagull.png";
  if (s === "sand_face" || s === "avatar_sand_face") return "avatar_sand_face.png";
  if (s === "sand_dive" || s === "avatar_sand_dive" || s === "sand_wipeout") return "avatar_sand_dive.png";
  if (s === "wilson" || s === "avatar_wilson") return "avatar_wilson.png";
  if (s === "blue_whale" || s === "avatar_blue_whale" || s === "whale") return "avatar_blue_whale.png";
  return null;
}

export function isSlugAvatar(avatarKey) {
  return getCustomAvatarImage(avatarKey) === "slug.png";
}

export function isMustangAvatar(avatarKey) {
  if (!avatarKey) return false;
  const s = String(avatarKey).trim().toLowerCase();
  return s === "mustang" || s === "horse" || s === "🐎";
}

export function renderAvatarContent(avatarKey) {
  const customImg = getCustomAvatarImage(avatarKey);
  if (customImg) {
    return `<img src="assets/${customImg}" alt="Avatar" class="avatar-slug-img" style="width: 100%; height: 100%; object-fit: cover; border-radius: 50%; display: block;">`;
  }
  if (isMustangAvatar(avatarKey)) {
    return "🐎";
  }
  if (avatarKey === "ichthys" || avatarKey === "christian_fish" || avatarKey === "fish_symbol") {
    return `<svg viewBox="0 0 24 24" width="100%" height="100%" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" style="display:inline-block; vertical-align:middle;"><path d="M 2 12 C 7 4, 16 6, 22 17 M 2 12 C 7 20, 16 18, 22 7"/><circle cx="6.5" cy="11" r="1" fill="currentColor"/></svg>`;
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
        <span>${getPlayerDisplayName(state.currentUser)}</span>
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

export function getPlayerDisplayName(player) {
  if (!player) return "Player";
  const nick = String(player.nickname || "").trim();
  if (nick && nick.toLowerCase() !== "player") {
    return nick;
  }
  const name = String(player.name || "").trim();
  const parts = name.split(/\s+/).filter(Boolean);
  const firstName = parts[0] || nick || "Player";
  return firstName;
}

export function getLadderDisplayName(player) {
  if (!player) return "Beach Player";
  return getPlayerDisplayName(player);
}

function resolvePlayerNames(pids, game, isHidden, isWinner = false) {
  if (!pids || pids.length === 0) return "TBD";
  const names = pids.map(id => {
    if (isHidden && game) {
      const allP = [...(game.team1PlayerIds || []), ...(game.team2PlayerIds || [])];
      const idx = allP.indexOf(id);
      return `Player ${idx >= 0 ? idx + 1 : 1}`;
    }
    const p = state.getPlayer(id);
    return p ? getPlayerDisplayName(p) : (typeof id === 'string' && id.startsWith("guest_") ? id.replace("guest_", "") : "Player");
  }).join(" & ");
  return isWinner ? `${names} <span style="font-size: 8px; line-height: 1;">🏅🏅</span>` : names;
}

export function checkPlayerGenderJoinable(game, player) {
  if (!player) return { allowed: false, message: "Please log in." };
  const category = (game.genderCategory || "COED").toUpperCase();
  if (category === "OPEN" || category === "NONE" || category === "ALL") {
    return { allowed: true };
  }
  const pGender = String(player.gender || "").trim().toLowerCase();

  const allActive = [...(game.team1PlayerIds || []), ...(game.team2PlayerIds || [])];
  const currentMales = allActive.map(id => state.getPlayer(id)).filter(p => p && String(p.gender || "").trim().toLowerCase() === "male").length;
  const currentFemales = allActive.map(id => state.getPlayer(id)).filter(p => p && String(p.gender || "").trim().toLowerCase() === "female").length;

  if (category === "COED") {
    if (pGender !== "male" && pGender !== "female") {
      return { allowed: false, message: "Please set your gender (Male or Female) in Profile to join a COED match." };
    }
    if (pGender === "male" && currentMales >= 2) {
      return { allowed: false, message: "COED format is limited to 2 male & 2 female players. Male spots are full (you can join the waitlist)." };
    }
    if (pGender === "female" && currentFemales >= 2) {
      return { allowed: false, message: "COED format is limited to 2 male & 2 female players. Female spots are full (you can join the waitlist)." };
    }
    return { allowed: true };
  } else if (category === "F" || category === "FEMALE") {
    if (pGender !== "female") {
      return { allowed: false, message: "This match is restricted to Female players only." };
    }
    return { allowed: true };
  } else if (category === "M" || category === "MALE") {
    if (pGender !== "male") {
      return { allowed: false, message: "This match is restricted to Male players only." };
    }
    return { allowed: true };
  }
  return { allowed: true };
}

export function getEligibleWaitlistIndex(game) {
  if (!game.waitlistPlayerIds || game.waitlistPlayerIds.length === 0) return -1;
  const currentTotal = (game.team1PlayerIds?.length || 0) + (game.team2PlayerIds?.length || 0);
  const maxP = game.maxPlayers || 4;
  if (currentTotal >= maxP) return -1;

  const allActive = [...(game.team1PlayerIds || []), ...(game.team2PlayerIds || [])];
  const currentMales = allActive.map(id => state.getPlayer(id)).filter(p => p && String(p.gender || "").trim().toLowerCase() === "male").length;
  const currentFemales = allActive.map(id => state.getPlayer(id)).filter(p => p && String(p.gender || "").trim().toLowerCase() === "female").length;

  const category = (game.genderCategory || "COED").toUpperCase();

  for (let i = 0; i < game.waitlistPlayerIds.length; i++) {
    const pid = game.waitlistPlayerIds[i];
    const p = state.getPlayer(pid);
    if (!p) continue;
    const pGender = String(p.gender || "").trim().toLowerCase();

    if (category === "COED") {
      if (pGender === "male" && currentMales < 2) return i;
      if (pGender === "female" && currentFemales < 2) return i;
    } else if (category === "F" || category === "FEMALE") {
      if (pGender === "female") return i;
    } else if (category === "M" || category === "MALE") {
      if (pGender === "male") return i;
    } else {
      return i;
    }
  }
  return -1;
}

export function getOpenSpotGenderSuffix(game, isTeam1 = null, slotIndex = null) {
  const category = (game.genderCategory || "COED").toUpperCase();
  if (category === "OPEN" || category === "NONE" || category === "ALL") {
    return "";
  }
  if (category === "M" || category === "MALE") {
    return " (M)";
  }
  if (category === "F" || category === "FEMALE") {
    return " (F)";
  }

  // COED
  const allActive = [...(game.team1PlayerIds || []), ...(game.team2PlayerIds || [])];
  const mCount = allActive.map(id => state.getPlayer(id)).filter(p => p && String(p.gender || "").trim().toLowerCase() === "male").length;
  const fCount = allActive.map(id => state.getPlayer(id)).filter(p => p && String(p.gender || "").trim().toLowerCase() === "female").length;

  const neededM = Math.max(0, 2 - mCount);
  const neededF = Math.max(0, 2 - fCount);

  if (neededM > 0 && neededF === 0) return " (M)";
  if (neededF > 0 && neededM === 0) return " (F)";

  if (isTeam1 !== null) {
    const teamIds = isTeam1 ? (game.team1PlayerIds || []) : (game.team2PlayerIds || []);
    const teamPlayers = teamIds.map(id => state.getPlayer(id));
    const teamM = teamPlayers.filter(p => p && String(p.gender || "").trim().toLowerCase() === "male").length;
    const teamF = teamPlayers.filter(p => p && String(p.gender || "").trim().toLowerCase() === "female").length;

    if (teamM > 0 && teamF === 0) return " (F)";
    if (teamF > 0 && teamM === 0) return " (M)";

    if (slotIndex !== null) {
      return (slotIndex % 2 === 0) ? " (M)" : " (F)";
    }
  }

  return " (M/F)";
}

export function getOpenSpotLabel(game, isTeam1 = null, slotIndex = null) {
  const suffix = getOpenSpotGenderSuffix(game, isTeam1, slotIndex);
  return `Open Spot${suffix}`;
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

  // Gender Category Check
  const genderCheck = checkPlayerGenderJoinable(game, state.currentUser);
  if (!genderCheck.allowed) {
    showToast(genderCheck.message || "You cannot join this match due to division restrictions.");
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

  const promotedPlayerObj = state.getPlayer(playerId);
  const genderCheck = checkPlayerGenderJoinable(game, promotedPlayerObj);
  if (!genderCheck.allowed) {
    showToast(genderCheck.message || "Player cannot join due to division restrictions.");
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
  const isRoot = isRootUser(state.currentUser);
  const isHost = isSamePlayer(game.hostPlayerId, currentUserId) || (game.team1PlayerIds && isSamePlayer(game.team1PlayerIds[0], currentUserId)) || isRoot;
  if (!isHost) {
    showToast("Only the match host or admin can remove players from the pool.");
    return;
  }

  if (!isRoot && isSamePlayer(playerId, game.hostPlayerId)) {
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
  const wasInWaitlist = game.waitlistPlayerIds && game.waitlistPlayerIds.includes(playerId);
  if (!wasInTeam1 && !wasInTeam2 && !wasInWaitlist) return;

  if (wasInWaitlist) {
    game.waitlistPlayerIds = (game.waitlistPlayerIds || []).filter(id => !isSamePlayer(id, playerId));
    state.saveLocal();
    saveGameToFirestore(game);
    renderMatches();
    showToast(`Removed ${pName} from the waiting list.`);
    return;
  }

  game.team1PlayerIds = (game.team1PlayerIds || []).filter(id => !isSamePlayer(id, playerId));
  game.team2PlayerIds = (game.team2PlayerIds || []).filter(id => !isSamePlayer(id, playerId));

  // Auto-promote first eligible waitlisted player into the open spot
  let promotedPlayerName = null;
  let promotedPlayer = null;
  if (!game.waitlistPlayerIds) game.waitlistPlayerIds = [];
  const eligibleIdx = getEligibleWaitlistIndex(game);
  if (eligibleIdx >= 0) {
    const promotedId = game.waitlistPlayerIds.splice(eligibleIdx, 1)[0];
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

  // Track teammates & opponents for Popular Kids ladder
  [...team1Ids, ...team2Ids].forEach(pid => {
    const p = state.players.find(x => x.id === pid);
    if (!p) return;
    p.uniquePartnerIds = p.uniquePartnerIds || [];
    p.uniqueOpponentIds = p.uniqueOpponentIds || [];
    const isT1 = team1Ids.includes(pid);
    const myTeam = isT1 ? team1Ids : team2Ids;
    const oppTeam = isT1 ? team2Ids : team1Ids;

    myTeam.forEach(partnerId => {
      if (partnerId !== pid && !p.uniquePartnerIds.includes(partnerId)) {
        p.uniquePartnerIds.push(partnerId);
      }
    });
    oppTeam.forEach(oppId => {
      if (!p.uniqueOpponentIds.includes(oppId)) {
        p.uniqueOpponentIds.push(oppId);
      }
    });
    savePlayerToFirestore(p);
  });

  match.appliedStatsWinner = winningTeam;

  if (state.currentUser && (winners.includes(state.currentUser.id) || losers.includes(state.currentUser.id))) {
    const updated = state.players.find(x => x.id === state.currentUser.id);
    if (updated) state.currentUser = updated;
  }
}

let _scoreDebounceTimers = {};

window.autoSaveSubMatchScore = (gameId, matchId) => {
  const s1El = document.getElementById(`sub-s1-${gameId}-${matchId}`);
  const s2El = document.getElementById(`sub-s2-${gameId}-${matchId}`);
  const s1Val = s1El?.value.trim();
  const s2Val = s2El?.value.trim();

  const game = state.games.find(g => g.id === gameId);
  if (!game || !game.subMatches) return;
  const match = game.subMatches.find(m => (m.id === matchId || String(game.subMatches.indexOf(m)) === String(matchId)));
  if (!match) return;

  if (s1Val !== "" && s2Val !== "" && s1Val !== undefined && s2Val !== undefined) {
    const s1 = parseInt(s1Val);
    const s2 = parseInt(s2Val);
    if (!isNaN(s1) && !isNaN(s2)) {
      match.team1Score = s1;
      match.team2Score = s2;
      match.isCompleted = true;
      match.winningTeam = s1 > s2 ? 1 : 2;

      if (s1El) s1El.style.color = match.winningTeam === 1 ? '#4ade80' : '#f87171';
      if (s2El) s2El.style.color = match.winningTeam === 2 ? '#4ade80' : '#38bdf8';

      clearTimeout(_scoreDebounceTimers[`${gameId}-${matchId}`]);
      _scoreDebounceTimers[`${gameId}-${matchId}`] = setTimeout(() => {
        applySubMatchStatsWeb(match);
        if (game.subMatches.every(m => m.isCompleted)) {
          game.status = "completed";
        }
        saveGameToFirestore(game);
        state.saveLocal();
        renderLadder();
        renderProfile();
      }, 400);
    }
  }
};

window.updateSubMatchScoreWeb = (gameId, matchId) => {
  window.autoSaveSubMatchScore(gameId, matchId);
  const game = state.games.find(g => g.id === gameId);
  if (!game || !game.subMatches) return;
  const match = game.subMatches.find(m => (m.id === matchId || String(game.subMatches.indexOf(m)) === String(matchId)));
  if (!match) return;

  const s1Val = document.getElementById(`sub-s1-${gameId}-${matchId}`)?.value.trim();
  const s2Val = document.getElementById(`sub-s2-${gameId}-${matchId}`)?.value.trim();
  if (s1Val !== "" && s2Val !== "" && !isNaN(parseInt(s1Val)) && !isNaN(parseInt(s2Val))) {
    showToast(`Saved score for Match ${match.matchNumber}!`);
  }
};

window.addSubMatchToGame = (gameId) => {
  const game = state.games.find(g => g.id === gameId);
  if (!game) return;
  const pids = [...(game.team1PlayerIds || []), ...(game.team2PlayerIds || [])];
  if (pids.length < 4) {
    showToast("Need at least 4 players in the game to add a match.");
    return;
  }
  
  const playCounts = {};
  const partnerHistory = {};
  pids.forEach(p => {
    playCounts[p] = 0;
    partnerHistory[p] = new Set();
  });
  
  (game.subMatches || []).forEach(m => {
    (m.team1PlayerIds || []).forEach(p => playCounts[p] = (playCounts[p] || 0) + 1);
    (m.team2PlayerIds || []).forEach(p => playCounts[p] = (playCounts[p] || 0) + 1);
    if (m.team1PlayerIds?.length >= 2) {
      partnerHistory[m.team1PlayerIds[0]]?.add(m.team1PlayerIds[1]);
      partnerHistory[m.team1PlayerIds[1]]?.add(m.team1PlayerIds[0]);
    }
    if (m.team2PlayerIds?.length >= 2) {
      partnerHistory[m.team2PlayerIds[0]]?.add(m.team2PlayerIds[1]);
      partnerHistory[m.team2PlayerIds[1]]?.add(m.team2PlayerIds[0]);
    }
  });
  
  const sorted = [...pids]
    .sort(() => Math.random() - 0.5)
    .sort((a, b) => (playCounts[a] || 0) - (playCounts[b] || 0));
  
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
  
  if (!game.subMatches) game.subMatches = [];
  const matchNum = game.subMatches.length + 1;
  const newMatch = {
    id: "sub_" + Date.now() + "_" + matchNum,
    matchNumber: matchNum,
    courtNumber: game.courtNumber || "Court #1",
    setNumber: matchNum,
    team1PlayerIds: t1,
    team2PlayerIds: t2,
    restingPlayerIds: byes,
    team1Score: null,
    team2Score: null,
    isCompleted: false,
    winningTeam: null
  };
  
  game.subMatches.push(newMatch);
  saveGameToFirestore(game);
  state.saveLocal();
  renderMatches();
  showToast(`Added Match #${matchNum}!`);
};

window.removeSubMatchFromGame = (gameId, matchId) => {
  const game = state.games.find(g => g.id === gameId);
  if (!game || !game.subMatches) return;
  const idx = game.subMatches.findIndex(m => m.id === matchId || String(game.subMatches.indexOf(m)) === String(matchId));
  if (idx === -1) return;
  
  game.subMatches.splice(idx, 1);
  game.subMatches.forEach((m, i) => {
    m.matchNumber = i + 1;
    m.setNumber = i + 1;
  });
  saveGameToFirestore(game);
  state.saveLocal();
  renderMatches();
  showToast("Removed match.");
};

let currentMatchFilter = "all"; // 'all', 'myGames', 'openSpots'
window.setMatchFilter = (filter) => {
  currentMatchFilter = filter;
  document.querySelectorAll(".match-filter-chip").forEach(el => {
    el.classList.toggle("active", el.dataset.filter === filter);
  });
  renderMatches();
};

export function renderTournamentCardHtml(t, currentUserId, index = 0) {
  try {
    const d = parseGameDate(t.date);
    const dateFormatted = d.toLocaleDateString("en-US", {
      weekday: "short",
      month: "short",
      day: "numeric"
    }) + " • " + d.toLocaleTimeString("en-US", {
      hour: "numeric",
      minute: "2-digit"
    });
    const courtsList = Array.isArray(t.courts) ? t.courts : [];
    const courtStr = courtsList.length > 0 ? `${courtsList.length} Court${courtsList.length > 1 ? 's' : ''}` : 'Courts TBD';

    const isHost = currentUserId && t.hostPlayerId && isSamePlayer(t.hostPlayerId, currentUserId);
    const isCoHost = currentUserId && (t.coHostPlayerIds || []).some(id => isSamePlayer(id, currentUserId));
    const isRegistered = currentUserId && (
      (t.teams || []).some(tm =>
        isSamePlayer(tm.player1Id, currentUserId) ||
        isSamePlayer(tm.player2Id, currentUserId) ||
        isSamePlayer(tm.player3Id, currentUserId) ||
        isSamePlayer(tm.player4Id, currentUserId)
      ) ||
      (t.freeAgents || []).some(fa => isSamePlayer(fa.playerId, currentUserId))
    );

    const poolMatches = (t.matches || []).filter(m => m.poolName);
    const poolTotal = poolMatches.length;
    const poolPlayed = poolMatches.filter(m => m.score1 !== null && m.score2 !== null && (m.score1 > 0 || m.score2 > 0 || m.winningTeamId)).length;

    const allowedDivs = t.allowedDivisions || (typeof DIVISION_CONFIG !== "undefined" ? DIVISION_CONFIG.map(div => div.name) : ["2v2 Coed Novice", "2v2 Coed Intermediate", "4v4 Coed", "2v2 Men's Intermediate"]);
    const totalTeams = (t.teams || []).length;
    const totalFreeAgents = (t.freeAgents || []).length;

    return `
      ${index > 0 ? '<div class="games-white-gap"></div>' : ''}
      <div class="game-details-card" id="tournament-card-${t.id}" onclick="window.openTournamentDetail('${t.id}')" style="cursor: pointer;">
        <!-- Header Row -->
        <div style="display: flex; justify-content: space-between; align-items: flex-start; gap: 8px; margin-bottom: 8px;">
          <div style="display: flex; align-items: center; gap: 6px; flex-wrap: wrap;">
            <span style="font-size: 18px;">🏆</span>
            <span style="font-size: 17px; font-weight: 800; color: #ffffff;">${t.title || 'Beach Tournament'}</span>
          </div>
          <div style="display: flex; align-items: center; gap: 6px; flex-wrap: wrap; justify-content: flex-end;">
            ${isHost ? `
              <span style="font-size: 10px; font-weight: 800; background: rgba(251, 191, 36, 0.2); color: #fbbf24; padding: 2px 7px; border-radius: 999px;">
                👑 Host
              </span>
            ` : ''}
            ${isCoHost ? `
              <span style="font-size: 10px; font-weight: 800; background: rgba(56, 189, 248, 0.2); color: #38bdf8; padding: 2px 7px; border-radius: 999px;">
                👥 Co-Host
              </span>
            ` : ''}
            ${isRegistered ? `
              <span style="font-size: 10px; font-weight: 800; background: rgba(34, 197, 94, 0.2); color: #4ade80; padding: 2px 7px; border-radius: 999px;">
                🟢 Registered
              </span>
            ` : ''}
            ${poolTotal > 0 ? `
              <span style="font-size: 10px; font-weight: 800; background: ${poolPlayed === poolTotal ? 'rgba(34, 197, 94, 0.2)' : 'rgba(249, 115, 22, 0.2)'}; color: ${poolPlayed === poolTotal ? '#4ade80' : '#fb923c'}; padding: 2px 7px; border-radius: 999px;">
                📊 ${poolPlayed}/${poolTotal} Pools
              </span>
            ` : ''}
            <span style="font-size: 10px; font-weight: 800; background: rgba(8, 145, 178, 0.25); color: #22d3ee; padding: 2px 7px; border-radius: 999px;">
              ${t.teamFormat === '4v4' ? '🏐 4v4 Quads' : '👥 2v2 Doubles'}
            </span>
          </div>
        </div>

        <!-- Date & Location -->
        <div style="display: flex; flex-direction: column; gap: 4px; font-size: 12px; color: rgba(255, 255, 255, 0.7); margin-bottom: 12px;">
          <div style="display: flex; align-items: center; gap: 6px;">
            <span style="color: #fb923c;">📅</span>
            <span style="color: #ffffff; font-weight: 600;">${dateFormatted}</span>
          </div>
          <div style="display: flex; align-items: center; gap: 6px;">
            <span style="color: #38bdf8;">📍</span>
            <span>${t.location || 'Main Beach'} • ${courtStr}</span>
          </div>
        </div>

        <!-- Divisions Badges -->
        <div style="display: flex; flex-wrap: wrap; gap: 6px; margin-bottom: 12px;">
          ${allowedDivs.map(divName => {
            const conf = (typeof DIVISION_CONFIG !== "undefined" ? DIVISION_CONFIG.find(c => c.name === divName) : null) || { icon: "🏐", name: divName };
            const divTeamCount = (t.teams || []).filter(tm => tm.division === divName).length;
            const maxTeams = t.maxTeamsPerDivision || 8;
            return `
              <span style="font-size: 11px; font-weight: 700; background: rgba(255, 255, 255, 0.08); color: #e2e8f0; padding: 3px 8px; border-radius: 999px; border: 1px solid rgba(255, 255, 255, 0.1);">
                ${conf.icon || "🏐"} ${conf.name || divName} (${divTeamCount}/${maxTeams})
              </span>
            `;
          }).join('')}
        </div>

        <!-- Footer -->
        <div style="display: flex; justify-content: space-between; align-items: center; border-top: 1px solid rgba(255, 255, 255, 0.1); padding-top: 10px; font-size: 12px; font-weight: 700; color: #fb923c;">
          <span style="color: rgba(255, 255, 255, 0.6); font-weight: 500;">
            👥 ${totalTeams} Team${totalTeams !== 1 ? 's' : ''} Registered${totalFreeAgents > 0 ? ` • ${totalFreeAgents} Free Agent${totalFreeAgents !== 1 ? 's' : ''}` : ''}
          </span>
          <span style="display: flex; align-items: center; gap: 4px;">
            View Details & Sign Up →
          </span>
        </div>
      </div>
    `;
  } catch (err) {
    console.error("Error rendering tournament card:", t?.id, err);
    return "";
  }
}
window.renderTournamentCardHtml = renderTournamentCardHtml;

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
  const isRoot = isRootUser(state.currentUser);
  checkUpcomingMatchReminders();

  if (typeof deduplicateTournaments === "function") {
    state.tournaments = deduplicateTournaments(state.tournaments || []);
  }

  const twoHoursAgo = new Date(Date.now() - 2 * 60 * 60 * 1000);
  const isCompletedFilter = currentMatchFilter === "completed" || currentMatchFilter === "pastGames";

  const isUserInTournament = (t) => {
    if (!currentUserId) return false;
    const isReg = (t.teams || []).some(tm =>
      isSamePlayer(tm.player1Id, currentUserId) ||
      isSamePlayer(tm.player2Id, currentUserId) ||
      isSamePlayer(tm.player3Id, currentUserId) ||
      isSamePlayer(tm.player4Id, currentUserId)
    ) || (t.freeAgents || []).some(fa => isSamePlayer(fa.playerId, currentUserId));
    const isHost = t.hostPlayerId && isSamePlayer(t.hostPlayerId, currentUserId);
    const isCoHost = (t.coHostPlayerIds || []).some(id => isSamePlayer(id, currentUserId));
    return isReg || isHost || isCoHost || isRoot;
  };

  const isUserInGame = (game) => {
    if (!currentUserId) return false;
    const allP = [...(game.team1PlayerIds || []), ...(game.team2PlayerIds || [])];
    return isPlayerInList(allP, currentUserId) ||
      isSamePlayer(game.hostPlayerId, currentUserId) ||
      isSamePlayer(game.team1PlayerIds?.[0], currentUserId) ||
      isRoot;
  };

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

  // Determine feed items (Games + Tournaments) for current filter
  let feedItems = [];

  if (isCompletedFilter) {
    const pastGames = (state.games || []).filter(g => {
      const s = String(g.status || "").trim().toLowerCase();
      const d = parseGameDate(g.scheduledDate);
      return s === "completed" || d <= twoHoursAgo;
    }).map(g => ({ type: "game", item: g, date: parseGameDate(g.scheduledDate) }));

    const pastTournaments = (state.tournaments || []).filter(t => {
      const s = String(t.status || "").trim().toLowerCase();
      const d = parseGameDate(t.date);
      return s === "completed" || d <= twoHoursAgo;
    }).map(t => ({ type: "tournament", item: t, date: parseGameDate(t.date) }));

    feedItems = [...pastGames, ...pastTournaments].sort((a, b) => b.date.getTime() - a.date.getTime());
  } else if (currentMatchFilter === "myGames" || currentMatchFilter === "myMatches") {
    if (currentUserId) {
      const myGames = (state.games || []).filter(g => {
        const s = String(g.status || "").trim().toLowerCase();
        if (s === "canceled" || s === "cancelled") return false;
        const d = parseGameDate(g.scheduledDate);
        if (d <= twoHoursAgo) return false;
        return isUserInGame(g);
      }).map(g => ({ type: "game", item: g, date: parseGameDate(g.scheduledDate) }));

      const myTournaments = (state.tournaments || []).filter(t => {
        const s = String(t.status || "").trim().toLowerCase();
        if (s === "completed") return false;
        const d = parseGameDate(t.date);
        if (d <= twoHoursAgo) return false;
        return isUserInTournament(t);
      }).map(t => ({ type: "tournament", item: t, date: parseGameDate(t.date) }));

      feedItems = [...myGames, ...myTournaments].sort((a, b) => a.date.getTime() - b.date.getTime());
    }
  } else {
    const upcomingGames = (state.games || []).filter(g => {
      const s = String(g.status || "").trim().toLowerCase();
      if (s === "canceled" || s === "cancelled" || s === "completed") return false;
      const d = parseGameDate(g.scheduledDate);
      if (d <= twoHoursAgo) return false;
      if (currentMatchFilter === "openSpots") return canJoin(g);
      return true;
    }).map(g => ({ type: "game", item: g, date: parseGameDate(g.scheduledDate) }));

    const upcomingTournaments = (currentMatchFilter === "openSpots") ? [] : (state.tournaments || []).filter(t => {
      const s = String(t.status || "").trim().toLowerCase();
      if (s === "completed") return false;
      const d = parseGameDate(t.date);
      return d > twoHoursAgo;
    }).map(t => ({ type: "tournament", item: t, date: parseGameDate(t.date) }));

    feedItems = [...upcomingGames, ...upcomingTournaments].sort((a, b) => a.date.getTime() - b.date.getTime());
  }

  if (feedItems.length === 0) {
    let emptyTitle = "No Upcoming Events";
    let emptySub = "There are no upcoming games or tournaments scheduled yet.";
    if (isCompletedFilter) {
      emptyTitle = "No Past Events";
      emptySub = "No past games or tournaments found in history.";
    } else if (currentMatchFilter === "myGames" || currentMatchFilter === "myMatches") {
      emptyTitle = "No Games or Tournaments";
      emptySub = "You haven't joined or hosted any upcoming games or tournaments.";
    }

    container.innerHTML = `
      <div style="text-align: center; padding: 48px 20px; color: var(--text-muted, #94a3b8);">
        <div style="font-size: 44px; margin-bottom: 12px;">🏐</div>
        <h3 style="font-size: 18px; font-weight: 800; color: #ffffff; margin-bottom: 6px;">${emptyTitle}</h3>
        <p style="font-size: 13px; color: rgba(255,255,255,0.65); max-width: 340px; margin: 0 auto 22px auto; line-height: 1.4;">
          ${emptySub}
        </p>
        <div style="display: flex; flex-direction: column; align-items: center; gap: 10px; max-width: 240px; margin: 0 auto;">
          <button type="button" class="btn btn-primary" onclick="window.openCreateMatchModal()" style="width: 100%; padding: 12px 18px; font-size: 14px; font-weight: 700; border-radius: 999px; background: #2b6e7a; border: none; color: #ffffff; display: flex; align-items: center; justify-content: center; gap: 6px; box-shadow: 0 4px 12px rgba(43, 110, 122, 0.4); cursor: pointer;">
            <span>➕</span> Host a Game
          </button>
          <button type="button" class="btn" onclick="window.openCreateTournamentModal()" style="width: 100%; padding: 12px 18px; font-size: 14px; font-weight: 700; border-radius: 999px; background: #ea580c; border: none; color: #ffffff; display: flex; align-items: center; justify-content: center; gap: 6px; box-shadow: 0 4px 12px rgba(234, 88, 12, 0.4); cursor: pointer;">
            <span>🏆</span> Host Tournament
          </button>
        </div>
      </div>
    `;
    return;
  }

  const cardsHtml = feedItems.map((feedItem, index) => {
    if (feedItem.type === "tournament") {
      return renderTournamentCardHtml(feedItem.item, currentUserId, index);
    }
    const game = feedItem.item;
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

    const renderSlot = (pid, isTeam1, slotIndex = 0) => {
      if (pid) {
        const p = state.getPlayer(pid);
        const isHidden = !isMember && !isRoot;
        const validName = p ? getPlayerDisplayName(p) : (typeof pid === 'string' && pid.startsWith("guest_") ? pid.replace("guest_", "") : "Player");
        const displayName = isHidden ? 'Player' : validName;
        const avatarDisplay = isHidden ? renderAvatarContent('🏐') : renderAvatarContent(p ? p.avatarEmoji : '🏐');
        const tierVal = (p?.rating || 'B');
        const tierClass = String(tierVal).toLowerCase() === 'intermediate' ? 'badge-tier-intermediate' : `badge-tier-${String(tierVal).toLowerCase()}`;
        const starVal = p ? formatStarRating(p) : "5.0";
        const teamClass = isTeam1 ? 'player-tile-team1' : 'player-tile-team2';

        const canRemove = (isHost || isRoot) && (isRoot ? !isSamePlayer(pid, currentUserId) : !isSamePlayer(pid, game.hostPlayerId));
        const removeBtnHtml = canRemove ? `
          <button type="button" class="player-tile-trash" title="Remove player from match" onclick="event.stopPropagation(); window.removePlayerFromPool('${game.id}', '${pid}')">🗑️</button>
        ` : '';

        return `
          <div class="player-tile-dark ${teamClass}">
            <div class="player-tile-avatar">${avatarDisplay}</div>
            <div class="player-tile-info">
              <div class="player-tile-name">${displayName}</div>
              <div style="display:flex; align-items:center; gap:5px;">
                <span class="badge-tier-pill ${tierClass}">${String(tierVal).toLowerCase() === 'intermediate' ? 'Int' : tierVal}</span>
                <span style="font-size:11px; font-weight:700; color:#fbbf24;">⭐ ${starVal}</span>
              </div>
            </div>
            ${removeBtnHtml}
          </div>
        `;
      } else {
        const emptyClass = isTeam1 ? 'player-tile-empty-t1' : 'player-tile-empty-t2';
        const canJoin = needsPlayers && !isMember && !game.isPrivate;
        const canHostAdd = (isHost || isRoot);
        const joinAttr = canJoin ? `onclick="window.joinGamePool('${game.id}')"` : (canHostAdd ? `onclick="window.openAddPlayerModal('${game.id}')" style="cursor: pointer;"` : '');
        const spotLabel = getOpenSpotLabel(game, isTeam1, slotIndex);
        return `
          <div class="player-tile-dark ${emptyClass}" ${joinAttr}>
            <span>+ ${spotLabel}</span>
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
        <!-- Header Row: Match Title + Dropdown Ellipsis -->
        <div class="card-header-row">
          <div class="card-date-title" onclick="window.showGameDetailsModal('${game.id}')">
            <span>${game.title || 'Match'}</span>
          </div>
          <div style="position: relative;">
            <button type="button" class="card-more-btn" onclick="event.stopPropagation(); window.toggleCardActionsMenu('${game.id}', event)" title="More options">
              •••
            </button>
            <div id="card-menu-${game.id}" class="card-dropdown-menu" style="display: none;">
              <button type="button" class="card-dropdown-item" onclick="window.openEditMatchModal('${game.id}')">
                <span>✏️</span> Edit Details
              </button>
              ${(isHost || isRoot) ? `
                <button type="button" class="card-dropdown-item" style="color: #34d399;" onclick="window.toggleCardActionsMenu('${game.id}'); window.openAddPlayerModal('${game.id}')">
                  <span>👤➕</span> + Add Player
                </button>
              ` : ''}
              ${isMember ? `
                <button type="button" class="card-dropdown-item" style="color: #f87171;" onclick="window.toggleCardActionsMenu('${game.id}'); window.leaveGame('${game.id}')">
                  <span>🚪</span> Leave Game
                </button>
              ` : ''}
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
          <div class="card-metadata-line-item" style="flex-wrap: wrap; gap: 4px 8px;">
            <span>📍</span>
            <span>${game.courtLocation} - ${courtDisplay}</span>
            <span id="weather-line-${game.id}" style="margin-left: 4px;">${renderWeatherLine(game)}</span>
          </div>
          <div class="card-metadata-line-item">
            <span>${formatLabel} • ${game.genderCategory || 'COED'} • Skill: ${skillStr}</span>
            ${game.isLevelLocked ? `<span style="font-size:10px; font-weight:700; background:rgba(234,88,12,0.2); color:#fb923c; padding:2px 6px; border-radius:4px;">🔒 Locked</span>` : ''}
          </div>
          <div class="card-metadata-line-item">
            <span>Host: ${hostDisplayName}</span>
            <span style="color:#fbbf24; font-size:13px; font-weight:700;">⭐ ${hostStarVal}</span>
            ${game.isPrivate ? `<span style="color: rgba(255, 255, 255, 0.85); display: inline-flex; align-items: center; gap: 4px;">🔒 Private Games</span>` : ''}
          </div>
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
                  const validName = p ? getPlayerDisplayName(p) : (typeof pid === 'string' && pid.startsWith("guest_") ? pid.replace("guest_", "") : "Player");
                  const displayName = isHidden ? 'Player' : validName;
                  const avatarDisplay = isHidden ? renderAvatarContent('🏐') : renderAvatarContent(p ? p.avatarEmoji : '🏐');
                  const tierVal = (p?.rating || 'B');
                  const tierClass = String(tierVal).toLowerCase() === 'intermediate' ? 'badge-tier-intermediate' : `badge-tier-${String(tierVal).toLowerCase()}`;
                  const starVal = p ? formatStarRating(p) : "5.0";
                  const isGameHost = isSamePlayer(pid, game.hostPlayerId);
                  const canRemove = (isHost || isRoot) && (isRoot ? !isSamePlayer(pid, currentUserId) : !isGameHost);

                  return `
                    <div class="player-pool-list-row">
                      <div style="display: flex; align-items: center; gap: 8px; min-width: 0;">
                        <span style="font-size: 10px; font-weight: 800; background: rgba(56, 189, 248, 0.18); color: #38bdf8; width: 22px; height: 22px; border-radius: 50%; display: flex; align-items: center; justify-content: center; flex-shrink: 0;">
                          #${idx + 1}
                        </span>
                        <div style="width: 28px; height: 28px; border-radius: 50%; background: transparent; display: flex; align-items: center; justify-content: center; font-size: 20px; flex-shrink: 0;">
                          ${avatarDisplay}
                        </div>
                        <div style="min-width: 0;">
                          <div style="font-size: 12px; font-weight: 700; color: #ffffff; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; display: flex; align-items: center; gap: 4px;">
                            <span>${displayName}</span>
                            ${isGameHost ? `<span style="font-size: 8px; font-weight: 800; background: rgba(251, 191, 36, 0.2); color: #fbbf24; padding: 1px 4px; border-radius: 3px;">HOST</span>` : ''}
                          </div>
                          <div style="display: flex; align-items: center; gap: 5px; margin-top: 1px;">
                            <span class="badge-tier-pill ${tierClass}" style="font-size: 9px; padding: 1px 5px;">${String(tierVal).toLowerCase() === 'intermediate' ? 'Int' : tierVal}</span>
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
                    <span style="font-size: 11px; font-weight: 700; color: #38bdf8;">+ Open Spot${getOpenSpotGenderSuffix(game)} (${spotsLeft} remaining)</span>
                  </div>
                ` : ''}
              </div>
            ` : ''}
          </div>
        ` : `
          <!-- 2x2 Player Spot Grid: Team 1 (Row 1 Cyan) / Team 2 (Row 2 Coral) -->
          <div class="player-grid-2x2">
            ${renderSlot(t1Ids[0], true, 0)}
            ${renderSlot(t1Ids[1], true, 1)}
            ${renderSlot(t2Ids[0], false, 0)}
            ${renderSlot(t2Ids[1], false, 1)}
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
                  const validName = p ? getPlayerDisplayName(p) : `Player ${idx + 1}`;
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
                        <div style="display: flex; align-items: center; gap: 6px;">
                          <button type="button" style="background: rgba(239,68,68,0.12); border: 1px solid rgba(239,68,68,0.3); color: #f87171; border-radius: 4px; padding: 1px 5px; font-size: 10px; font-weight: 800; cursor: pointer; line-height: 1.2;" title="Remove this match" onclick="event.stopPropagation(); window.removeSubMatchFromGame('${game.id}', '${mKey}')">✕</button>
                        </div>
                      </div>
                      <div class="submatch-score-row" style="display: flex; justify-content: space-between; align-items: center; font-weight: 700; font-size: 13px; margin-bottom: 6px; color: #ffffff; gap: 6px;">
                        <div class="submatch-team submatch-team-1" style="flex: 1 1 0; min-width: 0; text-align: left; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; color: #f87171; font-size: 6pt;">
                          ${resolvePlayerNames(m.team1PlayerIds, game, !isMember && !isRoot, m.winningTeam === 1)}
                        </div>

                        <div class="submatch-score-center" style="display: flex; align-items: center; gap: 5px; flex-shrink: 0;">
                          <input type="number" id="sub-s1-${game.id}-${mKey}" class="form-input submatch-score-input" inputmode="numeric" pattern="[0-9]*" style="width: 44px; height: 32px; padding: 2px 4px; font-size: 13px; font-weight: 800; text-align: center; background:#1e2433; color:#f87171; border: 1.5px solid rgba(239, 68, 68, 0.5); border-radius: 6px;" placeholder="T1" value="${s1Val}" oninput="window.autoSaveSubMatchScore('${game.id}', '${mKey}')" onchange="window.updateSubMatchScoreWeb('${game.id}', '${mKey}')">
                          <span style="color: rgba(255,255,255,0.4); font-size: 10px; font-weight: 900;">VS</span>
                          <input type="number" id="sub-s2-${game.id}-${mKey}" class="form-input submatch-score-input" inputmode="numeric" pattern="[0-9]*" style="width: 44px; height: 32px; padding: 2px 4px; font-size: 13px; font-weight: 800; text-align: center; background:#1e2433; color:#38bdf8; border: 1.5px solid rgba(56, 189, 248, 0.5); border-radius: 6px;" placeholder="T2" value="${s2Val}" oninput="window.autoSaveSubMatchScore('${game.id}', '${mKey}')" onchange="window.updateSubMatchScoreWeb('${game.id}', '${mKey}')">
                        </div>

                        <div class="submatch-team submatch-team-2" style="flex: 1 1 0; min-width: 0; text-align: right; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; color: #38bdf8; font-size: 6pt;">
                          ${resolvePlayerNames(m.team2PlayerIds, game, !isMember && !isRoot, m.winningTeam === 2)}
                        </div>
                      </div>
                      ${m.restingPlayerIds && m.restingPlayerIds.length > 0 ? `
                        <div style="font-size: 10px; color: rgba(255,255,255,0.5); margin-top: 2px;">
                          ⏸ Resting: ${resolvePlayerNames(m.restingPlayerIds, game, !isMember && !isRoot)}
                        </div>
                      ` : ''}
                    </div>
                  `;
                }).join("")}
                <div style="display: flex; justify-content: space-between; align-items: center; margin-top: 6px;">
                  <button type="button" class="btn btn-outline btn-sm" style="font-size: 11px; font-weight: 700; color: #38bdf8; border-color: rgba(56, 189, 248, 0.4); padding: 4px 10px; border-radius: 6px;" onclick="window.addSubMatchToGame('${game.id}')">
                    ➕ Add Match
                  </button>
                  <button type="button" class="btn btn-outline btn-sm" style="font-size: 11px; font-weight: 700; color: #ea580c; border-color: #fdba74; padding: 4px 10px; border-radius: 6px;" onclick="window.openRandomTeamsModalForGame('${game.id}')">
                    🎲 Regenerate Matches
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

export function deduplicatePlayers(players) {
  if (!Array.isArray(players)) return [];
  const grouped = new Map();

  for (const player of players) {
    if (!player) continue;
    const phoneDigits = String(player.phoneNumber || "").replace(/\D/g, "");
    let key;
    if (phoneDigits.length >= 7) {
      key = `phone:${phoneDigits}`;
    } else {
      const trimmedName = String(player.name || "").trim().toLowerCase();
      if (trimmedName) {
        key = `name:${trimmedName}`;
      } else {
        key = `id:${String(player.id || "").toLowerCase()}`;
      }
    }

    if (grouped.has(key)) {
      const existing = grouped.get(key);
      const existingMatches = (existing.wins || 0) + (existing.losses || 0);
      const newMatches = (player.wins || 0) + (player.losses || 0);
      if (newMatches > existingMatches) {
        grouped.set(key, player);
      } else if (newMatches === existingMatches && (player.eloRating || 1500) > (existing.eloRating || 1500)) {
        grouped.set(key, player);
      } else if (newMatches === existingMatches && player.phoneNumber && !existing.phoneNumber) {
        grouped.set(key, player);
      }
    } else {
      grouped.set(key, player);
    }
  }

  return Array.from(grouped.values());
}

function renderLadder() {
  const container = document.getElementById("ladder-list");
  if (!container) return;

  const tier = state.selectedLadderTier;
  const deduped = deduplicatePlayers(state.players);
  let filtered = deduped.filter(p => !p.isStatsHidden);
  if (tier !== "All") {
    filtered = filtered.filter(p => p.rating === tier);
  }

  const tf = state.selectedLadderTimeframe || "month";
  const isTimeframeFiltered = tf === "month" || tf === "year";
  const cutoffDays = tf === "month" ? 30 : 365;
  const cutoffTime = Date.now() - cutoffDays * 24 * 60 * 60 * 1000;

  const timeframeGames = isTimeframeFiltered 
    ? (state.games || []).filter(g => parseGameDate(g.scheduledDate).getTime() >= cutoffTime)
    : (state.games || []);

  let playerList = filtered.map(p => {
    if (!isTimeframeFiltered) {
      return { ...p, periodPlayed: (p.wins + p.losses) > 0 };
    }
    let pWins = 0;
    let pLosses = 0;
    let pElo = p.eloRating || 1500;
    let matchesCount = 0;

    for (const g of timeframeGames) {
      const isGameCompleted = g.status === "completed";
      const subMatches = (Array.isArray(g.subMatches) && g.subMatches.length > 0) ? g.subMatches : [g];
      for (const m of subMatches) {
        if (m.team1Score == null || m.team2Score == null) continue;
        const s1 = Number(m.team1Score);
        const s2 = Number(m.team2Score);
        if (s1 === 0 && s2 === 0 && !m.isCompleted && !isGameCompleted) continue;
        const winner = s1 > s2 ? 1 : (s2 > s1 ? 2 : 0);
        if (winner === 0) continue;
        const inT1 = (m.team1PlayerIds || []).some(id => isSamePlayer(id, p.id));
        const inT2 = (m.team2PlayerIds || []).some(id => isSamePlayer(id, p.id));
        if (inT1) {
          matchesCount++;
          if (winner === 1) { pWins++; pElo += 24; }
          else { pLosses++; pElo = Math.max(800, pElo - 20); }
        } else if (inT2) {
          matchesCount++;
          if (winner === 2) { pWins++; pElo += 24; }
          else { pLosses++; pElo = Math.max(800, pElo - 20); }
        }
      }
    }
    return {
      ...p,
      wins: pWins,
      losses: pLosses,
      eloRating: pElo,
      periodPlayed: matchesCount > 0
    };
  });

  playerList.sort((a, b) => {
    if (isTimeframeFiltered) {
      const playedA = a.periodPlayed ? 1 : 0;
      const playedB = b.periodPlayed ? 1 : 0;
      if (playedB !== playedA) return playedB - playedA;
    }
    if (b.wins !== a.wins) return b.wins - a.wins;
    const totalA = a.wins + a.losses;
    const totalB = b.wins + b.losses;
    const rateA = totalA > 0 ? (a.wins / totalA) : 0;
    const rateB = totalB > 0 ? (b.wins / totalB) : 0;
    if (rateB !== rateA) return rateB - rateA;
    return (b.eloRating || 1500) - (a.eloRating || 1500);
  });

  if (playerList.length === 0) {
    container.innerHTML = `
      <div style="text-align: center; padding: 32px 16px; color: var(--text-muted); font-size: 13px;">
        No public player rankings available in this tier.
      </div>
    `;
    return;
  }

  container.innerHTML = playerList.map((player, idx) => {
    const rank = idx + 1;
    const total = player.wins + player.losses;
    const pct = total > 0 ? Math.round((player.wins / total) * 100) : 0;
    const isCurrent = player.id === state.currentUser?.id;

    return `
      <div class="rank-row rank-${rank} ${isCurrent ? 'style="border-color: var(--primary); background: var(--primary-light);"' : ''}">
        <div class="rank-num">${rank === 1 ? '🥇' : rank === 2 ? '🥈' : rank === 3 ? '🥉' : '#' + rank}</div>
        ${renderAvatar(player.avatarEmoji, "lg", (player.consecutiveBackouts || 0) >= 3)}
        <div class="rank-info">
          <div class="rank-name">${getLadderDisplayName(player)}</div>
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

  const tf = state.selectedLadderTimeframe || "month";
  const deduped = deduplicatePlayers(state.players);
  const visiblePlayers = deduped.filter(p => !p.isStatsHidden);
  const sorted = [...visiblePlayers].sort((a, b) => {
    const connA = getPlayerConnections(a, tf).total;
    const connB = getPlayerConnections(b, tf).total;
    if (connB !== connA) return connB - connA;
    const matchesA = (a.wins || 0) + (a.losses || 0);
    const matchesB = (b.wins || 0) + (b.losses || 0);
    return matchesB - matchesA;
  });

  if (sorted.length === 0) {
    container.innerHTML = `
      <div style="text-align: center; padding: 32px 16px; color: var(--text-muted); font-size: 13px;">
        No public player network rankings available yet.
      </div>
    `;
    return;
  }

  container.innerHTML = sorted.map((player, idx) => {
    const rank = idx + 1;
    const net = getPlayerConnections(player, tf);
    const connections = net.total;
    const isCurrent = player.id === state.currentUser?.id;
    const badgeTitle = getPopularKidsTitle(connections);

    return `
      <div class="rank-row ${isCurrent ? 'style="border-color: var(--accent); background: var(--accent-light);"' : ''}">
        <div class="rank-num">${rank === 1 ? '👑' : '#' + rank}</div>
        ${renderAvatar(player.avatarEmoji, "lg", (player.consecutiveBackouts || 0) >= 3)}
        <div class="rank-info">
          <div class="rank-name">${getLadderDisplayName(player)}</div>
          <div style="display: flex; align-items: center; gap: 6px; margin-top: 3px;">
            <span style="font-size: 11px; font-weight: 800; color: #a855f7; background: rgba(168, 85, 247, 0.12); padding: 2px 7px; border-radius: 6px; display: inline-flex; align-items: center; gap: 3px;">
              ${badgeTitle}
            </span>
          </div>
          <div class="rank-sub" style="margin-top: 3px;">${net.partnersCount} Partners • ${net.opponentsCount} Opponents</div>
        </div>
        <div class="rank-stats">
          <div style="font-size:16px; font-weight:800; color:var(--accent);">${connections} Connections</div>
        </div>
      </div>
    `;
  }).join("");
}

window.toggleLadderTimeframe = function(type) {
  const monthBox = document.getElementById("ladder-filter-month");
  const yearBox = document.getElementById("ladder-filter-year");
  const subtitleEl = document.getElementById("ladder-timeframe-subtitle");

  if (type === "month") {
    if (monthBox && monthBox.checked) {
      if (yearBox) yearBox.checked = false;
      state.selectedLadderTimeframe = "month";
    } else {
      state.selectedLadderTimeframe = "allTime";
    }
  } else if (type === "year") {
    if (yearBox && yearBox.checked) {
      if (monthBox) monthBox.checked = false;
      state.selectedLadderTimeframe = "year";
    } else {
      state.selectedLadderTimeframe = "allTime";
    }
  }

  if (subtitleEl) {
    if (state.selectedLadderTimeframe === "month") {
      subtitleEl.textContent = "Last 30 days rankings and social catalysts on the sand";
    } else if (state.selectedLadderTimeframe === "year") {
      subtitleEl.textContent = "Past year rankings and social catalysts on the sand";
    } else {
      subtitleEl.textContent = "All-time rankings and social catalysts on the sand";
    }
  }

  renderLadder();
  renderPopularKids();
};

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

  // Rating badge & Gender badge
  const ratingEl = document.getElementById("profile-rating-badge");
  if (ratingEl) ratingEl.textContent = `${user.rating || "B"} TIER`;

  const genderEl = document.getElementById("profile-gender-badge");
  if (genderEl) {
    const isFem = String(user.gender || "").toLowerCase() === "female";
    genderEl.textContent = isFem ? "♀ Female" : "♂ Male";
    genderEl.style.background = isFem ? "rgba(236, 72, 153, 0.15)" : "rgba(59, 130, 246, 0.15)";
    genderEl.style.color = isFem ? "#db2777" : "#2563eb";
  }

  // Stars & Flaker
  const starsEl = document.getElementById("profile-stars");
  if (starsEl) {
    starsEl.textContent = `⭐ ${formatStarRating(user)} (${user.starRatingCount || 0} reviews)`;
  }

  const flakerBadge = document.getElementById("profile-flaker-badge");
  if (flakerBadge) {
    flakerBadge.style.display = ((user.consecutiveBackouts || 0) >= 3) ? "block" : "none";
  }

  // Privacy header badge
  const privHeaderBadge = document.getElementById("profile-header-privacy-badge");
  if (privHeaderBadge) {
    privHeaderBadge.style.display = user.isStatsHidden ? "block" : "none";
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

  // Privacy Toggle & Badge in Profile Card
  const hideToggle = document.getElementById("profile-hide-stats-toggle");
  if (hideToggle) hideToggle.checked = !!user.isStatsHidden;

  const privBadge = document.getElementById("profile-privacy-badge");
  if (privBadge) privBadge.style.display = user.isStatsHidden ? "inline-block" : "none";

  const isRoot = isRootUser(user);

  // Test Push button - only visible to Root Admin
  const testPushBtn = document.getElementById("btn-test-push");
  if (testPushBtn) {
    testPushBtn.style.display = isRoot ? "inline-flex" : "none";
  }

  // Demo Mode Profile Switcher - strictly restricted to 4087869405
  const demoCard = document.getElementById("demo-mode-card");
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

window.toggleHideStats = (val) => {
  const user = state.currentUser;
  if (!user) return;
  user.isStatsHidden = !!val;

  const idx = state.players.findIndex(p => p.id === user.id);
  if (idx !== -1) {
    state.players[idx] = user;
  }

  state.saveLocal();
  savePlayerToFirestore(user);
  renderProfile();
  renderLadder();
  renderPopularKids();
  showToast(user.isStatsHidden ? "🔒 Stats hidden from public ladders & profiles" : "🌍 Stats visible on public ladders");
};

window.openEditProfileModal = () => {
  const user = state.currentUser;
  if (!user) return;
  const modal = document.getElementById("edit-profile-modal");
  if (!modal) return;

  document.getElementById("edit-profile-name").value = user.name || "";
  document.getElementById("edit-profile-nickname").value = user.nickname || "";
  document.getElementById("edit-profile-phone").value = user.phoneNumber || "";
  document.getElementById("edit-profile-rating").value = user.rating || "B";
  const editGenderEl = document.getElementById("edit-profile-gender");
  if (editGenderEl) editGenderEl.value = user.gender || "Male";

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

  const editHideToggle = document.getElementById("edit-profile-hide-stats");
  if (editHideToggle) editHideToggle.checked = !!user.isStatsHidden;

  const currentAvatar = user.avatarEmoji || "slug";
  window.selectedEditProfileAvatar = currentAvatar;
  document.querySelectorAll("#edit-profile-avatars .avatar-btn").forEach(btn => {
    const btnAvatar = btn.dataset.avatar;
    const isSelected = (btnAvatar === currentAvatar) ||
                       (getCustomAvatarImage(btnAvatar) && getCustomAvatarImage(btnAvatar) === getCustomAvatarImage(currentAvatar)) ||
                       (isMustangAvatar(btnAvatar) && isMustangAvatar(currentAvatar)) ||
                       (btnAvatar === "✝️" && (currentAvatar === "✝️" || currentAvatar === "cross")) ||
                       (btnAvatar === "ichthys" && (currentAvatar === "ichthys" || currentAvatar === "christian_fish"));
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
  const gender = document.getElementById("edit-profile-gender")?.value || user.gender || "Male";
  const phoneNumber = document.getElementById("edit-profile-phone").value.trim();
  const rating = document.getElementById("edit-profile-rating").value;
  const homeBeach = document.getElementById("edit-profile-beach").value;
  const bio = document.getElementById("edit-profile-bio").value.trim();
  const avatarEmoji = window.selectedEditProfileAvatar || user.avatarEmoji || "slug";
  const hideStatsEl = document.getElementById("edit-profile-hide-stats");
  const isStatsHidden = hideStatsEl ? hideStatsEl.checked : !!user.isStatsHidden;

  if (!name) {
    showToast("Please enter your name.");
    return;
  }

  user.name = name;
  user.nickname = nickname;
  user.gender = gender;
  user.phoneNumber = phoneNumber;
  user.rating = rating;
  user.homeBeach = homeBeach;
  user.bio = bio;
  user.avatarEmoji = avatarEmoji;
  user.isStatsHidden = isStatsHidden;

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
  renderPopularKids();
  renderMatches();
  showToast("Profile updated & synced successfully!");
};

// PUSH & IN-APP NOTIFICATION HELPERS
function escapeHtml(str) {
  if (!str) return "";
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

function formatTimeAgo(isoString) {
  if (!isoString) return "Just now";
  const diffMs = Date.now() - new Date(isoString).getTime();
  const diffMins = Math.floor(diffMs / 60000);
  if (diffMins < 1) return "Just now";
  if (diffMins < 60) return `${diffMins}m ago`;
  const diffHours = Math.floor(diffMins / 60);
  if (diffHours < 24) return `${diffHours}h ago`;
  const diffDays = Math.floor(diffHours / 24);
  return `${diffDays}d ago`;
}

function getNotificationIcon(type) {
  switch (type) {
    case "Match Confirmed": return "🏐";
    case "Match Update": return "🔔";
    case "Match Chat": return "💬";
    case "Score Logged": return "🏆";
    case "Queue Update": return "⚡️";
    case "Ladder Update": return "📈";
    case "Popular Kids Badge": return "👑";
    case "Tournament": return "🥇";
    default: return "🔔";
  }
}

export function updatePushStatusBadge() {
  const badge = document.getElementById("push-status-badge");
  const btn = document.getElementById("btn-enable-push");
  if (!badge) return;

  if (window.AndroidBridge) {
    badge.textContent = "Android Push: Active 🔔";
    badge.style.background = "#dcfce7";
    badge.style.color = "#15803d";
    if (btn) {
      btn.textContent = "Android Alerts Active ✅";
      btn.classList.replace("btn-primary", "btn-outline");
    }
    return;
  }

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

export async function triggerWebPushNotification(title, body, options = {}) {
  // 1. Android Native Push Bridge
  if (window.AndroidBridge && typeof window.AndroidBridge.postNotification === "function") {
    try {
      window.AndroidBridge.postNotification(title, body);
    } catch (e) {
      console.warn("AndroidBridge notification error:", e);
    }
  }

  // 2. Web Standard Notifications API
  if ("Notification" in window && Notification.permission === "granted") {
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
        } else {
          new Notification(title, { body, icon: "assets/slug.png" });
        }
      } else {
        new Notification(title, { body, icon: "assets/slug.png" });
      }
    } catch (e) {
      console.warn("Web Notification error:", e);
    }
  }

  // 3. In-App Notification Center History
  if (!options.skipHistory) {
    window.addAppNotification({
      title,
      message: body,
      type: options.type || "Match Confirmed",
      relatedGameId: options.relatedGameId || null
    }, false);
  }
}

window.addAppNotification = function(notifItem, shouldTriggerPush = true) {
  if (!state.notifications) state.notifications = [];
  const newItem = {
    id: notifItem.id || ("notif-" + Date.now() + "-" + Math.random().toString(36).substr(2, 4)),
    title: notifItem.title || "Notification",
    message: notifItem.message || "",
    type: notifItem.type || "Match Confirmed",
    timestamp: notifItem.timestamp || new Date().toISOString(),
    isRead: false,
    relatedGameId: notifItem.relatedGameId || null
  };

  state.notifications.unshift(newItem);
  if (state.notifications.length > 50) {
    state.notifications = state.notifications.slice(0, 50);
  }
  state.saveLocal();
  window.updateNotificationBadge();
  if (document.getElementById("modal-notifications")?.classList.contains("active")) {
    window.renderNotificationsList();
  }

  if (shouldTriggerPush) {
    triggerWebPushNotification(newItem.title, newItem.message, { skipHistory: true });
  }
};

window.updateNotificationBadge = function() {
  const dot = document.getElementById("notifications-badge-dot");
  if (!dot) return;
  const notifs = state.notifications || [];
  const unreadCount = notifs.filter(n => !n.isRead).length;
  dot.style.display = unreadCount > 0 ? "block" : "none";
};

window.renderNotificationsList = function() {
  const container = document.getElementById("notifications-modal-list");
  if (!container) return;

  const notifs = state.notifications || [];
  if (notifs.length === 0) {
    container.innerHTML = `
      <div style="text-align: center; padding: 36px 16px; color: var(--text-muted, #64748b);">
        <div style="font-size: 36px; margin-bottom: 8px;">🔕</div>
        <div style="font-weight: 700; font-size: 15px; color: var(--text-primary, #0f172a); margin-bottom: 4px;">No notifications yet</div>
        <div style="font-size: 13px; line-height: 1.4;">You will get notified whenever an auto-match is confirmed or match scores are logged!</div>
      </div>
    `;
    return;
  }

  container.innerHTML = notifs.map(n => {
    const isUnread = !n.isRead;
    const icon = getNotificationIcon(n.type);
    const timeAgo = formatTimeAgo(n.timestamp || n.date);
    return `
      <div class="notification-card" style="display: flex; gap: 12px; padding: 12px; border-radius: 12px; background: ${isUnread ? 'rgba(234, 88, 12, 0.08)' : 'var(--bg-subtle, #f8fafc)'}; border: 1px solid ${isUnread ? 'rgba(234, 88, 12, 0.3)' : 'var(--border-color, #e2e8f0)'}; align-items: flex-start; transition: all 0.2s;">
        <div style="width: 38px; height: 38px; border-radius: 50%; background: rgba(234, 88, 12, 0.15); display: flex; align-items: center; justify-content: center; font-size: 18px; flex-shrink: 0;">
          ${icon}
        </div>
        <div style="flex: 1; min-width: 0;">
          <div style="display: flex; justify-content: space-between; align-items: baseline; gap: 8px; margin-bottom: 3px;">
            <div style="font-weight: ${isUnread ? '700' : '600'}; font-size: 14px; color: ${isUnread ? '#ea580c' : 'var(--text-primary, #0f172a)'}; line-height: 1.3;">
              ${escapeHtml(n.title)}
            </div>
            <div style="font-size: 11px; color: var(--text-muted, #64748b); flex-shrink: 0; font-weight: 500;">
              ${timeAgo}
            </div>
          </div>
          <div style="font-size: 13px; color: var(--text-secondary, #334155); line-height: 1.4;">
            ${escapeHtml(n.message)}
          </div>
        </div>
        ${isUnread ? '<div style="width: 8px; height: 8px; border-radius: 50%; background: #ea580c; flex-shrink: 0; margin-top: 4px;"></div>' : ''}
      </div>
    `;
  }).join("");
};

window.openNotificationsModal = function() {
  const modal = document.getElementById("modal-notifications");
  if (!modal) return;
  modal.classList.add("active");
  window.renderNotificationsList();

  if (window.AndroidBridge && typeof window.AndroidBridge.requestPermission === "function") {
    try {
      window.AndroidBridge.requestPermission();
    } catch (e) {}
  }
};

window.closeNotificationsModal = function() {
  document.getElementById("modal-notifications")?.classList.remove("active");
};

window.markAllNotificationsRead = function() {
  if (state.notifications) {
    state.notifications.forEach(n => n.isRead = true);
    state.saveLocal();
  }
  window.renderNotificationsList();
  window.updateNotificationBadge();
  showToast("All notifications marked as read ✓");
};

window.enablePushNotifications = async () => {
  if (window.AndroidBridge && typeof window.AndroidBridge.requestPermission === "function") {
    try {
      window.AndroidBridge.requestPermission();
      showToast("Requesting Android notification permission... 🔔");
      setTimeout(() => {
        triggerWebPushNotification("🏐 Notifications Enabled!", "You'll now receive instant alerts when your set games are locked.");
        updatePushStatusBadge();
      }, 1000);
      return;
    } catch (e) {
      console.warn("AndroidBridge requestPermission error:", e);
    }
  }

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
  const title = "🏐 Volleyball Match Alert";
  const body = "Saturday Morning AA Doubles at Main Beach Court #2 is locked!";
  triggerWebPushNotification(title, body, { type: "Match Confirmed" });
  showToast("Test notification dispatched! 🔔");
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

  // If player isn't logged in, they cannot access Set games, Auto-Match, or Profile. Only Ladders and Volleyball are visible.
  if (!state.currentUser && normalizedId !== "ladders" && normalizedId !== "volleyball") {
    if (typeof window.showAuthModal === "function") {
      window.showAuthModal();
    }
    const activeTab = document.querySelector(".tab-content.active");
    if (!activeTab || (activeTab.id !== "tab-ladders" && activeTab.id !== "tab-volleyball")) {
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
    if (normalizedId === "volleyball") {
      if (typeof window.renderVolleyballTab === "function") {
        window.renderVolleyballTab();
      }
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
  const gender = document.getElementById("signup-gender")?.value || "Male";
  const rating = document.getElementById("signup-rating")?.value || "Intermediate";
  const homeBeach = document.getElementById("signup-beach")?.value || "Main Beach";
  const avatar = window.selectedSignupAvatarEmoji || "slug";
  const errEl = document.getElementById("signup-error");

  if (!phone) {
    showToast("Please enter your mobile phone number.");
    return;
  }

  const cleanPhone = phone.replace(/\D/g, "");
  if (!cleanPhone) {
    showToast("Please enter a valid phone number.");
    return;
  }

  // Enforce single account per phone number
  const existingPlayer = state.players.find(p => {
    const pCleaned = (p.phoneNumber || "").replace(/\D/g, "");
    return (pCleaned && pCleaned === cleanPhone) || p.phoneNumber === phone;
  });

  if (existingPlayer) {
    showToast("This phone number is already registered! Please log in.");
    if (errEl) {
      errEl.textContent = "This phone number is already registered. Please log in.";
      errEl.style.display = "block";
    }
    return;
  }

  if (errEl) {
    errEl.style.display = "none";
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
    gender,
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

  // Auto-promote first eligible player from waitlist if spots opened
  let promotedPlayerName = null;
  if (!game.waitlistPlayerIds) game.waitlistPlayerIds = [];
  const eligibleIdx = getEligibleWaitlistIndex(game);
  if (eligibleIdx >= 0) {
    const promotedId = game.waitlistPlayerIds.splice(eligibleIdx, 1)[0];
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

// Format Default Game Title: e.g. "Wednesday COED 9/16/26 3PM"
export function formatDefaultGameTitle(dateObj, genderCategory = "COED") {
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
  
  let divStr = "";
  const cat = (genderCategory || "").toUpperCase();
  if (cat === "COED") {
    divStr = "COED ";
  } else if (cat === "F" || cat === "FEMALE") {
    divStr = "F ";
  } else if (cat === "M" || cat === "MALE") {
    divStr = "M ";
  } else if (cat === "OPEN") {
    divStr = "Open ";
  }
  
  return `${dayName} ${divStr}${month}/${day}/${year} ${timeStr}`;
}

window.handleDivisionCheckboxChange = (prefix, changedCb) => {
  const checkboxes = document.querySelectorAll(`input[name='${prefix}-division-cb']`);
  if (changedCb.checked) {
    checkboxes.forEach(cb => {
      if (cb !== changedCb) cb.checked = false;
    });
  }
};

export function getSelectedDivision(prefix) {
  const checked = document.querySelector(`input[name='${prefix}-division-cb']:checked`);
  return checked ? checked.value : "OPEN";
}

export function setSelectedDivision(prefix, value) {
  const val = (value || "OPEN").toUpperCase();
  const checkboxes = document.querySelectorAll(`input[name='${prefix}-division-cb']`);
  checkboxes.forEach(cb => {
    cb.checked = (cb.value.toUpperCase() === val);
  });
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
  const genderCategory = getSelectedDivision("create");
  const maxPlayers = parseInt(document.getElementById("create-max-players")?.value) || 4;
  const format = document.getElementById("create-format")?.value || "Best of 3 Sets (21-21-15)";
  const courtLocation = document.getElementById("create-beach").value;
  const courtNumber = document.getElementById("create-court").value.trim() || "Court #1";
  const scheduledDateInput = document.getElementById("create-date").value;
  const scheduledDate = new Date(scheduledDateInput).toISOString();
  const notes = document.getElementById("create-notes").value.trim();

  const defaultTitle = formatDefaultGameTitle(new Date(scheduledDateInput), genderCategory);
  const newGame = {
    id: "game-" + Date.now(),
    title: defaultTitle,
    targetRating,
    allowedRatings: allowedRatings.length > 0 ? allowedRatings : [targetRating],
    genderCategory,
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

let currentAddPlayerGameId = null;

window.openAddPlayerModal = (gameId) => {
  const game = state.games.find(g => g.id === gameId);
  if (!game) return;
  currentAddPlayerGameId = gameId;
  const searchInput = document.getElementById("add-player-search");
  if (searchInput) searchInput.value = "";
  window.renderAddPlayerModalList();
  const modal = document.getElementById("modal-add-player-to-game");
  if (modal) modal.classList.add("active");
};

window.closeAddPlayerModal = () => {
  const modal = document.getElementById("modal-add-player-to-game");
  if (modal) modal.classList.remove("active");
  currentAddPlayerGameId = null;
};

window.renderAddPlayerModalList = () => {
  const container = document.getElementById("add-player-list");
  if (!container || !currentAddPlayerGameId) return;

  const game = state.games.find(g => g.id === currentAddPlayerGameId);
  if (!game) return;

  const gamePlayerIds = [...(game.team1PlayerIds || []), ...(game.team2PlayerIds || [])];
  const searchInput = document.getElementById("add-player-search");
  const query = (searchInput ? searchInput.value : "").trim().toLowerCase();

  const availablePlayers = (state.players || [])
    .filter(p => !gamePlayerIds.includes(p.id))
    .filter(p => {
      if (!query) return true;
      const nameMatch = (p.name || "").toLowerCase().includes(query);
      const nickMatch = (p.nickname || "").toLowerCase().includes(query);
      return nameMatch || nickMatch;
    })
    .sort((a, b) => (a.name || "").localeCompare(b.name || ""));

  if (availablePlayers.length === 0) {
    container.innerHTML = `
      <div style="text-align: center; color: var(--text-muted, #8e8e93); padding: 24px 12px; font-size: 13px;">
        No available players found.
      </div>
    `;
    return;
  }

  container.innerHTML = availablePlayers.map(p => {
    // Format: FirstName(Nickname) like Shannon(The Rock)
    const rawName = String(p.name || "").trim();
    const parts = rawName.split(/\s+/).filter(Boolean);
    const firstName = parts[0] || "Player";
    const rawNick = String(p.nickname || "").trim();
    const cleanNick = rawNick.replace(/^\((.*)\)$/, '$1').trim();
    let displayName;
    if (cleanNick && cleanNick.toLowerCase() !== "player" && cleanNick.toLowerCase() !== firstName.toLowerCase()) {
      displayName = `${firstName}(${cleanNick})`;
    } else {
      displayName = rawName || firstName || "Player";
    }

    const rating = p.rating || "B";
    const ratingBadge = `<span class="badge-tier-pill badge-tier-${rating.toLowerCase()}">${rating}</span>`;
    const homeBeach = p.homeBeach || "Main Beach";
    const elo = p.eloRating ?? 1500;

    // Avatar
    let avatarContent;
    if (p.avatarUrl) {
      avatarContent = `<img src="${p.avatarUrl}" style="width: 100%; height: 100%; object-fit: cover; border-radius: 50%;">`;
    } else {
      avatarContent = renderAvatarContent(p.avatarEmoji || "🏐");
    }

    return `
      <div style="display: flex; align-items: center; justify-content: space-between; padding: 10px 12px; background: var(--bg, #f8fafc); border: 1px solid var(--border, rgba(60,60,67,0.12)); border-radius: 12px; gap: 10px;">
        <div style="display: flex; align-items: center; gap: 10px; min-width: 0; flex: 1;">
          <div style="width: 40px; height: 40px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 26px; line-height: 1; background: rgba(0,0,0,0.04); flex-shrink: 0; overflow: hidden; border: 1px solid var(--border, rgba(0,0,0,0.08));">
            ${avatarContent}
          </div>
          <div style="display: flex; flex-direction: column; min-width: 0; flex: 1;">
            <div style="font-weight: 700; font-size: 14px; color: var(--text-main, #000000); white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">
              ${displayName}
            </div>
            <div style="display: flex; align-items: center; gap: 6px; font-size: 11px; color: var(--text-muted, #8e8e93); margin-top: 2px; flex-wrap: wrap;">
              ${ratingBadge}
              <span>•</span>
              <span style="white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 120px;">${homeBeach}</span>
              <span>•</span>
              <span style="white-space: nowrap; font-weight: 600;">Elo: ${elo}</span>
            </div>
          </div>
        </div>
        <button type="button" class="btn btn-sm" style="background: #10b981; color: white; border: none; font-weight: 700; padding: 6px 14px; font-size: 12px; border-radius: 8px; cursor: pointer; flex-shrink: 0;" onclick="window.addPlayerToGameWeb('${game.id}', '${p.id}')">
          + Add
        </button>
      </div>
    `;
  }).join('');
};

window.addPlayerToGameWeb = (gameId, playerId) => {
  const game = state.games.find(g => g.id === gameId);
  if (!game || !state.currentUser) return;

  const currentUserId = state.currentUser.id;
  const isHost = (game.hostPlayerId === currentUserId) || (game.team1PlayerIds && game.team1PlayerIds[0] === currentUserId) || (state.currentUser && state.currentUser.isRoot);
  if (!isHost) {
    showToast("Only the match host or admin can add players.");
    return;
  }

  const allPlayers = [...(game.team1PlayerIds || []), ...(game.team2PlayerIds || [])];
  if (allPlayers.includes(playerId)) {
    showToast("Player is already in this game.");
    return;
  }

  const playerObj = state.getPlayer(playerId);
  if (!playerObj) {
    showToast("Player not found.");
    return;
  }

  const genderCheck = checkPlayerGenderJoinable(game, playerObj);
  if (!genderCheck.allowed) {
    showToast(genderCheck.message || "Player cannot join due to division restrictions.");
    return;
  }

  // Remove from waitlist if they were on it
  if (game.waitlistPlayerIds && game.waitlistPlayerIds.includes(playerId)) {
    game.waitlistPlayerIds = game.waitlistPlayerIds.filter(id => id !== playerId);
  }

  if (!game.team1PlayerIds) game.team1PlayerIds = [];
  if (!game.team2PlayerIds) game.team2PlayerIds = [];

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
  window.closeAddPlayerModal();

  const pName = playerObj.nickname ? `${playerObj.name} (${playerObj.nickname})` : playerObj.name;
  showToast(`Added ${pName} to the game!`);

  // Dispatch APNs push
  const token = playerObj.deviceToken;
  const hostPlayer = state.getPlayer(currentUserId);
  const hostName = hostPlayer ? (hostPlayer.nickname || hostPlayer.name) : "The host";
  if (token && token !== state.currentUser?.deviceToken) {
    fetch("/api/send-push", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        tokens: [token],
        title: "🎉 Added to Game",
        body: `${hostName} added you to '${game.title || "Match"}'!`,
        gameId: game.id
      })
    }).catch(err => console.log("Push note:", err));
  }
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

    ${(isHost || isRoot) ? `
      <button type="button" class="btn btn-outline" style="justify-content: flex-start; gap: 8px; font-weight: 700; color: #10b981; border-color: #6ee7b7; padding: 10px 14px;" onclick="window.closeAdminActionsModal(); window.openAddPlayerModal('${game.id}')">
        <span style="font-size: 16px;">👤➕</span>
        <span>+ Add Player to Game</span>
      </button>
    ` : ''}

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
  setSelectedDivision("edit", game.genderCategory || "OPEN");
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
  game.genderCategory = getSelectedDivision("edit");
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
export function formatGameShareTitle(game) {
  if (!game) return "Join Volleyball Match";
  const d = parseGameDate(game.scheduledDate || game.scheduledTime);
  if (isNaN(d.getTime())) return "Join Volleyball Match";
  const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
  const shortDay = days[d.getDay()];
  let hours = d.getHours();
  const minutes = d.getMinutes();
  const ampm = hours >= 12 ? "PM" : "AM";
  hours = hours % 12;
  hours = hours ? hours : 12;
  const timeStr = minutes === 0 ? `${hours}${ampm}` : `${hours}:${String(minutes).padStart(2, "0")}${ampm}`;
  return `Join vb ${shortDay} at ${timeStr}`;
}
window.formatGameShareTitle = formatGameShareTitle;

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

  const shareTitle = formatGameShareTitle(game);
  if (titleEl) titleEl.textContent = shareTitle;
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
  const game = state.games.find(g => g.id === window.activeQRGameId);
  const shareTitle = formatGameShareTitle(game);
  const shareUrl = getGameShareUrl(window.activeQRGameId);
  const textToCopy = `${shareTitle}\n${shareUrl}`;

  navigator.clipboard.writeText(textToCopy).then(() => {
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
    showToast(`Copied: "${shareTitle}"`);
  }).catch(() => {
    navigator.clipboard.writeText(shareUrl).catch(() => {});
    showToast("Share link copied to clipboard!");
  });
};

window.shareGameLink = async () => {
  if (!window.activeQRGameId) return;
  const game = state.games.find(g => g.id === window.activeQRGameId);
  const shareTitle = formatGameShareTitle(game);
  const shareUrl = getGameShareUrl(window.activeQRGameId);

  if (navigator.share) {
    try {
      await navigator.share({
        title: shareTitle,
        text: `${shareTitle}\n`,
        url: shareUrl
      });
      showToast("Game link shared!");
    } catch (err) {
      if (err.name !== "AbortError") {
        window.copyGameQRLink();
      }
    }
  } else {
    window.copyGameQRLink();
  }
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

    const shareTitle = formatGameShareTitle(game);
    document.title = `${shareTitle} • Volleyball Match`;

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
              <div style="font-weight:700; font-size:14px;">${getPlayerDisplayName(p)}</div>
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
        const nick = p ? getPlayerDisplayName(p) : `Player ${i + 1}`;
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
    const base = p ? getPlayerDisplayName(p) : "Player";
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

    const shuffledCourtGroups = [];
    for (let c = 0; c < courtCount; c++) {
      shuffledCourtGroups.push([...players.slice(c * 4, (c + 1) * 4)].sort(() => Math.random() - 0.5));
    }

    // 3 rounds interleaved across courts: all courts play Set 1 simultaneously, then Set 2, then Set 3
    for (let round = 1; round <= 3; round++) {
      for (let c = 0; c < courtCount; c++) {
        const courtPlayers = shuffledCourtGroups[c];
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
      const existingMatches = parentGame.subMatches || [];
      const offset = existingMatches.length;
      const newSubMatches = window.currentGeneratedMatches.map((m, idx) => {
        const s1 = (m.s1 !== undefined && m.s1 !== "" && m.s1 !== null) ? parseInt(m.s1) : null;
        const s2 = (m.s2 !== undefined && m.s2 !== "" && m.s2 !== null) ? parseInt(m.s2) : null;
        const isComp = Boolean(s1 !== null && s2 !== null && !isNaN(s1) && !isNaN(s2));
        const winner = isComp ? (s1 > s2 ? 1 : 2) : null;
        const matchNum = offset + idx + 1;
        return {
          id: "sub_" + Date.now() + "_" + (offset + idx),
          matchNumber: matchNum,
          courtNumber: m.courtNumber || "Court #1",
          setNumber: matchNum,
          team1PlayerIds: [resolvePlayerId(m.team1[0]), resolvePlayerId(m.team1[1])],
          team2PlayerIds: [resolvePlayerId(m.team2[0]), resolvePlayerId(m.team2[1])],
          restingPlayerIds: (m.resting || []).map(resolvePlayerId),
          team1Score: s1,
          team2Score: s2,
          isCompleted: isComp,
          winningTeam: winner
        };
      });

      parentGame.subMatches = [...existingMatches, ...newSubMatches];
      saveGameToFirestore(parentGame);
      state.saveLocal();
      window.closeRandomTeamsModal();
      window.currentEditingGameId = null;
      renderMatches();
      showToast(`Appended ${newSubMatches.length} matches to ${parentGame.title}! Total: ${parentGame.subMatches.length} matches.`);
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

// ==========================================
// TOURNAMENT MODULE FOR WEB
// ==========================================
window.currentTournamentFilter = "upcoming";
window.activeTournamentId = null;
window.activeTournamentDivision = "Coed Novice";
window.activeTournamentSubTab = "pools";

const DIVISION_CONFIG = [
  { name: "2v2 Coed Novice", icon: "👫", gender: "COED", skill: "Novice", teamSize: 2, maxRating: "Novice" },
  { name: "2v2 Coed Intermediate", icon: "👫", gender: "COED", skill: "Intermediate", teamSize: 2 },
  { name: "4v4 Coed", icon: "🏐", gender: "COED", skill: "Open", teamSize: 4 },
  { name: "2v2 Men's Intermediate", icon: "👨", gender: "M", skill: "Intermediate", teamSize: 2 }
];

export function deduplicateTournaments(tournaments) {
  if (!Array.isArray(tournaments)) return [];
  const result = [];
  const staleDocIdsToDelete = new Set();

  for (const t of tournaments) {
    if (!t) continue;
    const tId = t.id ? String(t.id).trim() : "";
    const tRawId = t.rawId ? String(t.rawId).trim() : "";
    const tTitle = (t.title || "").trim().toLowerCase();
    const tDate = typeof t.date === "string" ? t.date.split("T")[0] : "";

    // Find if an existing item in result matches this tournament
    const existingIdx = result.findIndex(e => {
      const eId = e.id ? String(e.id).trim() : "";
      const eRawId = e.rawId ? String(e.rawId).trim() : "";
      const eTitle = (e.title || "").trim().toLowerCase();
      const eDate = typeof e.date === "string" ? e.date.split("T")[0] : "";

      // 1. Direct ID match
      if (tId && eId && tId === eId) return true;
      // 2. Direct rawId match
      if (tRawId && eRawId && tRawId === eRawId) return true;
      // 3. Cross ID match
      if (tId && eRawId && tId === eRawId) return true;
      if (tRawId && eId && tRawId === eId) return true;
      // 4. Same title and date
      if (tTitle && eTitle && tTitle === eTitle && tDate && eDate && tDate === eDate) return true;
      return false;
    });

    if (existingIdx !== -1) {
      // Merge tournament records to preserve registered teams, free agents, and matches
      const existing = result[existingIdx];

      // If one of them has a Firestore document ID that differs from canonical, flag the shadow doc for cleanup
      const shadowDocId = t._docId || (t.id !== existing.id ? t.id : null);
      if (shadowDocId && shadowDocId !== existing.id && shadowDocId !== existing.rawId) {
        staleDocIdsToDelete.add(shadowDocId);
      }

      // Merge teams without duplicate players
      const mergedTeams = [...(existing.teams || [])];
      for (const tm of (t.teams || [])) {
        const alreadyIn = mergedTeams.some(m => 
          (m.id && tm.id && m.id === tm.id) ||
          (m.player1Id && tm.player1Id && m.player1Id === tm.player1Id && m.division === tm.division)
        );
        if (!alreadyIn) mergedTeams.push(tm);
      }
      existing.teams = mergedTeams;

      // Merge free agents without duplicate players
      const mergedFA = [...(existing.freeAgents || [])];
      for (const fa of (t.freeAgents || [])) {
        const alreadyIn = mergedFA.some(m => 
          (m.id && fa.id && m.id === fa.id) ||
          (m.playerId && fa.playerId && m.playerId === fa.playerId && m.division === fa.division)
        );
        if (!alreadyIn) mergedFA.push(fa);
      }
      existing.freeAgents = mergedFA;

      // Keep matches if existing has none
      if ((!existing.matches || existing.matches.length === 0) && Array.isArray(t.matches) && t.matches.length > 0) {
        existing.matches = t.matches;
      }

      // Keep more complete notes / fields
      if (!existing.notes && t.notes) existing.notes = t.notes;
      if (!existing.hostPlayerId && t.hostPlayerId) existing.hostPlayerId = t.hostPlayerId;
      if (!existing.teamFormat && t.teamFormat) existing.teamFormat = t.teamFormat;
      if (t.rawId && !existing.rawId) existing.rawId = t.rawId;
    } else {
      result.push({ ...t });
    }
  }

  // Delete redundant duplicate docs from Firestore in background
  if (staleDocIdsToDelete.size > 0) {
    for (const staleId of staleDocIdsToDelete) {
      deleteTournamentFromFirestore(staleId).catch(() => {});
    }
  }

  return result;
}
window.deduplicateTournaments = deduplicateTournaments;

window.openTournamentsModal = function() {
  const modal = document.getElementById("tournaments-modal");
  if (!modal) return;
  modal.classList.add("active");
  window.renderTournamentsList();
};

window.closeTournamentsModal = function() {
  document.getElementById("tournaments-modal")?.classList.remove("active");
};

window.setTournamentFilter = function(filter) {
  window.currentTournamentFilter = filter;
  ["upcoming", "my", "past"].forEach(f => {
    const btn = document.getElementById("tourn-filter-" + f);
    if (btn) btn.classList.toggle("active", f === filter);
  });
  window.renderTournamentsList();
};

window.renderTournamentsList = function() {
  const container = document.getElementById("tournaments-list");
  if (!container) return;

  state.tournaments = deduplicateTournaments(state.tournaments || []);

  const currentUserId = state.currentUser?.id;
  const list = (state.tournaments || []).filter(t => {
    if (window.currentTournamentFilter === "my") {
      if (!currentUserId) return false;
      const isReg = (t.teams || []).some(tm => tm.player1Id === currentUserId || tm.player2Id === currentUserId || tm.player3Id === currentUserId || tm.player4Id === currentUserId) ||
                    (t.freeAgents || []).some(fa => fa.playerId === currentUserId);
      const isHost = t.hostPlayerId && isSamePlayer(t.hostPlayerId, currentUserId);
      const isCoHost = (t.coHostPlayerIds || []).some(id => isSamePlayer(id, currentUserId));
      return isReg || isHost || isCoHost;
    }
    if (window.currentTournamentFilter === "past") {
      return t.status === "completed";
    }
    return t.status !== "completed";
  });

  list.sort((a, b) => {
    const da = parseGameDate(a.date).getTime();
    const db = parseGameDate(b.date).getTime();
    if (window.currentTournamentFilter === "past") {
      return db - da;
    }
    return da - db;
  });

  if (list.length === 0) {
    let emptyTitle = "No Upcoming Tournaments";
    let emptyDesc = "Be the first to host a beach tournament for the community!";
    if (window.currentTournamentFilter === "my") {
      emptyTitle = "No Registered Tournaments";
      emptyDesc = "You haven't signed up for or hosted any tournaments yet.";
    } else if (window.currentTournamentFilter === "past") {
      emptyTitle = "No Past Tournaments";
      emptyDesc = "Completed beach tournaments will be archived here.";
    }

    container.innerHTML = `
      <div style="text-align: center; padding: 48px 16px; color: rgba(255, 255, 255, 0.6);">
        <div style="font-size: 44px; margin-bottom: 12px;">🏆</div>
        <div style="font-weight: 800; font-size: 17px; color: #ffffff; margin-bottom: 6px;">${emptyTitle}</div>
        <div style="font-size: 13px; color: rgba(255, 255, 255, 0.6); max-width: 280px; margin: 0 auto 18px auto; line-height: 1.4;">${emptyDesc}</div>
        <button type="button" class="btn btn-primary" onclick="window.openCreateTournamentModal()" style="background: #ea580c; border: none; font-weight: 800; padding: 10px 20px; border-radius: 12px; font-size: 14px; display: inline-flex; align-items: center; gap: 6px;">
          <span>➕</span> Host Tournament
        </button>
      </div>
    `;
    return;
  }

  container.innerHTML = list.map((t, idx) => renderTournamentCardHtml(t, currentUserId, idx)).join("");
};

window.openTournamentDetail = function(tournamentId) {
  window.activeTournamentId = tournamentId;
  const modal = document.getElementById("tournament-detail-modal");
  if (!modal) return;
  modal.classList.add("active");
  window.renderTournamentDetail();
};

window.closeTournamentDetailModal = function() {
  document.getElementById("tournament-detail-modal")?.classList.remove("active");
};

window.setTournamentDivision = function(divisionName) {
  window.activeTournamentDivision = divisionName;
  window.renderTournamentDetail();
};

window.calculatePoolStandings = function(teams, matches) {
  const standings = (teams || []).map(team => {
    let played = 0;
    let wins = 0;
    let losses = 0;
    let pointsFor = 0;
    let pointsAgainst = 0;

    (matches || []).forEach(m => {
      if (m.status !== "completed") return;
      if (m.team1Id === team.id) {
        played++;
        const s1 = parseInt(m.team1Score, 10) || 0;
        const s2 = parseInt(m.team2Score, 10) || 0;
        pointsFor += s1;
        pointsAgainst += s2;
        if (s1 > s2) wins++;
        else if (s2 > s1) losses++;
      } else if (m.team2Id === team.id) {
        played++;
        const s1 = parseInt(m.team1Score, 10) || 0;
        const s2 = parseInt(m.team2Score, 10) || 0;
        pointsFor += s2;
        pointsAgainst += s1;
        if (s2 > s1) wins++;
        else if (s1 > s2) losses++;
      }
    });

    const pointDifferential = pointsFor - pointsAgainst;
    const winRate = played > 0 ? wins / played : 0;

    return {
      team,
      matchesPlayed: played,
      wins,
      losses,
      pointsFor,
      pointsAgainst,
      pointDifferential,
      winRate
    };
  });

  standings.sort((a, b) => {
    if (b.wins !== a.wins) return b.wins - a.wins;
    if (b.pointDifferential !== a.pointDifferential) return b.pointDifferential - a.pointDifferential;
    return b.pointsFor - a.pointsFor;
  });

  return standings;
};

window.setTournamentSubTab = function(tabName) {
  window.activeTournamentSubTab = tabName;
  ["pools", "bracket", "roster", "info"].forEach(t => {
    const btn = document.getElementById("td-tab-" + t);
    if (btn) btn.classList.toggle("active", t === tabName);
  });
  window.renderTournamentDetail();
};

window.formatPhoneNumber = function(phone) {
  if (!phone) return "";
  const digits = String(phone).replace(/\D/g, "");
  if (digits.length === 10) {
    return `(${digits.slice(0, 3)}) ${digits.slice(3, 6)}-${digits.slice(6)}`;
  } else if (digits.length === 11 && digits.startsWith("1")) {
    return `+1 (${digits.slice(1, 4)}) ${digits.slice(4, 7)}-${digits.slice(7)}`;
  }
  return phone;
};

window.formatFirstLastInit = function(fullName) {
  if (!fullName || typeof fullName !== 'string') return '';
  const trimmed = fullName.trim();
  if (!trimmed) return '';

  if (trimmed.includes('/')) {
    return trimmed.split('/').map(part => window.formatFirstLastInit(part)).join('/');
  }

  const parts = trimmed.split(/\s+/).filter(Boolean);
  if (parts.length <= 1) {
    return parts[0] || '';
  }

  const first = parts[0];
  const last = parts[parts.length - 1];

  if (/^[A-Za-z]\.?$/.test(last)) {
    return `${first} ${last.replace('.', '')}.`;
  }

  return `${first} ${last.charAt(0).toUpperCase()}.`;
};

window.getTeamPlayerDisplay = function(team, tournament) {
  if (!team) return '';

  const playerIds = [team.player1Id, team.player2Id, team.player3Id, team.player4Id].filter(Boolean);
  const resolvedNames = [];

  for (const pid of playerIds) {
    const p = (state.players || []).find(item => item.id === pid);
    if (p) {
      const pName = p.name || p.displayName || p.nickname || '';
      if (pName) {
        resolvedNames.push(window.formatFirstLastInit(pName));
      }
    }
  }

  if (resolvedNames.length > 0) {
    return resolvedNames.join('/');
  }

  const directNames = [team.p1Name, team.p2Name, team.p3Name, team.p4Name].filter(Boolean);
  if (directNames.length > 0) {
    return directNames.map(n => window.formatFirstLastInit(n)).join('/');
  }

  // Demo team name mapping fallback
  const rawName = (team.teamName || '').toLowerCase();
  if (rawName.includes('sandstorm')) {
    return 'Lauren L./Peter T.';
  } else if (rawName.includes('spike force')) {
    return 'Alicia M./Emily S.';
  } else if (rawName.includes('net ninjas')) {
    return 'Billy K./Harshal P.';
  } else if (rawName.includes('ace bandits')) {
    return 'Lucas V./Chloe B.';
  } else if (rawName.includes('block party')) {
    return 'Kai R./Taylor J.';
  } else if (rawName.includes('sun spikers')) {
    return 'Maya L./Carlos G.';
  } else if (rawName.includes('coast crushers')) {
    return 'Sam R./Jordan H.';
  } else if (rawName.includes('dune diggers')) {
    return 'Alex M./Chris P.';
  }

  if (team.teamName && team.teamName.includes('/')) {
    return window.formatFirstLastInit(team.teamName);
  }
  if (team.teamName && team.teamName.includes('&')) {
    return team.teamName.split('&').map(part => window.formatFirstLastInit(part)).join('/');
  }

  return team.teamName || 'TBD';
};

window.renderTournamentDetail = function() {
  const targetId = window.activeTournamentId ? String(window.activeTournamentId).trim() : "";
  const t = (state.tournaments || []).find(item => 
    (item.id && String(item.id).trim() === targetId) ||
    (item.rawId && String(item.rawId).trim() === targetId)
  );
  if (!t) return;

  const allowedDivs = t.allowedDivisions || DIVISION_CONFIG.map(c => c.name);
  if (!allowedDivs.includes(window.activeTournamentDivision)) {
    window.activeTournamentDivision = allowedDivs[0] || "Coed Novice";
  }

  const isRoot = isRootUser(state.currentUser);
  const isCoHost = (t.coHostPlayerIds || []).some(id => isSamePlayer(id, state.currentUser?.id));
  const isHost = (t.hostPlayerId && isSamePlayer(t.hostPlayerId, state.currentUser?.id)) || isCoHost || isRoot;
  const isPrimaryHost = (t.hostPlayerId && isSamePlayer(t.hostPlayerId, state.currentUser?.id)) || isRoot;

  // Render Header
  const headerContainer = document.getElementById("tournament-detail-header");
  if (headerContainer) {
    const d = new Date(t.date);
    const hostPlayer = t.hostPlayerId ? state.getPlayer(t.hostPlayerId) : null;
    const hostName = hostPlayer ? (window.formatFirstLastInit ? window.formatFirstLastInit(hostPlayer.name) : hostPlayer.name) : "Organizer";
    const coHosts = (t.coHostPlayerIds || []).map(id => state.getPlayer(id)).filter(Boolean);
    const coHostNames = coHosts.map(p => window.formatFirstLastInit ? window.formatFirstLastInit(p.name) : p.name).join(', ');

    headerContainer.innerHTML = `
      <div style="display: flex; justify-content: space-between; align-items: flex-start; gap: 8px;">
        <div>
          <div style="display: flex; gap: 8px; align-items: center; margin-bottom: 4px;">
            <div style="font-size: 11px; font-weight: 800; color: #ea580c; text-transform: uppercase;">BEACH TOURNAMENT</div>
            <div style="font-size: 11px; font-weight: 800; color: #0891b2; background: rgba(8,145,178,0.1); padding: 2px 8px; border-radius: 20px;">
              ${t.teamFormat === '4v4' ? '🏐 4v4 Quads' : '👥 2v2 Doubles'}
            </div>
          </div>
          <h2 style="font-size: 18px; font-weight: 800; margin: 2px 0 4px 0; color: var(--text-main, #0f172a);">${t.title}</h2>
          <div style="font-size: 12px; color: var(--text-muted, #64748b);">
            📅 ${d.toLocaleDateString("en-US", { weekday: "short", month: "short", day: "numeric" })} • 📍 ${t.location} (${(t.courts || []).join(', ')})
          </div>
          <div style="font-size: 11px; color: var(--text-muted, #64748b); margin-top: 4px; display: flex; align-items: center; gap: 6px; flex-wrap: wrap;">
            <span style="display: inline-flex; align-items: center; gap: 3px;">👑 <b>Host:</b> ${hostName}</span>
            ${coHostNames ? `<span style="color: #cbd5e1;">•</span> <span style="display: inline-flex; align-items: center; gap: 3px; color: #0284c7;">👥 <b>Co-Hosts:</b> ${coHostNames}</span>` : ''}
          </div>
        </div>

        ${isHost ? `
          <div style="display: flex; gap: 6px; align-items: center; flex-shrink: 0; flex-wrap: wrap; justify-content: flex-end;">
            ${isPrimaryHost ? `
              <button type="button" class="btn btn-outline" style="padding: 5px 10px; font-size: 11px; font-weight: 700; color: #0284c7; border-color: #bae6fd;" onclick="window.openManageCoHostsModal('${t.id}')">
                👥 Co-Hosts
              </button>
            ` : ''}
            <button type="button" class="btn btn-outline" style="padding: 5px 10px; font-size: 11px; font-weight: 700;" onclick="window.openEditTournamentModal('${t.id}')">
              ✏️ Edit
            </button>
            ${isPrimaryHost ? `
              <button type="button" class="btn btn-outline" style="padding: 5px 10px; font-size: 11px; font-weight: 700; color: #dc2626; border-color: #fca5a5;" onclick="window.deleteTournament('${t.id}')">
                🗑️ Delete
              </button>
            ` : ''}
          </div>
        ` : ''}
      </div>
    `;
  }

  // Render Division Pills
  const pillsContainer = document.getElementById("tournament-division-pills");
  if (pillsContainer) {
    pillsContainer.innerHTML = allowedDivs.map(divName => {
      const conf = DIVISION_CONFIG.find(c => c.name === divName) || { icon: "🏐", name: divName };
      const count = (t.teams || []).filter(tm => tm.division === divName).length;
      const isSelected = window.activeTournamentDivision === divName;
      return `
        <button type="button" onclick="window.setTournamentDivision('${divName}')" style="display: flex; align-items: center; gap: 6px; padding: 6px 12px; border-radius: 999px; font-size: 12px; font-weight: 700; white-space: nowrap; border: 1px solid ${isSelected ? '#ea580c' : 'var(--border, #cbd5e1)'}; background: ${isSelected ? '#ea580c' : 'var(--surface, #ffffff)'}; color: ${isSelected ? '#ffffff' : 'var(--text-main, #1e293b)'}; cursor: pointer;">
          <span>${conf.icon}</span>
          <span>${divName}</span>
          <span style="font-size: 10px; font-weight: 800; padding: 1px 6px; border-radius: 999px; background: ${isSelected ? 'rgba(255,255,255,0.25)' : 'var(--bg-alt, #f1f5f9)'}; color: ${isSelected ? '#ffffff' : 'var(--text-muted, #64748b)'};">${count}/${t.maxTeamsPerDivision || 8}</span>
        </button>
      `;
    }).join('');
  }

  // Render SubTab Body
  const bodyContainer = document.getElementById("tournament-detail-body");
  if (!bodyContainer) return;

  const currentDiv = window.activeTournamentDivision;
  const divTeams = (t.teams || []).filter(tm => tm.division === currentDiv);
  const divFreeAgents = (t.freeAgents || []).filter(fa => fa.division === currentDiv);
  const divMatches = (t.matches || []).filter(m => m.division === currentDiv);

  if (window.activeTournamentSubTab === "pools") {
    const poolAName = "Pool A";
    const poolBName = "Pool B";
    const poolAMatches = divMatches.filter(m => m.poolName === poolAName);
    const poolBMatches = divMatches.filter(m => m.poolName === poolBName);
    const hasPools = poolAMatches.length > 0 || poolBMatches.length > 0;
    const poolATeams = divTeams.filter(tm => tm.poolName === poolAName || !tm.poolName);
    const poolBTeams = divTeams.filter(tm => tm.poolName === poolBName);
    const standingsA = window.calculatePoolStandings(divTeams.filter(tm => tm.poolName === poolAName), poolAMatches);
    const standingsB = window.calculatePoolStandings(divTeams.filter(tm => tm.poolName === poolBName), poolBMatches);
    const bracketMatches = divMatches.filter(m => m.stage !== "pool" && !m.poolName);

    const isMatchPlayed = m => m.score1 !== null && m.score2 !== null && (m.score1 > 0 || m.score2 > 0 || m.winningTeamId);
    const playedA = poolAMatches.filter(isMatchPlayed).length;
    const totalA = poolAMatches.length;
    const playedB = poolBMatches.filter(isMatchPlayed).length;
    const totalB = poolBMatches.length;
    const totalPoolMatches = totalA + totalB;
    const playedPoolMatches = playedA + playedB;
    const percentPlayed = totalPoolMatches > 0 ? Math.round((playedPoolMatches / totalPoolMatches) * 100) : 0;
    const remainingMatches = totalPoolMatches - playedPoolMatches;
    const allPoolsComplete = playedPoolMatches === totalPoolMatches && totalPoolMatches > 0;

    const renderPoolStatusDashboard = () => {
      if (!hasPools) return '';
      return `
        <div style="background: var(--surface, #ffffff); border: 1px solid var(--border, #cbd5e1); border-radius: 14px; padding: 14px 16px; box-shadow: 0 2px 6px rgba(0,0,0,0.03); margin-bottom: 2px;">
          <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
            <div style="display: flex; align-items: center; gap: 6px;">
              <span style="font-size: 14px;">📊</span>
              <span style="font-size: 13px; font-weight: 800; color: var(--text-main, #0f172a);">Pools Status</span>
            </div>
            <div style="font-size: 11px; font-weight: 800; color: ${allPoolsComplete ? '#16a34a' : '#ea580c'}; background: ${allPoolsComplete ? 'rgba(22,163,74,0.1)' : 'rgba(234,88,12,0.1)'}; padding: 3px 8px; border-radius: 999px;">
              ${playedPoolMatches} / ${totalPoolMatches} Games Played (${percentPlayed}%)
            </div>
          </div>

          <!-- Progress Bar -->
          <div style="width: 100%; height: 8px; background: var(--bg-alt, #e2e8f0); border-radius: 999px; overflow: hidden; margin-bottom: 10px;">
            <div style="width: ${percentPlayed}%; height: 100%; background: ${allPoolsComplete ? '#16a34a' : 'linear-gradient(90deg, #ea580c, #f59e0b)'}; border-radius: 999px; transition: width 0.3s ease;"></div>
          </div>

          <!-- Pool Breakdown Chips -->
          <div style="display: flex; gap: 8px; flex-wrap: wrap; align-items: center; justify-content: space-between;">
            <div style="display: flex; gap: 8px; flex-wrap: wrap;">
              <div style="font-size: 11px; font-weight: 700; padding: 4px 8px; border-radius: 8px; background: var(--bg-alt, #f8fafc); border: 1px solid var(--border, #e2e8f0); color: var(--text-main, #334155);">
                🏊 <b>Pool A:</b> ${playedA}/${totalA} ${playedA === totalA && totalA > 0 ? '✅' : ''}
              </div>
              <div style="font-size: 11px; font-weight: 700; padding: 4px 8px; border-radius: 8px; background: var(--bg-alt, #f8fafc); border: 1px solid var(--border, #e2e8f0); color: var(--text-main, #334155);">
                🏊 <b>Pool B:</b> ${playedB}/${totalB} ${playedB === totalB && totalB > 0 ? '✅' : ''}
              </div>
            </div>
            <div style="font-size: 11px; font-weight: 700; color: var(--text-muted, #64748b);">
              ${remainingMatches > 0 ? `⏳ ${remainingMatches} game${remainingMatches === 1 ? '' : 's'} remaining` : '🎉 All pool games complete!'}
            </div>
          </div>

          ${allPoolsComplete && bracketMatches.length === 0 ? `
            <div style="margin-top: 12px; padding: 10px; border-radius: 10px; background: rgba(22,163,74,0.08); border: 1px solid rgba(22,163,74,0.25); display: flex; justify-content: space-between; align-items: center; gap: 8px; flex-wrap: wrap;">
              <div style="font-size: 12px; font-weight: 700; color: #15803d;">
                🎉 All pool games finished! Ready to seed playoffs.
              </div>
              <button type="button" class="btn btn-primary" style="padding: 6px 14px; font-size: 12px; font-weight: 800; background: #16a34a; border-color: #15803d;" onclick="window.generatePlayoffBracket('${t.id}', '${currentDiv}')">
                🚀 Start Single Elimination Playoffs
              </button>
            </div>
          ` : ''}
        </div>
      `;
    };

    const renderStandingsTable = (poolName, standings, matches) => {
      const poolPlayedCount = matches.filter(isMatchPlayed).length;
      const poolTotalCount = matches.length;
      const isPoolDone = poolPlayedCount === poolTotalCount && poolTotalCount > 0;
      return `
      <div style="display: flex; flex-direction: column; gap: 10px; margin-bottom: 16px;">
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <span style="font-size: 12px; font-weight: 900; color: #0284c7; text-transform: uppercase;">
            ${poolName} <span style="font-size: 11px; font-weight: 700; color: var(--text-muted, #64748b);">(${poolPlayedCount}/${poolTotalCount} Played)</span> ${isPoolDone ? '✅' : ''}
          </span>
          <span style="font-size: 11px; font-weight: 800; color: #16a34a;">All Teams Advance to Playoffs</span>
        </div>

        <!-- Table Card -->
        <div style="background: var(--surface, #ffffff); border: 1px solid var(--border, #e2e8f0); border-radius: 12px; overflow: hidden;">
          <table style="width: 100%; border-collapse: collapse; font-size: 12px;">
            <thead>
              <tr style="background: var(--bg-alt, #f8fafc); border-bottom: 1px solid var(--border, #e2e8f0); color: var(--text-muted, #64748b); font-size: 10px; font-weight: 800; text-transform: uppercase;">
                <th style="padding: 8px 10px; text-align: left; width: 28px;">#</th>
                <th style="padding: 8px 10px; text-align: left;">Team</th>
                <th style="padding: 8px 8px; text-align: center; width: 34px;">MP</th>
                <th style="padding: 8px 8px; text-align: center; width: 44px;">W-L</th>
                <th style="padding: 8px 10px; text-align: right; width: 38px;">+/-</th>
              </tr>
            </thead>
            <tbody>
              ${standings.length === 0 ? `
                <tr><td colspan="5" style="padding: 16px; text-align: center; color: var(--text-muted, #94a3b8);">No teams seeded yet</td></tr>
              ` : standings.map((row, idx) => `
                <tr style="border-bottom: 1px solid var(--border, #f1f5f9); background: rgba(22,163,74,0.03);">
                  <td style="padding: 8px 10px; font-weight: 900; color: #16a34a;">
                    ${idx + 1} 🟢
                  </td>
                  <td style="padding: 8px 10px; font-weight: 700; color: var(--text-main, #0f172a);">
                    ${window.getTeamPlayerDisplay(row.team, t)}
                  </td>
                  <td style="padding: 8px 8px; text-align: center; color: var(--text-muted, #64748b);">${row.matchesPlayed}</td>
                  <td style="padding: 8px 8px; text-align: center; font-weight: 700; color: ${row.wins > 0 ? '#16a34a' : 'inherit'};">${row.wins}-${row.losses}</td>
                  <td style="padding: 8px 10px; text-align: right; font-weight: 700; color: ${row.pointDifferential >= 0 ? '#16a34a' : '#dc2626'};">
                    ${row.pointDifferential >= 0 ? `+${row.pointDifferential}` : row.pointDifferential}
                  </td>
                </tr>
              `).join('')}
            </tbody>
          </table>
        </div>

        <!-- Matches in this pool -->
        ${matches.length > 0 ? `
          <div style="display: flex; flex-direction: column; gap: 8px; margin-top: 4px;">
            ${matches.map(m => window.renderMatchCardHTML(t, m)).join('')}
          </div>
        ` : ''}
      </div>
    `;
    };

    bodyContainer.innerHTML = `
      <div style="display: flex; flex-direction: column; gap: 14px;">
        ${!hasPools ? `
          <div style="text-align: center; padding: 24px 16px; background: var(--bg-alt, #f8fafc); border-radius: 14px; border: 1px solid var(--border, #e2e8f0);">
            <div style="font-size: 32px; margin-bottom: 6px;">🏊</div>
            <div style="font-weight: 800; color: var(--text-main, #0f172a); font-size: 15px;">Auto Pool Play Generator</div>
            <div style="font-size: 12px; color: var(--text-muted, #64748b); max-width: 360px; margin: 4px auto 12px auto; line-height: 1.4;">
              Automatically divides registered teams (${divTeams.length}) into Pool A & Pool B based on team Elo rating. Every team advances to the single-elimination playoff bracket!
            </div>
            <button type="button" class="btn btn-primary" style="padding: 10px 20px; font-weight: 800; font-size: 13px;" onclick="window.generatePoolPlay('${t.id}', '${currentDiv}')" ${divTeams.length < 4 ? 'disabled' : ''}>
              ✨ Generate Pools (Snake Seeding)
            </button>
            ${divTeams.length < 4 ? `
              <div style="font-size: 11px; color: #ea580c; margin-top: 8px;">At least 4 teams required to seed pool play.</div>
              <button type="button" class="btn btn-outline" style="font-size: 12px; padding: 6px 14px; margin-top: 10px; font-weight: 700;" onclick="window.addDemoTournamentTeams('${t.id}', '${currentDiv}')">
                ⚡ Quick-Add Demo Teams
              </button>
            ` : ''}
          </div>
        ` : `
          ${renderPoolStatusDashboard()}
          ${renderStandingsTable(poolAName, standingsA, poolAMatches)}
          ${renderStandingsTable(poolBName, standingsB, poolBMatches)}

          ${bracketMatches.length === 0 ? `
            <div style="text-align: center; padding: 18px; background: rgba(234,88,12,0.06); border: 1px solid rgba(234,88,12,0.2); border-radius: 14px; margin-top: 6px;">
              <div style="font-weight: 800; color: var(--text-main, #0f172a); font-size: 14px;">Ready for Single Elimination Playoffs?</div>
              <div style="font-size: 12px; color: var(--text-muted, #64748b); margin: 2px 0 10px 0;">Every team advances to the single-elimination playoff bracket seeded by pool finish!</div>
              <button type="button" class="btn btn-primary" style="padding: 8px 18px; font-weight: 800; font-size: 12px;" onclick="window.generatePlayoffBracket('${t.id}', '${currentDiv}')">
                🏆 Generate Single Elimination Bracket
              </button>
            </div>
          ` : ''}

          ${isHost ? `
            <div style="text-align: center; margin-top: 4px;">
              <button type="button" class="btn btn-outline" style="font-size: 11px; padding: 4px 12px;" onclick="if(confirm('Re-seed pool play? Existing match scores in pools will be reset.')) window.generatePoolPlay('${t.id}', '${currentDiv}')">
                🔄 Re-Seed Pools
              </button>
            </div>
          ` : ''}
        `}
      </div>
    `;
  } else if (window.activeTournamentSubTab === "bracket") {
    const bracketMatches = divMatches.filter(m => m.stage !== "pool" && !m.poolName);
    const finalMatch = bracketMatches.find(m => m.stage === "final");
    const thirdMatch = bracketMatches.find(m => m.stage === "third_place");
    const semiMatches = bracketMatches.filter(m => m.stage === "semi" || m.stage === "semifinal");
    const quarterMatches = bracketMatches.filter(m => m.stage === "quarter" || m.stage === "quarterfinal");
    const champTeam = finalMatch?.winningTeamId ? (t.teams || []).find(tm => tm.id === finalMatch.winningTeamId) : null;

    bodyContainer.innerHTML = `
      <div style="display: flex; flex-direction: column; gap: 12px;">
        ${bracketMatches.length === 0 ? `
          <div style="text-align: center; padding: 32px 16px; background: var(--bg-alt, #f8fafc); border-radius: 14px; border: 1px solid var(--border, #e2e8f0);">
            <div style="font-size: 36px; margin-bottom: 6px;">🏆</div>
            <div style="font-weight: 800; color: var(--text-main, #0f172a); font-size: 15px;">Playoff Bracket Not Yet Generated</div>
            <div style="font-size: 12px; color: var(--text-muted, #64748b); max-width: 360px; margin: 4px auto 12px auto; line-height: 1.4;">
              Complete pool play matches first. Every single team advances to the single-elimination playoff bracket!
            </div>
            <button type="button" class="btn btn-primary" style="padding: 10px 20px; font-weight: 800; font-size: 13px;" onclick="window.generatePlayoffBracket('${t.id}', '${currentDiv}')">
              ✨ Generate Single Elimination Bracket
            </button>
          </div>
        ` : `
          ${champTeam ? `
            <div style="background: linear-gradient(135deg, #fef3c7, #fffbeb); border: 2px solid #f59e0b; border-radius: 16px; padding: 18px; text-align: center; box-shadow: 0 4px 12px rgba(245,158,11,0.15);">
              <div style="font-size: 32px; margin-bottom: 4px;">👑</div>
              <div style="font-size: 10px; font-weight: 900; color: #b45309; text-transform: uppercase; letter-spacing: 0.05em;">Tournament Champion</div>
              <div style="font-size: 20px; font-weight: 900; color: #78350f; margin-top: 2px;">${window.getTeamPlayerDisplay(champTeam, t)}</div>
              <div style="font-size: 12px; color: #92400e; margin-top: 2px;">Division: ${currentDiv}</div>
            </div>
          ` : ''}

          <!-- Visual Playoff Bracket Tree Chart -->
          ${window.renderPlayoffBracketChartHTML(t, currentDiv, bracketMatches)}

          <!-- Clean Playoff Match Cards List -->
          <div style="display: flex; flex-direction: column; gap: 8px;">
            ${finalMatch ? window.renderPlayoffCleanMatchCardHTML(t, finalMatch) : ''}
            ${thirdMatch ? window.renderPlayoffCleanMatchCardHTML(t, thirdMatch) : ''}
            ${semiMatches.map(m => window.renderPlayoffCleanMatchCardHTML(t, m)).join('')}
            ${quarterMatches.map(m => window.renderPlayoffCleanMatchCardHTML(t, m)).join('')}
          </div>

          ${isHost ? `
            <div style="text-align: center; margin-top: 6px;">
              <button type="button" class="btn btn-outline" style="font-size: 11px; padding: 5px 14px;" onclick="if(confirm('Re-seed playoff bracket? Bracket scores will be reset.')) window.generatePlayoffBracket('${t.id}', '${currentDiv}')">
                🔄 Re-Seed Bracket
              </button>
            </div>
          ` : ''}
        `}
      </div>
    `;
  } else if (window.activeTournamentSubTab === "roster") {
    bodyContainer.innerHTML = `
      <div style="display: flex; flex-direction: column; gap: 16px;">
        <!-- Teams List -->
        <div>
          <div style="font-size: 12px; font-weight: 800; color: #ea580c; text-transform: uppercase; margin-bottom: 8px;">
            Confirmed Teams (${divTeams.length}/${t.maxTeamsPerDivision || 8})
          </div>
          ${divTeams.length === 0 ? `
            <div style="text-align: center; padding: 24px 12px; background: var(--bg-alt, #f8fafc); border-radius: 12px; color: var(--text-muted, #94a3b8); font-size: 12px;">
              No teams registered for ${currentDiv} yet. Be the first to enter!
            </div>
          ` : `
            <div style="display: flex; flex-direction: column; gap: 8px;">
              ${divTeams.map((team, idx) => {
                const p1 = state.players.find(p => p.id === team.player1Id);
                const p2 = team.player2Id ? state.players.find(p => p.id === team.player2Id) : null;
                const p3 = team.player3Id ? state.players.find(p => p.id === team.player3Id) : null;
                const p4 = team.player4Id ? state.players.find(p => p.id === team.player4Id) : null;
                const is4v4 = (t.teamFormat === '4v4');
                const p1Name = p1 ? getPlayerDisplayName(p1) : 'Player 1';
                const p2Name = p2 ? getPlayerDisplayName(p2) : null;
                const p3Name = p3 ? getPlayerDisplayName(p3) : null;
                const p4Name = p4 ? getPlayerDisplayName(p4) : null;
                const playerLine1 = `${p1?.avatarEmoji || '🏐'} ${p1Name} & ${p2 ? `${p2.avatarEmoji || '🏐'} ${p2Name}` : '<i style="color: #ea580c;">Looking for partner</i>'}`;
                const playerLine2 = is4v4 ? `${p3 ? `${p3.avatarEmoji || '🏐'} ${p3Name}` : '<i style="color: #ea580c;">+ Open Spot</i>'} & ${p4 ? `${p4.avatarEmoji || '🏐'} ${p4Name}` : '<i style="color: #ea580c;">+ Open Spot</i>'}` : '';
                return `
                  <div style="display: flex; justify-content: space-between; align-items: center; background: var(--surface, #ffffff); border: 1px solid var(--border, #e2e8f0); border-radius: 12px; padding: 10px 14px;">
                    <div style="display: flex; align-items: center; gap: 10px;">
                      <span style="font-size: 12px; font-weight: 900; color: #ea580c; width: 24px;">#${team.seed || (idx + 1)}</span>
                      <div>
                        <div style="display: flex; align-items: center; gap: 6px;">
                          <span style="font-size: 14px; font-weight: 700; color: var(--text-main, #0f172a);">${team.teamName}</span>
                          ${team.poolName ? `<span style="font-size: 10px; font-weight: 800; color: #0284c7; background: rgba(2,132,199,0.1); padding: 1px 6px; border-radius: 8px;">${team.poolName}</span>` : ''}
                        </div>
                        <div style="font-size: 11px; color: var(--text-muted, #64748b);">
                          ${playerLine1}
                        </div>
                        ${is4v4 ? `<div style="font-size: 11px; color: var(--text-muted, #64748b); margin-top: 2px;">
                          ${playerLine2}
                        </div>` : ''}
                      </div>
                    </div>
                  </div>
                `;
              }).join('')}
            </div>
          `}
        </div>

        <!-- Free Agents Pool -->
        <div>
          <div style="font-size: 12px; font-weight: 800; color: #0284c7; text-transform: uppercase; margin-bottom: 8px;">
            Free Agent Pool (${divFreeAgents.length})
          </div>
          ${divFreeAgents.length === 0 ? `
            <div style="text-align: center; padding: 18px 12px; background: var(--bg-alt, #f8fafc); border-radius: 12px; color: var(--text-muted, #94a3b8); font-size: 12px;">
              No solo free agents waiting in this division.
            </div>
          ` : `
            <div style="display: flex; flex-direction: column; gap: 8px;">
              ${divFreeAgents.map(fa => {
                const p = state.players.find(item => item.id === fa.playerId);
                return `
                  <div style="display: flex; justify-content: space-between; align-items: center; background: var(--surface, #ffffff); border: 1px solid var(--border, #e2e8f0); border-radius: 12px; padding: 8px 12px;">
                    <div style="display: flex; align-items: center; gap: 8px;">
                      <span style="font-size: 20px;">${p?.avatarEmoji || '🏐'}</span>
                      <div>
                        <div style="font-size: 13px; font-weight: 700; color: var(--text-main, #0f172a);">${p ? getPlayerDisplayName(p) : 'Beach Player'}</div>
                        ${fa.notes ? `<div style="font-size: 11px; color: var(--text-muted, #64748b); font-style: italic;">"${fa.notes}"</div>` : ''}
                      </div>
                    </div>
                    <span style="font-size: 11px; font-weight: 800; background: rgba(2, 132, 199, 0.1); color: #0284c7; padding: 2px 8px; border-radius: 999px;">
                      ${p?.rating || 'B'}
                    </span>
                  </div>
                `;
              }).join('')}
            </div>
          `}
        </div>
      </div>
    `;
  } else {
    bodyContainer.innerHTML = `
      <div style="display: flex; flex-direction: column; gap: 14px; font-size: 13px; color: var(--text-main, #334155);">
        <div style="background: var(--bg-alt, #f8fafc); border-radius: 12px; padding: 14px; border: 1px solid var(--border, #e2e8f0);">
          <div style="font-size: 11px; font-weight: 800; color: #ea580c; text-transform: uppercase; margin-bottom: 4px;">Host Notes</div>
          <div style="line-height: 1.5;">${t.notes || "Double elimination format. Official beach volleyball balls provided."}</div>
        </div>

        <div style="background: var(--bg-alt, #f8fafc); border-radius: 12px; padding: 14px; border: 1px solid var(--border, #e2e8f0);">
          <div style="font-size: 11px; font-weight: 800; color: #0284c7; text-transform: uppercase; margin-bottom: 6px;">Tournament Rules</div>
          <ul style="margin: 0; padding-left: 18px; line-height: 1.6; font-size: 12px;">
            <li>Rally scoring to 21 points (win by 2, capped at 23).</li>
            <li>Switch sides every 7 points to balance wind and sunlight conditions.</li>
            <li>No open-hand tips (roll shots, knuckles, or cut-shots only).</li>
            <li>Coed division teams must consist of 1 male and 1 female player.</li>
            <li>Pool play: Round-robin within Pool A and Pool B.</li>
            <li>Playoffs: Top 2 from each pool advance to Semifinals (A1 vs B2, B1 vs A2).</li>
          </ul>
        </div>
      </div>
    `;
  }

  // Render Footer Buttons (Register / Leave)
  const footerContainer = document.getElementById("tournament-detail-footer");
  if (footerContainer) {
    const currentUserId = state.currentUser?.id;
    const isRegistered = currentUserId && (
      (t.teams || []).some(tm => tm.player1Id === currentUserId || tm.player2Id === currentUserId || tm.player3Id === currentUserId || tm.player4Id === currentUserId) ||
      (t.freeAgents || []).some(fa => fa.playerId === currentUserId)
    );

    if (isRegistered) {
      footerContainer.innerHTML = `
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <div style="font-size: 12px; font-weight: 700; color: #16a34a;">
            ✅ You are signed up for this tournament
          </div>
          <button type="button" class="btn btn-outline" style="color: #dc2626; border-color: #fca5a5; padding: 6px 14px; font-size: 12px;" onclick="window.leaveTournament('${t.id}')">
            Leave Tournament
          </button>
        </div>
      `;
    } else {
      footerContainer.innerHTML = `
        <button type="button" class="btn btn-primary" style="width: 100%; font-weight: 800; padding: 12px; font-size: 14px;" onclick="window.openTournamentSignUpModal('${t.id}')">
          🏐 Sign Up for ${currentDiv}
        </button>
      `;
    }
  }
};

window.renderMatchCardHTML = function(tournament, match) {
  const t1 = (tournament.teams || []).find(tm => tm.id === match.team1Id);
  const t2 = (tournament.teams || []).find(tm => tm.id === match.team2Id);
  const isFinal = match.status === "completed";
  const stageName = match.poolName ? match.poolName : (match.stage ? match.stage.replace('_', ' ').toUpperCase() : 'MATCH');
  const name1 = t1 ? window.getTeamPlayerDisplay(t1, tournament) : '<span style="color: var(--text-muted, #94a3b8); font-weight: 400; font-style: italic;">TBD</span>';
  const name2 = t2 ? window.getTeamPlayerDisplay(t2, tournament) : '<span style="color: var(--text-muted, #94a3b8); font-weight: 400; font-style: italic;">TBD</span>';

  return `
    <div style="background: var(--surface, #ffffff); border: 1px solid ${isFinal ? 'rgba(22,163,74,0.3)' : 'var(--border, #e2e8f0)'}; border-radius: 12px; padding: 12px;">
      <div style="display: flex; justify-content: space-between; font-size: 11px; font-weight: 800; color: #ea580c; margin-bottom: 8px;">
        <span style="background: rgba(234,88,12,0.1); padding: 2px 8px; border-radius: 999px;">${stageName} • #${match.matchNumber}</span>
        <span style="color: #0284c7; font-weight: 700;">📍 ${match.courtNumber || 'Court #1'}</span>
      </div>
      <div style="display: flex; justify-content: space-between; align-items: center; font-size: 13px; font-weight: 700; gap: 8px;">
        <div style="flex: 1; text-align: left; color: ${match.winningTeamId === match.team1Id ? '#16a34a' : 'inherit'}; font-weight: ${match.winningTeamId === match.team1Id ? '900' : '700'};">
          ${name1}
          ${match.winningTeamId === match.team1Id ? ' ✓' : ''}
        </div>

        <div style="font-size: 14px; font-weight: 900; background: var(--bg-alt, #f1f5f9); padding: 4px 12px; border-radius: 8px; white-space: nowrap;">
          ${match.team1Score !== undefined && match.team1Score !== null ? `${match.team1Score} - ${match.team2Score}` : 'vs'}
        </div>

        <div style="flex: 1; text-align: right; color: ${match.winningTeamId === match.team2Id ? '#16a34a' : 'inherit'}; font-weight: ${match.winningTeamId === match.team2Id ? '900' : '700'};">
          ${match.winningTeamId === match.team2Id ? '✓ ' : ''}
          ${name2}
        </div>
      </div>

      ${(t1 && t2) ? `
        <div style="margin-top: 10px; padding-top: 8px; border-top: 1px dashed var(--border, #e2e8f0); text-align: center;">
          <button type="button" class="btn btn-outline" style="font-size: 11px; font-weight: 700; color: #ea580c; border-color: rgba(234,88,12,0.3); padding: 3px 12px;" onclick="window.openTournamentScoreModal('${tournament.id}', '${match.id}')">
            ${isFinal ? '✏️ Edit Score' : '⚡️ Report Score'}
          </button>
        </div>
      ` : ''}
    </div>
  `;
};

window.renderPlayoffCleanMatchCardHTML = function(tournament, match) {
  const t1 = (tournament.teams || []).find(tm => tm.id === match.team1Id);
  const t2 = (tournament.teams || []).find(tm => tm.id === match.team2Id);
  const isFinal = match.status === "completed";
  
  let roundTitle = "";
  if (match.stage === "quarter" || match.stage === "quarterfinal") {
    roundTitle = `Quarterfinals #${match.matchNumber || ''} (${match.courtNumber || 'Court #1'})`;
  } else if (match.stage === "semi" || match.stage === "semifinal") {
    roundTitle = `Semifinals #${match.matchNumber || ''} (${match.courtNumber || 'Court #1'})`;
  } else if (match.stage === "final") {
    roundTitle = `Finals (${match.courtNumber || 'Court #1'})`;
  } else if (match.stage === "third_place") {
    roundTitle = `3rd Place Consolation (${match.courtNumber || 'Court #2'})`;
  } else {
    roundTitle = `${match.stage ? match.stage.toUpperCase() : 'PLAYOFF'} (${match.courtNumber || 'Court #1'})`;
  }

  const s1 = match.team1Score !== undefined && match.team1Score !== null ? match.team1Score : "";
  const s2 = match.team2Score !== undefined && match.team2Score !== null ? match.team2Score : "";
  const winner1 = isFinal && match.winningTeamId === match.team1Id;
  const winner2 = isFinal && match.winningTeamId === match.team2Id;

  const seed1 = t1 ? (t1.seed || t1.poolSeed || '•') : '';
  const seed2 = t2 ? (t2.seed || t2.poolSeed || '•') : '';
  const name1 = t1 ? window.getTeamPlayerDisplay(t1, tournament) : '<span style="color: #94a3b8; font-style: italic;">TBD</span>';
  const name2 = t2 ? window.getTeamPlayerDisplay(t2, tournament) : '<span style="color: #94a3b8; font-style: italic;">TBD</span>';

  return `
    <div class="playoff-clean-card" onclick="window.openTournamentScoreModal('${tournament.id}', '${match.id}')">
      <div class="playoff-clean-header">${roundTitle}</div>
      <div style="display: flex; align-items: center; gap: 8px;">
        <div style="flex: 1;">
          <div class="playoff-clean-team-row">
            <span class="playoff-clean-seed">${seed1}</span>
            <span class="playoff-clean-team-name ${winner1 ? 'winner' : ''}">${name1}</span>
            <span class="playoff-clean-score ${winner1 ? 'winner' : ''}">${s1}</span>
          </div>
          <div class="playoff-clean-team-row">
            <span class="playoff-clean-seed">${seed2}</span>
            <span class="playoff-clean-team-name ${winner2 ? 'winner' : ''}">${name2}</span>
            <span class="playoff-clean-score ${winner2 ? 'winner' : ''}">${s2}</span>
          </div>
        </div>
        <span class="playoff-clean-chevron">›</span>
      </div>
    </div>
  `;
};

window.renderPlayoffBracketChartHTML = function(t, division, bracketMatches) {
  const quarterMatches = bracketMatches.filter(m => m.stage === "quarter" || m.stage === "quarterfinal");
  const semiMatches = bracketMatches.filter(m => m.stage === "semi" || m.stage === "semifinal");
  const finalMatch = bracketMatches.find(m => m.stage === "final");

  if (!finalMatch && semiMatches.length === 0) return '';

  const hasQuarters = quarterMatches.length > 0;
  const colWidth = 175;
  const colGap = 36;
  const nodeH = 60;

  let totalW = 0;
  let totalH = 0;
  let svgPaths = [];

  function renderNode(m, top, left, label, isFinal) {
    if (!m) return '';
    const t1 = (t.teams || []).find(tm => tm.id === m.team1Id);
    const t2 = (t.teams || []).find(tm => tm.id === m.team2Id);
    const isCompleted = m.status === "completed";
    const s1 = (m.team1Score !== undefined && m.team1Score !== null) ? m.team1Score : '';
    const s2 = (m.team2Score !== undefined && m.team2Score !== null) ? m.team2Score : '';
    const winner1 = isCompleted && m.winningTeamId === m.team1Id;
    const winner2 = isCompleted && m.winningTeamId === m.team2Id;

    const seed1 = t1 ? (t1.seed || t1.poolSeed || '1') : '';
    const seed2 = t2 ? (t2.seed || t2.poolSeed || '2') : '';
    const name1 = t1 ? window.getTeamPlayerDisplay(t1, t) : '<span style="color: #94a3b8; font-style: italic;">TBD</span>';
    const name2 = t2 ? window.getTeamPlayerDisplay(t2, t) : '<span style="color: #94a3b8; font-style: italic;">TBD</span>';

    return `
      <div class="playoff-node-card ${isCompleted ? 'completed' : ''}" 
           style="position: absolute; top: ${top}px; left: ${left}px; width: ${colWidth}px;" 
           onclick="window.openTournamentScoreModal('${t.id}', '${m.id}')">
        <div class="playoff-node-header">${label}</div>
        <div class="playoff-node-team ${winner1 ? 'winner' : ''}">
          <span class="playoff-node-seed">${seed1}</span>
          <span class="playoff-node-name">${name1}</span>
          <span class="playoff-node-score">${s1}</span>
        </div>
        <div class="playoff-node-team ${winner2 ? 'winner' : ''}">
          <span class="playoff-node-seed">${seed2}</span>
          <span class="playoff-node-name">${name2}</span>
          <span class="playoff-node-score">${s2}</span>
        </div>
        ${isFinal ? '<div class="playoff-node-subtitle">Winner is champion</div>' : ''}
      </div>
    `;
  }

  let nodesHtml = '';

  if (hasQuarters) {
    // 8 Teams: Quarterfinals (col 0) -> Semifinals (col 1) -> Finals (col 2)
    totalH = 346;
    const x0 = 8;
    const x1 = x0 + colWidth + colGap; // 8 + 175 + 36 = 219
    const x2 = x1 + colWidth + colGap; // 219 + 175 + 36 = 430
    totalW = x2 + colWidth + 18;       // 430 + 175 + 18 = 623

    const q0 = quarterMatches[0] || null;
    const q1 = quarterMatches[1] || null;
    const q2 = quarterMatches[2] || null;
    const q3 = quarterMatches[3] || null;

    const s0 = semiMatches[0] || null;
    const s1 = semiMatches[1] || null;

    // Y Centers
    const yQ0 = 42;
    const yQ1 = 126;
    const yQ2 = 216;
    const yQ3 = 300;

    const yS0 = (yQ0 + yQ1) / 2; // 84
    const yS1 = (yQ2 + yQ3) / 2; // 258
    const yF = (yS0 + yS1) / 2;  // 171

    // Render Quarters
    if (q0) nodesHtml += renderNode(q0, yQ0 - nodeH/2, x0, `Quarterfinals #1 (${q0.courtNumber || 'Court #1'})`, false);
    if (q1) nodesHtml += renderNode(q1, yQ1 - nodeH/2, x0, `Quarterfinals #2 (${q1.courtNumber || 'Court #2'})`, false);
    if (q2) nodesHtml += renderNode(q2, yQ2 - nodeH/2, x0, `Quarterfinals #3 (${q2.courtNumber || 'Court #1'})`, false);
    if (q3) nodesHtml += renderNode(q3, yQ3 - nodeH/2, x0, `Quarterfinals #4 (${q3.courtNumber || 'Court #2'})`, false);

    // Render Semis
    if (s0) nodesHtml += renderNode(s0, yS0 - nodeH/2, x1, `Semifinals #1 (${s0.courtNumber || 'Court #1'})`, false);
    if (s1) nodesHtml += renderNode(s1, yS1 - nodeH/2, x1, `Semifinals #2 (${s1.courtNumber || 'Court #2'})`, false);

    // Render Final
    if (finalMatch) nodesHtml += renderNode(finalMatch, yF - nodeH/2, x2, `Finals (${finalMatch.courtNumber || 'Court #1'})`, true);

    // SVG Connectors between Quarters (x0 + colWidth) and Semis (x1)
    const midX0 = x0 + colWidth + (colGap / 2); // 8 + 175 + 18 = 201
    svgPaths.push(`M ${x0 + colWidth} ${yQ0} H ${midX0} V ${yQ1} H ${x0 + colWidth}`);
    svgPaths.push(`M ${midX0} ${yS0} H ${x1}`);

    svgPaths.push(`M ${x0 + colWidth} ${yQ2} H ${midX0} V ${yQ3} H ${x0 + colWidth}`);
    svgPaths.push(`M ${midX0} ${yS1} H ${x1}`);

    // SVG Connectors between Semis (x1 + colWidth) and Finals (x2)
    const midX1 = x1 + colWidth + (colGap / 2); // 219 + 175 + 18 = 412
    svgPaths.push(`M ${x1 + colWidth} ${yS0} H ${midX1} V ${yS1} H ${x1 + colWidth}`);
    svgPaths.push(`M ${midX1} ${yF} H ${x2}`);

  } else {
    // 4 Teams: Semifinals (col 0) -> Finals (col 1)
    totalH = 220;
    const x0 = 8;
    const x1 = x0 + colWidth + colGap; // 8 + 175 + 36 = 219
    totalW = x1 + colWidth + 18;

    const s0 = semiMatches[0] || null;
    const s1 = semiMatches[1] || null;

    const yS0 = 55;
    const yS1 = 165;
    const yF = (yS0 + yS1) / 2; // 110

    if (s0) nodesHtml += renderNode(s0, yS0 - nodeH/2, x0, `Semifinals #1 (${s0.courtNumber || 'Court #1'})`, false);
    if (s1) nodesHtml += renderNode(s1, yS1 - nodeH/2, x0, `Semifinals #2 (${s1.courtNumber || 'Court #2'})`, false);
    if (finalMatch) nodesHtml += renderNode(finalMatch, yF - nodeH/2, x1, `Finals (${finalMatch.courtNumber || 'Court #1'})`, true);

    const midX0 = x0 + colWidth + (colGap / 2);
    svgPaths.push(`M ${x0 + colWidth} ${yS0} H ${midX0} V ${yS1} H ${x0 + colWidth}`);
    svgPaths.push(`M ${midX0} ${yF} H ${x1}`);
  }

  return `
    <div class="playoff-chart-wrapper">
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px; padding: 0 4px;">
        <span style="font-size: 11px; font-weight: 800; color: var(--text-muted, #64748b); text-transform: uppercase; letter-spacing: 0.05em;">
          🏆 Playoff Bracket Tree
        </span>
        <span style="font-size: 10px; color: var(--text-muted, #94a3b8);">
          Scroll horizontally ➔
        </span>
      </div>
      <div class="playoff-chart-scroll" style="height: ${totalH}px;">
        <div style="position: relative; width: ${totalW}px; height: ${totalH}px;">
          <!-- SVG Connector Lines -->
          <svg style="position: absolute; top: 0; left: 0; width: ${totalW}px; height: ${totalH}px; pointer-events: none; z-index: 1;">
            <path d="${svgPaths.join(' ')}" fill="none" stroke="#94a3b8" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
          <!-- Match Nodes -->
          ${nodesHtml}
        </div>
      </div>
      <span class="playoff-chart-hint">›</span>
    </div>
  `;
};

window.addDemoTournamentTeams = function(tournamentId, division) {
  const t = (state.tournaments || []).find(item => 
    (item.id && String(item.id).trim() === String(tournamentId).trim()) ||
    (item.rawId && String(item.rawId).trim() === String(tournamentId).trim())
  );
  if (!t) return;
  t.teams = t.teams || [];
  const currentDivTeams = t.teams.filter(tm => tm.division === division);
  const demoConfigs = [
    { name: "Lauren L./Peter T.", p1Name: "Lauren Larson", p2Name: "Peter Thach", p1: 0, p2: 1 },
    { name: "Alicia M./Emily S.", p1Name: "Alicia Miller", p2Name: "Emily Smith", p1: 2, p2: 3 },
    { name: "Billy K./Harshal P.", p1Name: "Billy King", p2Name: "Harshal Patel", p1: 4, p2: 5 },
    { name: "Lucas V./Chloe B.", p1Name: "Lucas Vance", p2Name: "Chloe Bennett", p1: 6, p2: 7 },
    { name: "Kai R./Taylor J.", p1Name: "Kai Rodriguez", p2Name: "Taylor Jenkins", p1: 0, p2: 4 },
    { name: "Maya L./Carlos G.", p1Name: "Maya Lin", p2Name: "Carlos Gomez", p1: 1, p2: 5 },
    { name: "Sam R./Jordan H.", p1Name: "Sam Rivera", p2Name: "Jordan Hayes", p1: 2, p2: 6 },
    { name: "Alex M./Chris P.", p1Name: "Alex Morgan", p2Name: "Chris Paul", p1: 3, p2: 7 }
  ];
  
  const configsToAdd = currentDivTeams.length === 0 ? demoConfigs : demoConfigs.slice(currentDivTeams.length % demoConfigs.length, (currentDivTeams.length % demoConfigs.length) + 4);
  
  configsToAdd.forEach((item, idx) => {
    const p1 = (state.players && state.players[item.p1]) ? state.players[item.p1].id : `demo-p-${Date.now()}-${idx * 2 + 1}`;
    const p2 = (state.players && state.players[item.p2]) ? state.players[item.p2].id : `demo-p-${Date.now()}-${idx * 2 + 2}`;
    t.teams.push({
      id: "demo-team-" + Date.now() + "-" + (currentDivTeams.length + idx),
      teamName: item.name,
      p1Name: item.p1Name,
      p2Name: item.p2Name,
      player1Id: p1,
      player2Id: p2,
      seed: currentDivTeams.length + idx + 1,
      division: division
    });
  });

  state.saveLocal();
  saveTournamentToFirestore(t);
  showToast(`⚡ Added ${configsToAdd.length} demo teams for ${division}!`);
  window.renderTournamentDetail();
  window.renderTournamentsList();
};

window.generatePoolPlay = function(tournamentId, division) {
  const t = (state.tournaments || []).find(item => 
    (item.id && String(item.id).trim() === String(tournamentId).trim()) ||
    (item.rawId && String(item.rawId).trim() === String(tournamentId).trim())
  );
  if (!t) return;

  const divTeams = (t.teams || []).filter(tm => tm.division === division);
  if (divTeams.length < 4) {
    showToast("At least 4 teams required to seed pool play!");
    return;
  }

  // Calculate average team Elo for seeding
  const seededTeams = divTeams.map(tm => {
    const p1 = state.players.find(p => p.id === tm.player1Id);
    const p2 = tm.player2Id ? state.players.find(p => p.id === tm.player2Id) : null;
    const elo1 = p1?.eloRating || 1500;
    const elo2 = p2 ? (p2.eloRating || 1500) : elo1;
    const avgElo = Math.round((elo1 + elo2) / 2);
    return { ...tm, avgElo };
  });

  seededTeams.sort((a, b) => b.avgElo - a.avgElo);

  // Snake seed into Pool A & Pool B
  const poolATeams = [];
  const poolBTeams = [];

  seededTeams.forEach((tm, idx) => {
    const isPoolA = (idx % 4 === 0 || idx % 4 === 3);
    const poolName = isPoolA ? "Pool A" : "Pool B";
    const teamInPool = {
      ...tm,
      poolName,
      poolSeed: (isPoolA ? poolATeams.length : poolBTeams.length) + 1,
      seed: idx + 1
    };
    if (isPoolA) {
      poolATeams.push(teamInPool);
    } else {
      poolBTeams.push(teamInPool);
    }
  });

  // Update teams in tournament
  const updatedTeamIds = new Set(seededTeams.map(tm => tm.id));
  t.teams = (t.teams || []).filter(tm => !updatedTeamIds.has(tm.id)).concat(poolATeams, poolBTeams);

  // Remove existing pool matches for this division
  t.matches = (t.matches || []).filter(m => !(m.division === division && (m.poolName || m.stage === "pool")));

  const courts = (t.courts && t.courts.length > 0) ? t.courts : ["Court #1", "Court #2"];
  let courtIndex = 0;
  let matchNumber = 1;

  function buildPoolRoundRobin(poolTeams, poolName) {
    const matches = [];
    const n = poolTeams.length;
    for (let i = 0; i < n; i++) {
      for (let j = i + 1; j < n; j++) {
        matches.push({
          id: crypto.randomUUID ? crypto.randomUUID() : 'match_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9),
          division,
          poolName,
          stage: "pool",
          roundNumber: 1,
          matchNumber: matchNumber++,
          courtNumber: courts[courtIndex % courts.length],
          team1Id: poolTeams[i].id,
          team2Id: poolTeams[j].id,
          team1Score: null,
          team2Score: null,
          winningTeamId: null,
          status: "scheduled"
        });
        courtIndex++;
      }
    }
    return matches;
  }

  const poolAMatches = buildPoolRoundRobin(poolATeams, "Pool A");
  const poolBMatches = buildPoolRoundRobin(poolBTeams, "Pool B");

  t.matches = (t.matches || []).concat(poolAMatches, poolBMatches);

  state.saveLocal();
  saveTournamentToFirestore(t);
  showToast(`✅ Pool Play seeded! ${poolAMatches.length + poolBMatches.length} matches created across ${courts.join(', ')}.`);
  window.renderTournamentDetail();
};

window.generatePlayoffBracket = function(tournamentId, division) {
  const t = (state.tournaments || []).find(item => 
    (item.id && String(item.id).trim() === String(tournamentId).trim()) ||
    (item.rawId && String(item.rawId).trim() === String(tournamentId).trim())
  );
  if (!t) return;

  const divTeams = (t.teams || []).filter(tm => tm.division === division);
  const divPoolAMatches = (t.matches || []).filter(m => m.division === division && m.poolName === "Pool A");
  const divPoolBMatches = (t.matches || []).filter(m => m.division === division && m.poolName === "Pool B");

  const poolATeams = divTeams.filter(tm => tm.poolName === "Pool A");
  const poolBTeams = divTeams.filter(tm => tm.poolName === "Pool B");

  const standingsA = window.calculatePoolStandings(poolATeams, divPoolAMatches);
  const standingsB = window.calculatePoolStandings(poolBTeams, divPoolBMatches);
  const totalTeams = standingsA.length + standingsB.length;

  if (totalTeams < 4) {
    showToast("Need at least 4 teams with standings to create playoffs!");
    return;
  }

  // Clear previous bracket matches for this division
  t.matches = (t.matches || []).filter(m => !(m.division === division && m.stage !== "pool" && !m.poolName));

  const courts = (t.courts && t.courts.length > 0) ? t.courts : ["Court #1", "Court #2"];
  const finalMatchId = crypto.randomUUID ? crypto.randomUUID() : 'final_' + Date.now();
  const thirdMatchId = crypto.randomUUID ? crypto.randomUUID() : 'third_' + Date.now();
  const semi1Id = crypto.randomUUID ? crypto.randomUUID() : 'semi1_' + Date.now();
  const semi2Id = crypto.randomUUID ? crypto.randomUUID() : 'semi2_' + Date.now();

  const existingMatches = (t.matches || []).filter(m => m.division === division);
  let matchNumber = existingMatches.reduce((max, m) => Math.max(max, m.matchNumber || 0), 0) + 1;

  const hasQuarterfinals = standingsA.length > 2 || standingsB.length > 2;
  const newMatches = [];

  if (hasQuarterfinals) {
    // QUARTERFINALS (Single Elimination)
    // Cross-pool pairings:
    // Match 1: A1 vs B4 (or bye if no B4) -> Winner to Semi 1 Slot 1
    // Match 2: B2 vs A3 (or bye if no A3) -> Winner to Semi 1 Slot 2
    // Match 3: B1 vs A4 (or bye if no A4) -> Winner to Semi 2 Slot 1
    // Match 4: A2 vs B3 (or bye if no B3) -> Winner to Semi 2 Slot 2
    const a1 = standingsA[0]?.team || null;
    const a2 = standingsA[1]?.team || null;
    const a3 = standingsA[2]?.team || null;
    const a4 = standingsA[3]?.team || null;

    const b1 = standingsB[0]?.team || null;
    const b2 = standingsB[1]?.team || null;
    const b3 = standingsB[2]?.team || null;
    const b4 = standingsB[3]?.team || null;

    let semi1Slot1TeamId = null;
    let semi1Slot2TeamId = null;
    let semi2Slot1TeamId = null;
    let semi2Slot2TeamId = null;

    // QF 1: A1 vs B4
    if (a1 && b4) {
      newMatches.push({
        id: crypto.randomUUID ? crypto.randomUUID() : 'qf1_' + Date.now(),
        division,
        stage: "quarter",
        roundNumber: 2,
        bracketRound: 1,
        matchNumber: matchNumber++,
        courtNumber: courts[0],
        team1Id: a1.id,
        team2Id: b4.id,
        team1Score: null,
        team2Score: null,
        winningTeamId: null,
        status: "scheduled",
        nextMatchId: semi1Id,
        nextMatchSlot: 1
      });
    } else if (a1) {
      semi1Slot1TeamId = a1.id;
    }

    // QF 2: B2 vs A3
    if (b2 && a3) {
      newMatches.push({
        id: crypto.randomUUID ? crypto.randomUUID() : 'qf2_' + Date.now(),
        division,
        stage: "quarter",
        roundNumber: 2,
        bracketRound: 1,
        matchNumber: matchNumber++,
        courtNumber: courts.length > 1 ? courts[1] : courts[0],
        team1Id: b2.id,
        team2Id: a3.id,
        team1Score: null,
        team2Score: null,
        winningTeamId: null,
        status: "scheduled",
        nextMatchId: semi1Id,
        nextMatchSlot: 2
      });
    } else if (b2) {
      semi1Slot2TeamId = b2.id;
    }

    // QF 3: B1 vs A4
    if (b1 && a4) {
      newMatches.push({
        id: crypto.randomUUID ? crypto.randomUUID() : 'qf3_' + Date.now(),
        division,
        stage: "quarter",
        roundNumber: 2,
        bracketRound: 1,
        matchNumber: matchNumber++,
        courtNumber: courts[0],
        team1Id: b1.id,
        team2Id: a4.id,
        team1Score: null,
        team2Score: null,
        winningTeamId: null,
        status: "scheduled",
        nextMatchId: semi2Id,
        nextMatchSlot: 1
      });
    } else if (b1) {
      semi2Slot1TeamId = b1.id;
    }

    // QF 4: A2 vs B3
    if (a2 && b3) {
      newMatches.push({
        id: crypto.randomUUID ? crypto.randomUUID() : 'qf4_' + Date.now(),
        division,
        stage: "quarter",
        roundNumber: 2,
        bracketRound: 1,
        matchNumber: matchNumber++,
        courtNumber: courts.length > 1 ? courts[1] : courts[0],
        team1Id: a2.id,
        team2Id: b3.id,
        team1Score: null,
        team2Score: null,
        winningTeamId: null,
        status: "scheduled",
        nextMatchId: semi2Id,
        nextMatchSlot: 2
      });
    } else if (a2) {
      semi2Slot2TeamId = a2.id;
    }

    // SEMIFINALS
    newMatches.push({
      id: semi1Id,
      division,
      stage: "semi",
      roundNumber: 3,
      bracketRound: 2,
      matchNumber: matchNumber++,
      courtNumber: courts[0],
      team1Id: semi1Slot1TeamId,
      team2Id: semi1Slot2TeamId,
      team1Score: null,
      team2Score: null,
      winningTeamId: null,
      status: "scheduled",
      nextMatchId: finalMatchId,
      nextMatchSlot: 1
    });

    newMatches.push({
      id: semi2Id,
      division,
      stage: "semi",
      roundNumber: 3,
      bracketRound: 2,
      matchNumber: matchNumber++,
      courtNumber: courts.length > 1 ? courts[1] : courts[0],
      team1Id: semi2Slot1TeamId,
      team2Id: semi2Slot2TeamId,
      team1Score: null,
      team2Score: null,
      winningTeamId: null,
      status: "scheduled",
      nextMatchId: finalMatchId,
      nextMatchSlot: 2
    });
  } else {
    // 4 Teams: All 4 teams advance directly to Semifinals (A1 vs B2, B1 vs A2)
    const a1 = standingsA[0]?.team;
    const a2 = standingsA[1]?.team;
    const b1 = standingsB[0]?.team;
    const b2 = standingsB[1]?.team;

    newMatches.push({
      id: semi1Id,
      division,
      stage: "semi",
      roundNumber: 2,
      bracketRound: 1,
      matchNumber: matchNumber++,
      courtNumber: courts[0],
      team1Id: a1 ? a1.id : null,
      team2Id: b2 ? b2.id : null,
      team1Score: null,
      team2Score: null,
      winningTeamId: null,
      status: "scheduled",
      nextMatchId: finalMatchId,
      nextMatchSlot: 1
    });

    newMatches.push({
      id: semi2Id,
      division,
      stage: "semi",
      roundNumber: 2,
      bracketRound: 1,
      matchNumber: matchNumber++,
      courtNumber: courts.length > 1 ? courts[1] : courts[0],
      team1Id: b1 ? b1.id : null,
      team2Id: a2 ? a2.id : null,
      team1Score: null,
      team2Score: null,
      winningTeamId: null,
      status: "scheduled",
      nextMatchId: finalMatchId,
      nextMatchSlot: 2
    });
  }

  // Championship Final
  newMatches.push({
    id: finalMatchId,
    division,
    stage: "final",
    roundNumber: hasQuarterfinals ? 4 : 3,
    bracketRound: hasQuarterfinals ? 3 : 2,
    matchNumber: matchNumber++,
    courtNumber: courts[0],
    team1Id: null,
    team2Id: null,
    team1Score: null,
    team2Score: null,
    winningTeamId: null,
    status: "scheduled"
  });

  // 3rd Place Consolation
  newMatches.push({
    id: thirdMatchId,
    division,
    stage: "third_place",
    roundNumber: hasQuarterfinals ? 4 : 3,
    bracketRound: hasQuarterfinals ? 3 : 2,
    matchNumber: matchNumber++,
    courtNumber: courts.length > 1 ? courts[1] : courts[0],
    team1Id: null,
    team2Id: null,
    team1Score: null,
    team2Score: null,
    winningTeamId: null,
    status: "scheduled"
  });

  t.matches = (t.matches || []).concat(newMatches);

  state.saveLocal();
  saveTournamentToFirestore(t);
  window.setTournamentSubTab("bracket");
  showToast(hasQuarterfinals 
    ? "🏆 Playoff Bracket created! Quarterfinals seeded (all 8 teams advanced to single elimination)." 
    : "🏆 Playoff Bracket created! Semifinals seeded (all teams advanced to single elimination).");
  window.renderTournamentDetail();
};

window.submitTournamentMatchScore = function(tournamentId, matchId, team1Score, team2Score) {
  const t = (state.tournaments || []).find(item => 
    (item.id && String(item.id).trim() === String(tournamentId).trim()) ||
    (item.rawId && String(item.rawId).trim() === String(tournamentId).trim())
  );
  if (!t) return;

  const match = (t.matches || []).find(m => String(m.id).trim() === String(matchId).trim());
  if (!match) return;

  const s1 = parseInt(team1Score, 10);
  const s2 = parseInt(team2Score, 10);
  if (isNaN(s1) || isNaN(s2) || s1 === s2) {
    showToast("Invalid score. Ties are not allowed.");
    return;
  }

  const winningTeamId = s1 > s2 ? match.team1Id : match.team2Id;
  const losingTeamId = s1 > s2 ? match.team2Id : match.team1Id;

  match.team1Score = s1;
  match.team2Score = s2;
  match.winningTeamId = winningTeamId;
  match.status = "completed";

  // Advance winner to next match in bracket if present
  if (match.nextMatchId) {
    const nextMatch = (t.matches || []).find(m => String(m.id).trim() === String(match.nextMatchId).trim());
    if (nextMatch) {
      if (match.nextMatchSlot === 1) {
        nextMatch.team1Id = winningTeamId;
      } else {
        nextMatch.team2Id = winningTeamId;
      }
    }
  }

  // If this was a semifinal, advance loser to 3rd place match
  if (match.stage === "semi" || match.stage === "semifinal") {
    const thirdMatch = (t.matches || []).find(m => m.division === match.division && m.stage === "third_place");
    if (thirdMatch) {
      if (match.nextMatchSlot === 1) {
        thirdMatch.team1Id = losingTeamId;
      } else {
        thirdMatch.team2Id = losingTeamId;
      }
    }
  }

  state.saveLocal();
  saveTournamentToFirestore(t);
  window.closeTournamentScoreModal();
  showToast("✅ Match score submitted! Bracket updated.");
  window.renderTournamentDetail();
};

window.openTournamentScoreModal = function(tournamentId, matchId) {
  const t = (state.tournaments || []).find(item => 
    (item.id && String(item.id).trim() === String(tournamentId).trim()) ||
    (item.rawId && String(item.rawId).trim() === String(tournamentId).trim())
  );
  if (!t) return;
  const match = (t.matches || []).find(m => String(m.id).trim() === String(matchId).trim());
  if (!match) return;

  const t1 = (t.teams || []).find(tm => tm.id === match.team1Id);
  const t2 = (t.teams || []).find(tm => tm.id === match.team2Id);
  if (!t1 || !t2) {
    showToast("Teams are not yet determined for this match.");
    return;
  }

  const name1 = window.getTeamPlayerDisplay(t1, t);
  const name2 = window.getTeamPlayerDisplay(t2, t);

  const s1 = (match.team1Score !== null && match.team1Score !== undefined) ? match.team1Score : 21;
  const s2 = (match.team2Score !== null && match.team2Score !== undefined) ? match.team2Score : 19;

  const modal = document.getElementById("tournament-score-modal");
  const body = document.getElementById("tournament-score-body");
  if (!modal || !body) return;

  const stageName = match.poolName ? match.poolName : (match.stage ? match.stage.replace('_', ' ').toUpperCase() : 'MATCH');

  body.innerHTML = `
    <div style="display: flex; flex-direction: column; gap: 16px;">
      <div style="text-align: center; background: var(--bg-alt, #f8fafc); padding: 10px; border-radius: 12px;">
        <span style="font-size: 11px; font-weight: 800; color: #ea580c; text-transform: uppercase;">${stageName}</span>
        <div style="font-size: 12px; color: var(--text-muted, #64748b); margin-top: 2px;">Match #${match.matchNumber} • ${match.courtNumber || 'Court #1'}</div>
      </div>

      <div style="display: flex; justify-content: space-around; align-items: center; background: var(--surface, #ffffff); border: 1px solid var(--border, #e2e8f0); border-radius: 14px; padding: 16px;">
        <div style="text-align: center; flex: 1;">
          <div style="font-size: 14px; font-weight: 800; color: var(--text-main, #0f172a); margin-bottom: 8px; line-height: 1.2;">${name1}</div>
          <div style="display: flex; align-items: center; justify-content: center; gap: 8px;">
            <button type="button" class="btn btn-outline" style="width: 34px; height: 34px; padding: 0; font-size: 18px; font-weight: 900;" onclick="window.adjustTournScore('team1', -1)">-</button>
            <input type="number" id="ts-score-1" data-team-name="${name1}" value="${s1}" min="0" max="99" style="width: 54px; text-align: center; font-size: 24px; font-weight: 900; border-radius: 8px; border: 1px solid var(--border, #cbd5e1); padding: 4px;" onchange="window.updateTournScorePreview()">
            <button type="button" class="btn btn-outline" style="width: 34px; height: 34px; padding: 0; font-size: 18px; font-weight: 900; color: #ea580c;" onclick="window.adjustTournScore('team1', 1)">+</button>
          </div>
        </div>

        <div style="font-size: 18px; font-weight: 900; color: var(--text-muted, #94a3b8); padding: 0 10px;">vs</div>

        <div style="text-align: center; flex: 1;">
          <div style="font-size: 14px; font-weight: 800; color: var(--text-main, #0f172a); margin-bottom: 8px; line-height: 1.2;">${name2}</div>
          <div style="display: flex; align-items: center; justify-content: center; gap: 8px;">
            <button type="button" class="btn btn-outline" style="width: 34px; height: 34px; padding: 0; font-size: 18px; font-weight: 900;" onclick="window.adjustTournScore('team2', -1)">-</button>
            <input type="number" id="ts-score-2" data-team-name="${name2}" value="${s2}" min="0" max="99" style="width: 54px; text-align: center; font-size: 24px; font-weight: 900; border-radius: 8px; border: 1px solid var(--border, #cbd5e1); padding: 4px;" onchange="window.updateTournScorePreview()">
            <button type="button" class="btn btn-outline" style="width: 34px; height: 34px; padding: 0; font-size: 18px; font-weight: 900; color: #ea580c;" onclick="window.adjustTournScore('team2', 1)">+</button>
          </div>
        </div>
      </div>

      <!-- Quick Presets -->
      <div>
        <div style="font-size: 10px; font-weight: 800; color: var(--text-muted, #64748b); text-transform: uppercase; margin-bottom: 6px;">Quick Presets</div>
        <div style="display: flex; gap: 6px; flex-wrap: wrap;">
          ${[[21,19],[21,17],[21,15],[21,12],[15,13]].map(([p1, p2]) => `
            <button type="button" class="btn btn-outline" style="padding: 4px 10px; font-size: 11px; font-weight: 700;" onclick="window.setTournScorePreset(${p1}, ${p2})">${p1}-${p2}</button>
          `).join('')}
        </div>
      </div>

      <div id="ts-winner-preview" style="text-align: center; padding: 10px; border-radius: 10px; font-size: 13px; font-weight: 700; background: rgba(22,163,74,0.12); color: #16a34a;">
        Projected Winner: ${s1 > s2 ? name1 : (s2 > s1 ? name2 : 'None (Tie not allowed)')}
      </div>

      <button type="button" class="btn btn-primary" style="width: 100%; padding: 12px; font-weight: 800; font-size: 14px;" onclick="window.submitTournamentScoreModal('${t.id}', '${match.id}')">
        Submit Official Score
      </button>
    </div>
  `;

  modal.classList.add("active");
};

window.closeTournamentScoreModal = function() {
  document.getElementById("tournament-score-modal")?.classList.remove("active");
};

window.adjustTournScore = function(team, delta) {
  const input = document.getElementById(team === "team1" ? "ts-score-1" : "ts-score-2");
  if (input) {
    let val = parseInt(input.value, 10) || 0;
    val = Math.max(0, Math.min(99, val + delta));
    input.value = val;
    window.updateTournScorePreview();
  }
};

window.setTournScorePreset = function(s1, s2) {
  const in1 = document.getElementById("ts-score-1");
  const in2 = document.getElementById("ts-score-2");
  if (in1 && in2) {
    in1.value = s1;
    in2.value = s2;
    window.updateTournScorePreview();
  }
};

window.updateTournScorePreview = function() {
  const in1 = document.getElementById("ts-score-1");
  const in2 = document.getElementById("ts-score-2");
  const preview = document.getElementById("ts-winner-preview");
  if (!in1 || !in2 || !preview) return;

  const s1 = parseInt(in1.value, 10) || 0;
  const s2 = parseInt(in2.value, 10) || 0;
  const name1 = in1.dataset.teamName || "Team 1";
  const name2 = in2.dataset.teamName || "Team 2";

  if (s1 === s2) {
    preview.style.background = "rgba(220,38,38,0.12)";
    preview.style.color = "#dc2626";
    preview.innerText = "Ties not allowed in volleyball";
  } else {
    preview.style.background = "rgba(22,163,74,0.12)";
    preview.style.color = "#16a34a";
    preview.innerText = s1 > s2 ? `Projected Winner: ${name1}` : `Projected Winner: ${name2}`;
  }
};

window.submitTournamentScoreModal = function(tournamentId, matchId) {
  const in1 = document.getElementById("ts-score-1");
  const in2 = document.getElementById("ts-score-2");
  if (!in1 || !in2) return;
  const s1 = parseInt(in1.value, 10);
  const s2 = parseInt(in2.value, 10);
  window.submitTournamentMatchScore(tournamentId, matchId, s1, s2);
};

window.leaveTournament = function(tournamentId) {
  if (!state.currentUser) {
    showToast("Please log in to leave.");
    return;
  }
  if (!confirm("Are you sure you want to unregister from this tournament?")) return;

  const targetId = tournamentId ? String(tournamentId).trim() : "";
  const t = (state.tournaments || []).find(item => 
    (item.id && String(item.id).trim() === targetId) ||
    (item.rawId && String(item.rawId).trim() === targetId)
  );
  if (!t) return;

  const uid = state.currentUser.id;
  t.teams = (t.teams || []).filter(tm => tm.player1Id !== uid && tm.player2Id !== uid && tm.player3Id !== uid && tm.player4Id !== uid);
  t.freeAgents = (t.freeAgents || []).filter(fa => fa.playerId !== uid);

  state.saveLocal();
  saveTournamentToFirestore(t);
  showToast("Left tournament.");
  window.renderTournamentDetail();
  window.renderTournamentsList();
};

window.openTournamentSignUpModal = function(tournamentId) {
  if (!state.currentUser) {
    showToast("Please log in first to sign up!");
    window.openAuthModal();
    return;
  }
  window.signUpTournamentId = tournamentId;
  const modal = document.getElementById("tournament-signup-modal");
  if (!modal) return;
  modal.classList.add("active");
  window.renderTournamentSignUpBody();
};

window.closeTournamentSignUpModal = function() {
  document.getElementById("tournament-signup-modal")?.classList.remove("active");
};

window.tournamentSignUpMode = "team"; // 'team' or 'free_agent'
window.selectedTournamentPartnerId = "";

window.setTournamentSignUpMode = function(mode) {
  window.tournamentSignUpMode = mode;
  window.renderTournamentSignUpBody();
};

window.renderTournamentSignUpBody = function() {
  const container = document.getElementById("tournament-signup-body");
  if (!container) return;

  const targetId = window.signUpTournamentId ? String(window.signUpTournamentId).trim() : "";
  const t = (state.tournaments || []).find(item => 
    (item.id && String(item.id).trim() === targetId) ||
    (item.rawId && String(item.rawId).trim() === targetId)
  );
  if (!t) return;

  const currentDiv = window.activeTournamentDivision || "2v2 Coed Novice";
  const user = state.currentUser;
  const divConf = DIVISION_CONFIG.find(c => c.name === currentDiv) || { teamSize: 2 };
  const is4v4 = (divConf.teamSize === 4 || currentDiv.includes("4v4") || t.teamFormat === "4v4");
  const teamLabel = is4v4 ? "4-Player Team" : "2-Player Team";
  const isNovice = currentDiv.toLowerCase().includes("novice");

  // Filter eligible partners based on rating for Novice divisions
  const partners = (state.players || []).filter(p => {
    if (p.id === user.id) return false;
    if (isNovice) {
      const pRating = (p.rating || "Novice").trim().toLowerCase();
      if (pRating !== "novice") return false;
    }
    return true;
  }).sort((a, b) => a.name.localeCompare(b.name));

  const partnerOption = (partners, selectId) => `
    <select id="${selectId}" class="form-input" style="width: 100%; padding: 10px; border-radius: 8px; margin-top: 4px;">
      <option value="">-- Looking for Teammate / TBD --</option>
      ${partners.map(p => {
        const name = window.formatFirstLastInit ? window.formatFirstLastInit(p.name) : p.name;
        const firstName = (p.name || "").split(/\s+/)[0] || "";
        const pNick = (p.nickname && p.nickname.toLowerCase() !== "player" && p.nickname.toLowerCase() !== firstName.toLowerCase()) ? ` "${p.nickname}"` : "";
        const pPhone = p.phoneNumber ? ` • 📞 ${window.formatPhoneNumber(p.phoneNumber)}` : "";
        return `<option value="${p.id}">${name}${pNick}${pPhone} (${p.gender ? p.gender.toUpperCase() : '?'}, Rating: ${p.rating || 'Novice'})</option>`;
      }).join('')}
    </select>
  `;

  container.innerHTML = `
    <div style="display: flex; flex-direction: column; gap: 14px;">
      <div style="background: var(--bg-alt, #f8fafc); padding: 12px; border-radius: 12px; border: 1px solid var(--border, #e2e8f0);">
        <div style="font-size: 11px; font-weight: 800; color: #ea580c; text-transform: uppercase;">Registering For</div>
        <div style="font-size: 15px; font-weight: 800; color: var(--text-main, #0f172a);">${t.title}</div>
        <div style="display: flex; gap: 8px; margin-top: 4px; flex-wrap: wrap; align-items: center;">
          <span style="font-size: 12px; font-weight: 700; color: #ea580c;">Division: ${currentDiv}</span>
          <span style="font-size: 11px; font-weight: 800; color: #0891b2; background: rgba(8,145,178,0.1); padding: 2px 8px; border-radius: 20px;">${is4v4 ? '🏐 4v4 Quads' : '👥 2v2 Doubles'}</span>
          ${isNovice ? '<span style="font-size: 10px; font-weight: 800; color: #16a34a; background: rgba(22,163,74,0.15); padding: 2px 8px; border-radius: 20px;">🛡️ Anti-Sandbagging Active</span>' : ''}
        </div>
      </div>

      <!-- Registration Type Toggle -->
      <div class="ios-segmented-control">
        <button type="button" class="ios-segment-btn ${window.tournamentSignUpMode === 'team' ? 'active' : ''}" onclick="window.setTournamentSignUpMode('team')">
          👥 ${teamLabel}
        </button>
        <button type="button" class="ios-segment-btn ${window.tournamentSignUpMode === 'free_agent' ? 'active' : ''}" onclick="window.setTournamentSignUpMode('free_agent')">
          🙋 Solo Free Agent
        </button>
      </div>

      ${window.tournamentSignUpMode === 'team' ? `
        <form id="tourn-reg-team-form" onsubmit="window.submitTournamentTeamRegistration(event)" style="display: flex; flex-direction: column; gap: 12px;">
          <div>
            <label style="font-size: 12px; font-weight: 700; color: var(--text-muted, #64748b);">Team Name</label>
            <input type="text" id="tourn-team-name" class="form-input" placeholder="e.g. Sand Spikers" required style="width: 100%; padding: 10px; border-radius: 8px; border: 1px solid var(--border, #cbd5e1); margin-top: 4px;">
          </div>

          <div>
            <label style="font-size: 12px; font-weight: 700; color: var(--text-muted, #64748b);">Teammate 2</label>
            ${partnerOption(partners, 'tourn-partner-select')}
          </div>

          ${is4v4 ? `
            <div>
              <label style="font-size: 12px; font-weight: 700; color: var(--text-muted, #64748b);">Teammate 3</label>
              ${partnerOption(partners, 'tourn-partner3-select')}
            </div>

            <div>
              <label style="font-size: 12px; font-weight: 700; color: var(--text-muted, #64748b);">Teammate 4</label>
              ${partnerOption(partners, 'tourn-partner4-select')}
            </div>
          ` : ''}

          <div style="font-size: 11px; color: var(--text-muted, #64748b); line-height: 1.4;">
            ${is4v4
              ? '* 4v4 Coed requires a mixed-gender team (at least 1 male and 1 female player).'
              : '* 2v2 Coed requires 1 male and 1 female player. Men\'s Intermediate requires male players.'}
            ${isNovice ? '<br><b style="color: #16a34a;">* Strict anti-sandbagging: Players rated Intermediate or higher cannot register in Novice divisions.</b>' : ''}
          </div>

          <button type="submit" class="btn btn-primary" style="margin-top: 8px; font-weight: 800; padding: 12px;">
            Confirm Team Registration
          </button>
        </form>
      ` : `
        <form id="tourn-reg-fa-form" onsubmit="window.submitTournamentFreeAgentRegistration(event)" style="display: flex; flex-direction: column; gap: 12px;">
          <div>
            <label style="font-size: 12px; font-weight: 700; color: var(--text-muted, #64748b);">Player Notes (Optional)</label>
            <input type="text" id="tourn-fa-notes" class="form-input" placeholder="e.g. Left-side blocker looking for defender" style="width: 100%; padding: 10px; border-radius: 8px; border: 1px solid var(--border, #cbd5e1); margin-top: 4px;">
          </div>

          <div style="font-size: 11px; color: var(--text-muted, #64748b); line-height: 1.4;">
            You will be added to the public Free Agent list for ${currentDiv}. Other players and the host can pair up with you!
          </div>

          <button type="submit" class="btn btn-primary" style="margin-top: 8px; font-weight: 800; padding: 12px; background: #0284c7;">
            Join Free Agent List
          </button>
        </form>
      `}
    </div>
  `;
};

window.submitTournamentTeamRegistration = function(e) {
  e.preventDefault();
  const targetId = window.signUpTournamentId ? String(window.signUpTournamentId).trim() : "";
  const t = (state.tournaments || []).find(item => 
    (item.id && String(item.id).trim() === targetId) ||
    (item.rawId && String(item.rawId).trim() === targetId)
  );
  if (!t || !state.currentUser) return;

  const teamName = document.getElementById("tourn-team-name")?.value.trim() || `Team ${state.currentUser.name}`;
  const partnerId = document.getElementById("tourn-partner-select")?.value || null;
  const partner3Id = document.getElementById("tourn-partner3-select")?.value || null;
  const partner4Id = document.getElementById("tourn-partner4-select")?.value || null;
  const currentDiv = window.activeTournamentDivision || "2v2 Coed Novice";
  const isNovice = currentDiv.toLowerCase().includes("novice");

  // Anti-sandbagging check for user
  if (isNovice) {
    const userRating = (state.currentUser.rating || "Novice").trim().toLowerCase();
    if (userRating !== "novice") {
      alert(`Anti-Sandbagging Rule: Your rating (${state.currentUser.rating}) exceeds Novice. You cannot play in Novice divisions.`);
      return;
    }
  }

  // Anti-sandbagging check for partners
  const partnerIds = [partnerId, partner3Id, partner4Id].filter(Boolean);
  if (isNovice) {
    for (const pid of partnerIds) {
      const p = state.players.find(pl => pl.id === pid);
      if (p) {
        const pRating = (p.rating || "Novice").trim().toLowerCase();
        if (pRating !== "novice") {
          alert(`Anti-Sandbagging Rule: Partner ${p.name} is rated ${p.rating}, which exceeds Novice. Sandbagging is strictly prohibited.`);
          return;
        }
      }
    }
  }

  if (partnerId) {
    const partner = state.players.find(p => p.id === partnerId);
    const uGen = (state.currentUser.gender || "M").toUpperCase();
    const pGen = (partner?.gender || "M").toUpperCase();

    if (currentDiv.toLowerCase().includes("coed") && !currentDiv.includes("4v4")) {
      if (uGen === pGen) {
        alert("2v2 Coed divisions require 1 male and 1 female player. Please select an opposite-gender partner.");
        return;
      }
    } else if (currentDiv.toLowerCase().includes("men")) {
      if (uGen !== "M" || pGen !== "M") {
        alert("Men's divisions require male players.");
        return;
      }
    }
  }

  t.teams = (t.teams || []).filter(tm => tm.player1Id !== state.currentUser.id && tm.player2Id !== state.currentUser.id && tm.player3Id !== state.currentUser.id && tm.player4Id !== state.currentUser.id);
  t.freeAgents = (t.freeAgents || []).filter(fa => fa.playerId !== state.currentUser.id);

  const newTeam = {
    id: "team-" + Date.now(),
    teamName,
    player1Id: state.currentUser.id,
    player2Id: partnerId,
    player3Id: partner3Id || null,
    player4Id: partner4Id || null,
    seed: (t.teams.filter(tm => tm.division === currentDiv).length) + 1,
    division: currentDiv
  };

  t.teams.push(newTeam);
  state.saveLocal();
  saveTournamentToFirestore(t);

  showToast(`🎉 Registered for ${currentDiv}!`);
  window.closeTournamentSignUpModal();
  window.renderTournamentDetail();
  window.renderTournamentsList();
};

window.submitTournamentFreeAgentRegistration = function(e) {
  e.preventDefault();
  const targetId = window.signUpTournamentId ? String(window.signUpTournamentId).trim() : "";
  const t = (state.tournaments || []).find(item => 
    (item.id && String(item.id).trim() === targetId) ||
    (item.rawId && String(item.rawId).trim() === targetId)
  );
  if (!t || !state.currentUser) return;

  const notes = document.getElementById("tourn-fa-notes")?.value.trim() || "";
  const currentDiv = window.activeTournamentDivision || "2v2 Coed Novice";
  const isNovice = currentDiv.toLowerCase().includes("novice");

  // Anti-sandbagging check for free agent
  if (isNovice) {
    const userRating = (state.currentUser.rating || "Novice").trim().toLowerCase();
    if (userRating !== "novice") {
      alert(`Anti-Sandbagging Rule: Your rating (${state.currentUser.rating}) exceeds Novice. You cannot enter Novice divisions.`);
      return;
    }
  }

  t.teams = (t.teams || []).filter(tm => tm.player1Id !== state.currentUser.id && tm.player2Id !== state.currentUser.id && tm.player3Id !== state.currentUser.id && tm.player4Id !== state.currentUser.id);
  t.freeAgents = (t.freeAgents || []).filter(fa => fa.playerId !== state.currentUser.id);

  t.freeAgents.push({
    id: "fa-" + Date.now(),
    playerId: state.currentUser.id,
    division: currentDiv,
    notes
  });

  state.saveLocal();
  saveTournamentToFirestore(t);

  showToast(`🙋 Joined free agent list for ${currentDiv}!`);
  window.closeTournamentSignUpModal();
  window.renderTournamentDetail();
  window.renderTournamentsList();
};

window.openCreateTournamentModal = function() {
  if (!state.currentUser) {
    showToast("Please log in first to host a tournament!");
    window.openAuthModal();
    return;
  }
  const modal = document.getElementById("create-tournament-modal");
  if (!modal) return;

  document.getElementById("edit-tourn-id").value = "";
  document.getElementById("create-tourn-modal-title").innerText = "🏆 Host Beach Tournament";
  document.getElementById("create-tourn-submit-btn").innerText = "Create Tournament";

  document.getElementById("new-tourn-title").value = "";
  document.getElementById("new-tourn-location").value = "Main Beach";
  document.getElementById("new-tourn-date").value = "";
  document.getElementById("new-tourn-courts").value = "Court #1, Court #2, Court #3, Court #4";
  document.getElementById("new-tourn-max-teams").value = "8";
  const formatEl = document.getElementById("new-tourn-format");
  if (formatEl) formatEl.value = "2v2";
  document.getElementById("new-tourn-notes").value = "Double elimination beach doubles tournament. Rally score to 21, switch sides every 7 points.";
  document.querySelectorAll('input[name="tourn-div"]').forEach(cb => cb.checked = true);

  const cohostSearch = document.getElementById("new-tourn-cohost-search");
  if (cohostSearch) cohostSearch.value = "";
  window.filterCreateTournCoHosts();

  modal.classList.add("active");
};

window.filterCreateTournCoHosts = function() {
  const query = (document.getElementById("new-tourn-cohost-search")?.value || "").toLowerCase().trim();
  const coHostsSelect = document.getElementById("new-tourn-cohosts");
  if (!coHostsSelect) return;
  const curUserId = state.currentUser?.id;
  const selectedValues = new Set(Array.from(coHostsSelect.selectedOptions).map(o => o.value));

  coHostsSelect.innerHTML = (state.players || [])
    .filter(p => !isSamePlayer(p.id, curUserId))
    .filter(p => {
      if (!query) return true;
      const name = (p.name || "").toLowerCase();
      const nick = (p.nickname || "").toLowerCase();
      const phone = (p.phoneNumber || "").replace(/\D/g, "");
      const cleanQ = query.replace(/\D/g, "");
      const matchName = name.includes(query);
      const matchNick = nick.includes(query);
      const matchPhone = cleanQ.length > 0 && phone.includes(cleanQ);
      return matchName || matchNick || matchPhone;
    })
    .map(p => {
      const name = window.formatFirstLastInit ? window.formatFirstLastInit(p.name) : p.name;
      const firstName = (p.name || "").split(/\s+/)[0] || "";
      const pNick = (p.nickname && p.nickname.toLowerCase() !== "player" && p.nickname.toLowerCase() !== firstName.toLowerCase()) ? ` "${p.nickname}"` : "";
      const pPhone = p.phoneNumber ? ` • 📞 ${window.formatPhoneNumber(p.phoneNumber)}` : "";
      const isSelected = selectedValues.has(p.id) ? "selected" : "";
      return `<option value="${p.id}" ${isSelected}>${name}${pNick}${pPhone} (${p.rating || 'Player'})</option>`;
    }).join('');
};

window.openEditTournamentModal = function(tournamentId) {
  const t = (state.tournaments || []).find(item => item.id === tournamentId);
  if (!t) return;

  const isRoot = isRootUser(state.currentUser);
  const isHost = (t.hostPlayerId && isSamePlayer(t.hostPlayerId, state.currentUser?.id)) || isRoot;
  if (!isHost) {
    showToast("Only the tournament host or admin can edit this tournament.");
    return;
  }

  const modal = document.getElementById("create-tournament-modal");
  if (!modal) return;

  document.getElementById("edit-tourn-id").value = t.id;
  document.getElementById("create-tourn-modal-title").innerText = "✏️ Edit Beach Tournament";
  document.getElementById("create-tourn-submit-btn").innerText = "Save Changes";

  document.getElementById("new-tourn-title").value = t.title || "";
  document.getElementById("new-tourn-location").value = t.location || "Main Beach";
  
  if (t.date) {
    const d = new Date(t.date);
    const pad = num => String(num).padStart(2, '0');
    const localIso = `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
    document.getElementById("new-tourn-date").value = localIso;
  } else {
    document.getElementById("new-tourn-date").value = "";
  }

  document.getElementById("new-tourn-courts").value = (t.courts || []).join(", ");
  document.getElementById("new-tourn-max-teams").value = t.maxTeamsPerDivision || 8;
  const formatEl = document.getElementById("new-tourn-format");
  if (formatEl) formatEl.value = t.teamFormat || "2v2";
  document.getElementById("new-tourn-notes").value = t.notes || "";

  const allowed = t.allowedDivisions || [];
  document.querySelectorAll('input[name="tourn-div"]').forEach(cb => {
    cb.checked = allowed.includes(cb.value);
  });

  const coHostsSelect = document.getElementById("new-tourn-cohosts");
  if (coHostsSelect) {
    const hostId = t.hostPlayerId;
    const currentCoHosts = t.coHostPlayerIds || [];
    coHostsSelect.innerHTML = (state.players || [])
      .filter(p => !isSamePlayer(p.id, hostId))
      .map(p => {
        const name = window.formatFirstLastInit ? window.formatFirstLastInit(p.name) : p.name;
        const firstName = (p.name || "").split(/\s+/)[0] || "";
        const pNick = (p.nickname && p.nickname.toLowerCase() !== "player" && p.nickname.toLowerCase() !== firstName.toLowerCase()) ? ` "${p.nickname}"` : "";
        const pPhone = p.phoneNumber ? ` • 📞 ${window.formatPhoneNumber(p.phoneNumber)}` : "";
        const isSelected = currentCoHosts.some(id => isSamePlayer(id, p.id));
        return `<option value="${p.id}" ${isSelected ? 'selected' : ''}>${name}${pNick}${pPhone} (${p.rating || 'Player'})</option>`;
      }).join('');
  }

  modal.classList.add("active");
};

window.closeCreateTournamentModal = function() {
  document.getElementById("create-tournament-modal")?.classList.remove("active");
};

window.submitCreateTournament = function(e) {
  e.preventDefault();
  const editId = document.getElementById("edit-tourn-id")?.value;
  const title = document.getElementById("new-tourn-title")?.value.trim();
  const location = document.getElementById("new-tourn-location")?.value;
  const dateVal = document.getElementById("new-tourn-date")?.value;
  const courtsStr = document.getElementById("new-tourn-courts")?.value || "Court #1, Court #2";
  const maxTeams = parseInt(document.getElementById("new-tourn-max-teams")?.value) || 8;
  const notes = document.getElementById("new-tourn-notes")?.value || "";
  const checkedDivs = Array.from(document.querySelectorAll('input[name="tourn-div"]:checked')).map(el => el.value);
  const teamFormat = document.getElementById("new-tourn-format")?.value || "2v2";
  const coHostsSelect = document.getElementById("new-tourn-cohosts");
  const selectedCoHostIds = coHostsSelect ? Array.from(coHostsSelect.selectedOptions).map(opt => opt.value) : [];

  if (editId) {
    const t = (state.tournaments || []).find(item => item.id === editId);
    if (!t) return;

    const isRoot = isRootUser(state.currentUser);
    const isHost = (t.hostPlayerId && isSamePlayer(t.hostPlayerId, state.currentUser?.id)) || isRoot;
    if (!isHost) {
      showToast("Only the tournament host or admin can edit this tournament.");
      return;
    }

    t.title = title;
    t.location = location;
    if (dateVal) t.date = new Date(dateVal).toISOString();
    t.courts = courtsStr.split(",").map(c => c.trim()).filter(Boolean);
    t.allowedDivisions = checkedDivs.length > 0 ? checkedDivs : DIVISION_CONFIG.map(d => d.name);
    t.maxTeamsPerDivision = maxTeams;
    t.notes = notes;
    t.teamFormat = teamFormat;
    t.coHostPlayerIds = selectedCoHostIds;

    state.saveLocal();
    saveTournamentToFirestore(t);
    showToast(`✅ Tournament "${title}" updated!`);
    window.closeCreateTournamentModal();
    window.renderTournamentDetail();
    window.renderTournamentsList();
    return;
  }

  const newTourn = {
    id: "tourn-" + Date.now(),
    title,
    location,
    date: dateVal ? new Date(dateVal).toISOString() : new Date(Date.now() + 86400000 * 3).toISOString(),
    courts: courtsStr.split(",").map(c => c.trim()).filter(Boolean),
    allowedDivisions: checkedDivs.length > 0 ? checkedDivs : DIVISION_CONFIG.map(d => d.name),
    maxTeamsPerDivision: maxTeams,
    teams: [],
    freeAgents: [],
    matches: [],
    status: "registration_open",
    notes,
    hostPlayerId: state.currentUser?.id || null,
    coHostPlayerIds: selectedCoHostIds,
    teamFormat
  };

  state.tournaments = state.tournaments || [];
  state.tournaments.unshift(newTourn);
  state.saveLocal();
  saveTournamentToFirestore(newTourn);

  showToast(`🏆 Hosted new tournament: ${title}!`);
  window.closeCreateTournamentModal();
  window.renderTournamentsList();
};

window.deleteTournament = function(tournamentId) {
  const t = (state.tournaments || []).find(item => item.id === tournamentId || (item.rawId && item.rawId === tournamentId));
  if (!t) return;

  const isRoot = isRootUser(state.currentUser);
  const isHost = (t.hostPlayerId && isSamePlayer(t.hostPlayerId, state.currentUser?.id)) || isRoot;
  if (!isHost) {
    showToast("Only the tournament host or admin can delete this tournament.");
    return;
  }

  if (!confirm(`Are you sure you want to permanently delete "${t.title}"? This cannot be undone.`)) {
    return;
  }

  const id1 = t.id;
  const id2 = t.rawId;

  state.tournaments = (state.tournaments || []).filter(item => item.id !== id1 && item.id !== id2 && item.title !== t.title);
  state.saveLocal();
  if (id1) deleteTournamentFromFirestore(id1);
  if (id2 && id2 !== id1) deleteTournamentFromFirestore(id2);

  showToast(`🗑️ Tournament "${t.title}" deleted.`);
  document.getElementById("tournament-detail-modal")?.classList.remove("active");
  window.renderTournamentsList();
};

window.openManageCoHostsModal = function(tournamentId) {
  const t = (state.tournaments || []).find(item => item.id === tournamentId);
  if (!t) return;

  const isRoot = isRootUser(state.currentUser);
  const isPrimaryHost = (t.hostPlayerId && isSamePlayer(t.hostPlayerId, state.currentUser?.id)) || isRoot;
  if (!isPrimaryHost) {
    showToast("Only the tournament host can manage co-hosts.");
    return;
  }

  window.activeManageCoHostsTournamentId = tournamentId;
  window.renderManageCoHostsModal(tournamentId);
  document.getElementById("manage-cohosts-modal")?.classList.add("active");
};

window.closeManageCoHostsModal = function() {
  document.getElementById("manage-cohosts-modal")?.classList.remove("active");
  window.activeManageCoHostsTournamentId = null;
};

window.renderManageCoHostsModal = function(tournamentId) {
  const container = document.getElementById("manage-cohosts-content");
  if (!container) return;

  const t = (state.tournaments || []).find(item => item.id === tournamentId);
  if (!t) return;

  const hostPlayer = t.hostPlayerId ? state.getPlayer(t.hostPlayerId) : null;
  const hostName = hostPlayer ? (window.formatFirstLastInit ? window.formatFirstLastInit(hostPlayer.name) : hostPlayer.name) : "Organizer";
  const hostFirst = hostPlayer ? (hostPlayer.name || "").split(/\s+/)[0] || "" : "";
  const hostNick = (hostPlayer && hostPlayer.nickname && hostPlayer.nickname.toLowerCase() !== "player" && hostPlayer.nickname.toLowerCase() !== hostFirst.toLowerCase()) ? hostPlayer.nickname : "";
  const hostPhone = hostPlayer && hostPlayer.phoneNumber ? window.formatPhoneNumber(hostPlayer.phoneNumber) : "";

  const coHostIds = t.coHostPlayerIds || [];
  const coHosts = coHostIds.map(id => state.getPlayer(id)).filter(Boolean);

  const excludedIds = new Set([t.hostPlayerId, ...coHostIds].filter(Boolean).map(id => String(id).toLowerCase()));
  const availablePlayers = (state.players || []).filter(p => !excludedIds.has(String(p.id).toLowerCase()));

  container.innerHTML = `
    <!-- Primary Host Display -->
    <div style="background: var(--bg-alt, #f8fafc); border: 1px solid var(--border, #e2e8f0); border-radius: 10px; padding: 10px 14px; display: flex; align-items: center; justify-content: space-between;">
      <div style="display: flex; align-items: center; gap: 8px;">
        <span style="font-size: 18px;">👑</span>
        <div>
          <div style="font-size: 11px; font-weight: 800; color: #ea580c; text-transform: uppercase;">Primary Host</div>
          <div style="font-size: 13px; font-weight: 700; color: var(--text-main, #0f172a);">
            ${hostName}${hostNick ? ` <span style="color: #ea580c; font-size: 12px; font-weight: 600;">"${hostNick}"</span>` : ''}
          </div>
          <div style="font-size: 11px; color: var(--text-muted, #64748b);">
            ${hostPhone ? `📞 ${hostPhone} • ` : ''}${hostPlayer ? (hostPlayer.homeBeach || 'Main Beach') : 'Beach Host'}
          </div>
        </div>
      </div>
      <span style="font-size: 10px; font-weight: 800; color: #64748b; background: #e2e8f0; padding: 2px 6px; border-radius: 6px;">Creator</span>
    </div>

    <!-- Co-Hosts List -->
    <div>
      <div style="font-size: 12px; font-weight: 800; color: #0284c7; text-transform: uppercase; margin: 4px 0 8px 0; display: flex; justify-content: space-between;">
        <span>Assigned Co-Hosts (${coHosts.length})</span>
      </div>
      ${coHosts.length === 0 ? `
        <div style="text-align: center; padding: 18px 12px; background: var(--bg-alt, #f8fafc); border-radius: 10px; color: var(--text-muted, #94a3b8); font-size: 12px; border: 1px dashed var(--border, #cbd5e1);">
          No co-hosts assigned yet. Add trusted players by phone number, name, or nickname to help manage pools, scores, and brackets.
        </div>
      ` : `
        <div style="display: flex; flex-direction: column; gap: 6px;">
          ${coHosts.map(p => {
            const pName = window.formatFirstLastInit ? window.formatFirstLastInit(p.name) : p.name;
            const pFirst = (p.name || "").split(/\s+/)[0] || "";
            const pNick = (p.nickname && p.nickname.toLowerCase() !== "player" && p.nickname.toLowerCase() !== pFirst.toLowerCase()) ? p.nickname : "";
            const pPhone = p.phoneNumber ? window.formatPhoneNumber(p.phoneNumber) : "";
            return `
              <div style="display: flex; justify-content: space-between; align-items: center; background: var(--surface, #ffffff); border: 1px solid var(--border, #e2e8f0); border-radius: 10px; padding: 8px 12px;">
                <div style="display: flex; align-items: center; gap: 8px;">
                  <span style="font-size: 16px;">👥</span>
                  <div>
                    <div style="font-size: 13px; font-weight: 700; color: var(--text-main, #0f172a);">
                      ${pName}${pNick ? ` <span style="color: #ea580c; font-size: 12px; font-weight: 600;">"${pNick}"</span>` : ''}
                    </div>
                    <div style="font-size: 11px; color: var(--text-muted, #64748b);">
                      ${pPhone ? `📞 ${pPhone} • ` : ''}${p.rating || 'Player'}${p.homeBeach ? ` • ${p.homeBeach}` : ''}
                    </div>
                  </div>
                </div>
                <button type="button" class="btn btn-outline" style="padding: 4px 8px; font-size: 11px; font-weight: 700; color: #dc2626; border-color: #fca5a5;" onclick="window.removeCoHostFromTournament('${t.id}', '${p.id}')">
                  Remove
                </button>
              </div>
            `;
          }).join('')}
        </div>
      `}
    </div>

    <!-- Add Co-Host Section -->
    <div style="border-top: 1px solid var(--border, #e2e8f0); padding-top: 12px; margin-top: 4px;">
      <div style="font-size: 12px; font-weight: 800; color: var(--text-main, #0f172a); margin-bottom: 6px;">
        ➕ Add New Co-Host
      </div>
      <div style="margin-bottom: 8px;">
        <input type="text" id="cohost-search-input" class="form-input" 
          placeholder="🔍 Search by phone #, first name, or nickname..." 
          style="width: 100%; padding: 8px 12px; font-size: 12px; border-radius: 8px; border: 1px solid var(--border, #cbd5e1); box-sizing: border-box;"
          oninput="window.filterCoHostSearch('${t.id}')">
      </div>
      <div id="cohost-search-results" style="max-height: 180px; overflow-y: auto; display: flex; flex-direction: column; gap: 6px; margin-bottom: 8px;">
      </div>
      <div style="display: flex; gap: 8px;">
        <select id="add-cohost-select" class="form-input" style="flex: 1; padding: 8px 10px; font-size: 12px; border-radius: 8px; border: 1px solid var(--border, #cbd5e1);">
          <option value="">Or choose from all players...</option>
          ${availablePlayers.map(p => {
            const pName = window.formatFirstLastInit ? window.formatFirstLastInit(p.name) : p.name;
            const pFirst = (p.name || "").split(/\s+/)[0] || "";
            const pNick = (p.nickname && p.nickname.toLowerCase() !== "player" && p.nickname.toLowerCase() !== pFirst.toLowerCase()) ? ` "${p.nickname}"` : "";
            const pPhone = p.phoneNumber ? ` • 📞 ${window.formatPhoneNumber(p.phoneNumber)}` : "";
            return `<option value="${p.id}">${pName}${pNick}${pPhone} (${p.rating || 'Player'})</option>`;
          }).join('')}
        </select>
        <button type="button" class="btn btn-primary" style="padding: 8px 14px; font-size: 12px; font-weight: 700; white-space: nowrap;" onclick="window.addSelectedCoHost('${t.id}')">
          Add
        </button>
      </div>
    </div>
  `;
};

window.filterCoHostSearch = function(tournamentId) {
  const container = document.getElementById("cohost-search-results");
  const input = document.getElementById("cohost-search-input");
  if (!container || !input) return;

  const rawQuery = (input.value || "").trim();
  const q = rawQuery.toLowerCase();
  if (!q) {
    container.innerHTML = "";
    return;
  }

  const t = (state.tournaments || []).find(item => item.id === tournamentId);
  if (!t) return;

  const coHostIds = t.coHostPlayerIds || [];
  const excludedIds = new Set([t.hostPlayerId, ...coHostIds].filter(Boolean).map(id => String(id).toLowerCase()));
  const availablePlayers = (state.players || []).filter(p => !excludedIds.has(String(p.id).toLowerCase()));

  const queryDigits = rawQuery.replace(/\D/g, "");

  const matches = availablePlayers.filter(p => {
    // 1. Phone number match
    const pDigits = (p.phoneNumber || "").replace(/\D/g, "");
    if (queryDigits && pDigits.includes(queryDigits)) return true;
    if (p.phoneNumber && p.phoneNumber.toLowerCase().includes(q)) return true;

    // 2. Nickname match
    if (p.nickname && p.nickname.toLowerCase().includes(q)) return true;

    // 3. First name or full name match
    const firstName = (p.name || "").split(/\s+/)[0] || "";
    if (firstName.toLowerCase().includes(q)) return true;
    if ((p.name || "").toLowerCase().includes(q)) return true;

    // 4. Home beach match
    if ((p.homeBeach || "").toLowerCase().includes(q)) return true;

    return false;
  });

  if (matches.length === 0) {
    container.innerHTML = `
      <div style="font-size: 11px; color: var(--text-muted, #94a3b8); text-align: center; padding: 8px; background: var(--bg-alt, #f8fafc); border-radius: 6px;">
        No players found matching "${rawQuery}".
      </div>
    `;
    return;
  }

  container.innerHTML = matches.map(p => {
    const pName = window.formatFirstLastInit ? window.formatFirstLastInit(p.name) : p.name;
    const pFirst = (p.name || "").split(/\s+/)[0] || "";
    const pNick = (p.nickname && p.nickname.toLowerCase() !== "player" && p.nickname.toLowerCase() !== pFirst.toLowerCase()) ? p.nickname : "";
    const pPhone = p.phoneNumber ? window.formatPhoneNumber(p.phoneNumber) : "";
    return `
      <div style="display: flex; justify-content: space-between; align-items: center; background: var(--surface, #ffffff); border: 1px solid var(--border, #cbd5e1); border-radius: 8px; padding: 6px 10px;">
        <div>
          <div style="font-size: 12px; font-weight: 700; color: var(--text-main, #0f172a);">
            ${pName}${pNick ? ` <span style="color: #ea580c; font-size: 11px; font-weight: 600;">"${pNick}"</span>` : ''}
          </div>
          <div style="font-size: 10px; color: var(--text-muted, #64748b);">
            ${pPhone ? `📞 ${pPhone} • ` : ''}${p.rating || 'Player'}${p.homeBeach ? ` • ${p.homeBeach}` : ''}
          </div>
        </div>
        <button type="button" class="btn btn-sm btn-primary" style="padding: 4px 10px; font-size: 11px; font-weight: 700; border-radius: 6px; white-space: nowrap;" onclick="window.addCoHostToTournament('${t.id}', '${p.id}')">
          ➕ Add
        </button>
      </div>
    `;
  }).join('');
};

window.addSelectedCoHost = function(tournamentId) {
  const select = document.getElementById("add-cohost-select");
  const playerId = select?.value;
  if (!playerId) {
    showToast("Please select a player to add as co-host.");
    return;
  }
  window.addCoHostToTournament(tournamentId, playerId);
};

window.addCoHostToTournament = function(tournamentId, playerId) {
  const t = (state.tournaments || []).find(item => item.id === tournamentId);
  if (!t) return;

  t.coHostPlayerIds = t.coHostPlayerIds || [];
  if (!t.coHostPlayerIds.some(id => isSamePlayer(id, playerId))) {
    t.coHostPlayerIds.push(playerId);
  }

  state.saveLocal();
  saveTournamentToFirestore(t);

  const player = state.getPlayer(playerId);
  const pName = player ? (window.formatFirstLastInit ? window.formatFirstLastInit(player.name) : player.name) : "Player";
  showToast(`👥 Added ${pName} as co-host!`);

  window.renderManageCoHostsModal(tournamentId);
  window.renderTournamentDetail();
  window.renderTournamentsList();
};

window.removeCoHostFromTournament = function(tournamentId, playerId) {
  const t = (state.tournaments || []).find(item => item.id === tournamentId);
  if (!t) return;

  t.coHostPlayerIds = (t.coHostPlayerIds || []).filter(id => !isSamePlayer(id, playerId));

  state.saveLocal();
  saveTournamentToFirestore(t);

  const player = state.getPlayer(playerId);
  const pName = player ? (window.formatFirstLastInit ? window.formatFirstLastInit(player.name) : player.name) : "Player";
  showToast(`Removed ${pName} from co-hosts.`);

  window.renderManageCoHostsModal(tournamentId);
  window.renderTournamentDetail();
  window.renderTournamentsList();
};

window.purgeAllTournaments = function() {
  const isRoot = isRootUser(state.currentUser);
  if (!isRoot) {
    showToast("Purge is only available for admins.");
    return;
  }

  if (!confirm("Are you sure you want to delete ALL tournaments from the database?")) return;

  (state.tournaments || []).forEach(t => {
    if (t.id) deleteTournamentFromFirestore(t.id);
    if (t.rawId && t.rawId !== t.id) deleteTournamentFromFirestore(t.rawId);
  });

  state.tournaments = [];
  state.saveLocal();
  showToast("All tournaments deleted.");
  document.getElementById("tournament-detail-modal")?.classList.remove("active");
  window.renderTournamentsList();
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
  try { renderAvailabilityWindows(); } catch (e) { console.error("renderAvailabilityWindows error:", e); }
  try { window.updateNotificationBadge(); } catch (e) { console.error("updateNotificationBadge error:", e); }

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

  // Backdrop click to close notifications modal
  document.getElementById("modal-notifications")?.addEventListener("click", (e) => {
    if (e.target.id === "modal-notifications") {
      window.closeNotificationsModal();
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

  subscribeToTournaments((remoteTournaments) => {
    if (Array.isArray(remoteTournaments)) {
      state.tournaments = deduplicateTournaments(remoteTournaments);
      state.saveLocal();
      if (document.getElementById("tournaments-modal")?.classList.contains("active")) {
        window.renderTournamentsList();
      }
      if (document.getElementById("tournament-detail-modal")?.classList.contains("active") && window.activeTournamentId) {
        window.renderTournamentDetail();
      }
    }
  });

  // Handle incoming deep link or game route from QR scan
  handleIncomingGameRoute();
}

if (document.readyState === "loading") {
  window.addEventListener("DOMContentLoaded", initApp);
} else {
  initApp();
}
