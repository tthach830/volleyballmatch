import { 
  savePlayerToFirestore, 
  saveGameToFirestore, 
  deleteGameFromFirestore,
  saveSlotToFirestore, 
  subscribeToPlayers, 
  subscribeToGames, 
  subscribeToSlots 
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
  if (!game || !game.status) return true;
  const s = String(game.status).trim().toLowerCase();
  return s === "scheduled" || s === "in progress" || s === "inprogress";
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

// App State
class AppState {
  constructor() {
    this.players = JSON.parse(localStorage.getItem("setgames_players")) || initialCommunityPlayers;
    const rawGames = JSON.parse(localStorage.getItem("setgames_games")) || initialCommunityGames;
    this.games = rawGames.filter(isUpcomingGame);
    this.availabilitySlots = JSON.parse(localStorage.getItem("setgames_slots")) || [];
    this.pickupQueue = [];
    this.selectedLadderTier = "All";
    this.collapsedMatches = {};
    
    // Active user session
    const savedUserId = localStorage.getItem("setgames_current_user_id");
    this.currentUser = this.players.find(p => p.id === savedUserId) || null;
  }

  saveLocal() {
    localStorage.setItem("setgames_players", JSON.stringify(this.players));
    localStorage.setItem("setgames_games", JSON.stringify(this.games));
    localStorage.setItem("setgames_slots", JSON.stringify(this.availabilitySlots));
    if (this.currentUser) {
      localStorage.setItem("setgames_current_user_id", this.currentUser.id);
    } else {
      localStorage.removeItem("setgames_current_user_id");
    }
  }

  getPlayer(id) {
    if (!id) return { id: "", name: "Beach Player", nickname: "Player", avatarEmoji: "🏐", rating: "B", eloRating: 1500, homeBeach: "Main Beach" };
    const found = this.players.find(p => p.id === id);
    if (found) return found;
    if (typeof id === "string" && id.startsWith("guest_")) {
      const clean = id.replace("guest_", "").replace(/([0-9]+)/, " $1").replace(/^./, str => str.toUpperCase());
      return { id, name: clean, nickname: clean, avatarEmoji: "🏐", rating: "B", eloRating: 1500, homeBeach: "Main Beach" };
    }
    return { id, name: "Beach Player", nickname: "Player", avatarEmoji: "🏐", rating: "B", eloRating: 1500, homeBeach: "Main Beach" };
  }
}

const state = new AppState();

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
export function renderAvatar(avatarKey, sizeClass = "", isFlaker = false) {
  let inner = "";
  if (avatarKey === "slug" || avatarKey === "🍌") {
    inner = `<img src="assets/slug.png" alt="Banana Slug" class="avatar-slug-img">`;
  } else {
    inner = `${avatarKey || "🏐"}`;
  }
  
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
        <span>${state.currentUser.name.split(" ")[0]}</span>
        <span class="badge badge-tier-${state.currentUser.rating.toLowerCase()}">${state.currentUser.rating}</span>
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

function resolvePlayerNames(pids) {
  if (!pids || pids.length === 0) return "TBD";
  return pids.map(id => {
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
  if (!game.team1PlayerIds) game.team1PlayerIds = [];
  if (!game.team2PlayerIds) game.team2PlayerIds = [];

  if (game.team1PlayerIds.length <= game.team2PlayerIds.length) {
    game.team1PlayerIds.push(uid);
  } else {
    game.team2PlayerIds.push(uid);
  }
  saveGameToFirestore(game);
  state.saveLocal();
  renderMatches();
  showToast(`Joined ${game.title} player pool!`);
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
    showToast("You are already on the waitlist!");
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
  showToast(`Added to waitlist (#${game.waitlistPlayerIds.length}) for ${game.title}!`);
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
  showToast(`Removed from waitlist for ${game.title}.`);
};

window.toggleMatchesCollapse = (gameId) => {
  state.collapsedMatches = state.collapsedMatches || {};
  state.collapsedMatches[gameId] = !state.collapsedMatches[gameId];
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

  const currentUserId = state.currentUser?.id;

  // 1. Determine games for current view filter
  const isCompletedFilter = currentMatchFilter === "completed";
  let targetGames;
  if (isCompletedFilter) {
    targetGames = state.games.filter(g => g.status === "completed")
      .sort((a, b) => parseGameDate(b.scheduledDate).getTime() - parseGameDate(a.scheduledDate).getTime());
  } else {
    targetGames = state.games.filter(isUpcomingGame)
      .sort((a, b) => parseGameDate(a.scheduledDate).getTime() - parseGameDate(b.scheduledDate).getTime());
  }

  const canJoin = (game) => {
    const maxPerTeam = Math.max(1, Math.floor((game.maxPlayers || 4) / 2));
    const team1Spots = maxPerTeam - (game.team1PlayerIds ? game.team1PlayerIds.length : 0);
    const team2Spots = maxPerTeam - (game.team2PlayerIds ? game.team2PlayerIds.length : 0);
    const hasOpenSpots = team1Spots > 0 || team2Spots > 0;
    if (!hasOpenSpots) return false;
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

  // 2. Apply selected view filter ('all', 'myGames', 'openSpots', 'completed')
  const displayGames = targetGames.filter(game => {
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
      "You are not registered in any upcoming games.<br>Tap 'Needs Players' to join or '+ New Game' to host!" :
      currentMatchFilter === "openSpots" ?
      "No open games needing players for your rating tier.<br>Tap '+ New Game' above to host a game!" :
      "No upcoming games available.<br>Tap '+ New Game' above to host a game!";
    container.innerHTML = `<div style="text-align:center; padding: 40px; color: var(--text-muted);">${emptyMsg}</div>`;
    return;
  }

  container.innerHTML = displayGames.map(game => {
    const allPlayerIds = [...(game.team1PlayerIds || []), ...(game.team2PlayerIds || [])];
    const maxPlayers = game.maxPlayers || 4;
    const spotsLeft = Math.max(0, maxPlayers - allPlayerIds.length);
    const needsPlayers = spotsLeft > 0;
    const isMember = currentUserId && (
      allPlayerIds.includes(currentUserId) ||
      game.hostPlayerId === currentUserId
    );
    const isHost = currentUserId && (
      (game.hostPlayerId && game.hostPlayerId === currentUserId) ||
      (game.team1PlayerIds?.[0] === currentUserId)
    );
    const hostPlayer = game.hostPlayerId ? state.getPlayer(game.hostPlayerId) : (game.team1PlayerIds?.[0] ? state.getPlayer(game.team1PlayerIds[0]) : null);

    const dateStr = parseGameDate(game.scheduledDate).toLocaleDateString("en-US", {
      weekday: "short",
      month: "short",
      day: "numeric",
      hour: "numeric",
      minute: "2-digit"
    });

    const renderPoolPlayer = (pid) => {
      const p = state.getPlayer(pid);
      if (!p) {
        const name = pid.startsWith("guest_") ? pid.replace("guest_", "") : "Player";
        return `<div class="player-item" style="display:flex; align-items:center; gap:6px; padding: 6px 10px; background: rgba(0,0,0,0.03); border-radius: 8px;">
          ${renderAvatar("🏐", "", false)}
          <span style="font-weight:600; font-size:13px;">${name}</span>
        </div>`;
      }
      const isFlaker = (p.consecutiveBackouts || 0) >= 3;
      return `<div class="player-item" style="display:flex; align-items:center; gap:6px; padding: 6px 10px; background: rgba(0,0,0,0.03); border-radius: 8px;">
        ${renderAvatar(p.avatarEmoji, "", isFlaker)}
        <div style="display:flex; flex-direction:column; min-width:0;">
          <span style="font-weight:700; font-size:13px; text-overflow:ellipsis; overflow:hidden; white-space:nowrap;">${p.nickname || p.name}</span>
          <div style="display:flex; align-items:center; gap:4px; font-size:10px;">
            <span class="badge badge-tier-${(p.rating || 'b').toLowerCase()}" style="font-size:9px; padding:1px 4px;">${p.rating || 'B'}</span>
            <span style="color:#b45309; font-weight:700;">⭐${formatStarRating(p)}</span>
          </div>
        </div>
      </div>`;
    };

    const poolPlayersHtml = allPlayerIds.map(renderPoolPlayer).join("");

    const waitlistIds = game.waitlistPlayerIds || [];
    const isWaitlisted = currentUserId && waitlistIds.includes(currentUserId);
    const waitlistPos = isWaitlisted ? (waitlistIds.indexOf(currentUserId) + 1) : null;

    let footerButtons = "";
    if (isMember) {
      const msgCount = game.messages ? game.messages.length : 0;
      footerButtons += `<button class="btn btn-outline btn-sm" style="color:#0284c7; border-color:#bae6fd; margin-right:6px;" onclick="window.openGameQRCodeModal('${game.id}')">📱 QR Code</button> `;
      footerButtons += `<button class="btn btn-outline btn-sm" style="color:#0284c7; border-color:#bae6fd; margin-right:6px;" onclick="window.openMatchChatModal('${game.id}')">💬 Chat${msgCount > 0 ? ' (' + msgCount + ')' : ''}</button> `;
      footerButtons += `<button class="btn btn-outline btn-sm" style="color:#ef4444; border-color:#fca5a5; margin-right:6px;" onclick="window.leaveGame('${game.id}')">Leave Game</button> `;
      footerButtons += `<button class="btn btn-outline btn-sm" style="color:#a855f7; border-color:#d8b4fe; margin-right:6px;" onclick="window.openRandomTeamsModalForGame('${game.id}')">🎲 Random</button> `;
      footerButtons += `<button class="btn btn-outline btn-sm" style="margin-right:6px;" onclick="window.openEditMatchModal('${game.id}')">⚙️ Edit</button> `;

      const otherPlayers = allPlayerIds.filter(id => id !== currentUserId);
      if ((isHost && otherPlayers.length === 0) || isRootUser(state.currentUser)) {
        footerButtons += `<button class="btn btn-outline btn-sm" style="color:#ef4444; border-color:#ef4444; margin-left:6px;" onclick="window.deleteGame('${game.id}')">🗑️ Delete Game ${isRootUser(state.currentUser) ? '(Root)' : ''}</button>`;
      }
    } else {
      footerButtons += `<button class="btn btn-outline btn-sm" style="color:#0284c7; border-color:#bae6fd; margin-right:6px;" onclick="window.openGameQRCodeModal('${game.id}')">📱 QR Code</button> `;
      if (isWaitlisted) {
        footerButtons += `<button class="btn btn-outline btn-sm" style="color:#ef4444; border-color:#fca5a5; margin-right:6px;" onclick="window.leaveWaitlist('${game.id}')">Leave Waitlist (#${waitlistPos})</button> `;
      }
      if (isRootUser(state.currentUser)) {
        footerButtons += `<button class="btn btn-outline btn-sm" style="color:#ef4444; border-color:#ef4444; margin-left:6px;" onclick="window.deleteGame('${game.id}')">🗑️ Delete Game (Root)</button>`;
      }
    }

    const myMatchBadge = isMember ? 
      `<span class="badge" style="background:#dbeafe; color:#1d4ed8; font-weight:800; font-size:10px; margin-right:4px;">🏐 My Game</span>` : '';

    const myWaitlistBadge = isWaitlisted ?
      `<span class="badge" style="background:#f3e8ff; color:#7e22ce; font-weight:800; font-size:10px; margin-right:4px;">⏳ Waitlisted #${waitlistPos}</span>` : '';

    const waitlistCountBadge = (!isWaitlisted && waitlistIds.length > 0) ?
      `<span class="badge" style="background:#f3e8ff; color:#7e22ce; font-weight:800; font-size:10px; margin-right:4px;">⏳ ${waitlistIds.length} Waitlist</span>` : '';

    const subMatchesBadge = (game.subMatches && game.subMatches.length > 0) ? 
      `<span class="badge" style="background:rgba(168, 85, 247, 0.15); color:#a855f7; font-weight:800; font-size:10px; margin-right:4px;">🎾 ${game.subMatches.length} Matches</span>` : '';

    const isMatchesCollapsed = !!(state.collapsedMatches && state.collapsedMatches[game.id]);

    const pCount = game.maxPlayers || 4;
    const formatLabel = pCount === 2 ? "1v1 Singles" : pCount === 6 ? "3v3 Triples" : "2v2 Doubles";
    const playersBadge = `<span class="badge" style="background:#f1f5f9; color:#475569; font-weight:700; font-size:10px; margin-right:4px;">👥 ${formatLabel}</span>`;

    const lockedBadge = game.isLevelLocked ? 
      `<span class="badge" style="background:#fef3c7; color:#b45309; font-weight:800; font-size:10px; margin-right:4px;">🔒 Level Locked</span>` : '';

    const hostSubtitle = hostPlayer ? 
      `<div style="font-size:12px; color:var(--text-muted); margin-top:2px;">👑 Host: <strong>${hostPlayer.nickname || hostPlayer.name}</strong> (⭐ ${formatStarRating(hostPlayer)})</div>` : '';

    const notesDisplay = game.notes ? `<div style="font-size:11px; color:var(--text-muted); margin-top:4px; font-style:italic;">"${game.notes}"</div>` : '';

    return `
      <div class="match-card" id="match-card-${game.id}">
        <div class="match-header">
          <div>
            <div style="font-weight: 800; font-size: 16px;">${game.title}</div>
            <div class="match-court">📍 ${game.courtLocation} • ${game.courtNumber || "Court #1"}</div>
            ${hostSubtitle}
            ${notesDisplay}
          </div>
          <div style="display:flex; align-items:center; flex-wrap:wrap; gap:4px;">
            <button type="button" class="btn btn-outline btn-sm" style="padding: 2px 7px; font-size: 11px; border-radius: 6px; border-color: #cbd5e1; color: #0284c7; background: #f0f9ff; font-weight:700;" onclick="window.openGameQRCodeModal('${game.id}')" title="Scan QR Code to Join">📱 QR</button>
            ${myMatchBadge}
            ${myWaitlistBadge}
            ${waitlistCountBadge}
            ${subMatchesBadge}
            ${playersBadge}
            ${(() => {
              const allowedList = (game.allowedRatings && game.allowedRatings.length > 0) ? game.allowedRatings : [game.targetRating || "B"];
              if (allowedList.length >= 6) {
                return `<span class="badge" style="background:#e0f2fe; color:#0369a1; font-weight:800; font-size:10px;">🌐 All Levels</span>`;
              }
              return allowedList.map(t => `<span class="badge badge-tier-${t.toLowerCase()}">${t}</span>`).join(" ");
            })()}
          </div>
        </div>

        <!-- Players Pool Card -->
        <div style="background: var(--bg-card, #f8fafc); border: 1px solid var(--border, #e2e8f0); border-radius: 12px; padding: 12px; margin: 12px 0;">
          <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom: 8px;">
            <span style="font-size: 11px; font-weight: 800; color: var(--text-muted); text-transform: uppercase;">
              👥 Players Pool (${allPlayerIds.length}/${maxPlayers} Players)
            </span>
            <span style="font-size: 11px; font-weight: 700; color: ${spotsLeft === 0 ? '#22c55e' : 'var(--accent)'};">
              ${spotsLeft === 0 ? 'Pool Full ✓' : spotsLeft + ' Open Spot' + (spotsLeft > 1 ? 's' : '')}
            </span>
          </div>
          <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 8px;">
            ${poolPlayersHtml}
            ${needsPlayers && !isMember ? `
              <button type="button" class="btn btn-outline btn-sm" style="color:var(--accent); border-color:var(--accent); border-style:dashed; min-height: 40px; font-weight:700;" onclick="window.joinGamePool('${game.id}')">
                + Join Player Pool
              </button>
            ` : ''}
          </div>

          ${spotsLeft === 0 && !isMember ? (
            isWaitlisted ? `
              <div style="background: #faf5ff; border: 1px solid #e9d5ff; border-radius: 10px; padding: 10px 14px; margin-top: 10px; display: flex; justify-content: space-between; align-items: center;">
                <div style="font-size: 12px; font-weight: 700; color: #7e22ce;">
                  ⏳ You are #${waitlistPos} on the Waitlist
                </div>
                <button type="button" class="btn btn-outline btn-sm" style="color: #ef4444; border-color: #fca5a5; padding: 3px 8px; font-size: 11px;" onclick="window.leaveWaitlist('${game.id}')">
                  Leave Waitlist
                </button>
              </div>
            ` : `
              <button type="button" class="btn btn-sm" style="background: #f3e8ff; color: #7e22ce; border: 1px dashed #c084fc; font-weight: 700; width: 100%; margin-top: 10px; padding: 9px 12px; border-radius: 8px; font-size: 12px;" onclick="window.joinWaitlist('${game.id}')">
                ⏳ Pool Full • Join Waitlist (${waitlistIds.length} queued)
              </button>
            `
          ) : ''}

          ${waitlistIds.length > 0 ? `
            <div style="margin-top: 12px; padding-top: 10px; border-top: 1px dashed var(--border, #e2e8f0);">
              <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
                <span style="font-size: 11px; font-weight: 800; color: #7e22ce; text-transform: uppercase;">
                  ⏳ Waitlist (${waitlistIds.length} Queued)
                </span>
                <span style="font-size: 10px; color: var(--text-muted);">Auto-promotes when a spot opens</span>
              </div>
              <div style="display: flex; flex-direction: column; gap: 6px;">
                ${waitlistIds.map((pid, idx) => {
                  const p = state.players.find(x => x.id === pid) || { id: pid, name: "Player", nickname: "", rating: "B" };
                  const pName = p.nickname ? `${p.name} (${p.nickname})` : p.name;
                  const isMe = currentUserId === pid;
                  return `
                    <div style="display: flex; align-items: center; justify-content: space-between; background: var(--card-bg, #fff); border: 1px solid var(--border, #e2e8f0); border-radius: 8px; padding: 6px 10px;">
                      <div style="display: flex; align-items: center; gap: 8px;">
                        <span style="font-size: 11px; font-weight: 800; background: #a855f7; color: #fff; width: 22px; height: 22px; border-radius: 50%; display: flex; align-items: center; justify-content: center;">#${idx + 1}</span>
                        <div>
                          <div style="font-size: 12px; font-weight: 700; color: var(--text-main);">${pName}</div>
                          <div style="font-size: 10px; color: var(--text-muted);">${p.rating}</div>
                        </div>
                      </div>
                      ${isMe ? `
                        <button type="button" class="btn btn-outline btn-sm" style="color: #ef4444; border-color: #fca5a5; padding: 2px 8px; font-size: 11px;" onclick="window.leaveWaitlist('${game.id}')">Leave</button>
                      ` : ''}
                    </div>
                  `;
                }).join("")}
              </div>
            </div>
          ` : ''}
        </div>

        <!-- Matches in this Game Section -->
        <div style="margin: 14px 0;">
          <div 
            onclick="window.toggleMatchesCollapse('${game.id}')"
            style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; cursor: pointer; user-select: none; padding: 4px 0;"
            title="Click to ${isMatchesCollapsed ? 'expand' : 'collapse'} matches"
          >
            <span style="font-size: 11px; font-weight: 800; color: var(--text-muted); text-transform: uppercase; display: flex; align-items: center; gap: 6px;">
              🎾 Matches in This Game (${(game.subMatches || []).length})
            </span>
            <button type="button" class="btn btn-sm" style="background: rgba(168, 85, 247, 0.12); color: #a855f7; border: 1px solid rgba(168, 85, 247, 0.3); font-size: 11px; font-weight: 800; padding: 3px 10px; border-radius: 20px; cursor: pointer; display: flex; align-items: center; gap: 4px;">
              ${isMatchesCollapsed ? 'Expand ▼' : 'Collapse ▲'}
            </button>
          </div>
          ${isMatchesCollapsed ? `
            <div onclick="window.toggleMatchesCollapse('${game.id}')" style="cursor: pointer; background: var(--bg-card, #fff); border: 1px dashed rgba(168, 85, 247, 0.4); border-radius: 10px; padding: 12px 14px; display: flex; justify-content: space-between; align-items: center; color: var(--text-muted); font-size: 12px; font-weight: 600;">
              <span>🎾 ${(game.subMatches || []).length > 0 ? (game.subMatches.length + ' matches hidden') : 'Matches section collapsed'}</span>
              <span style="color: #a855f7; font-weight: 800;">Tap to Expand ▼</span>
            </div>
          ` : `
          ${(!game.subMatches || game.subMatches.length === 0) ? `
            <div style="background: rgba(168, 85, 247, 0.05); border: 1px dashed rgba(168, 85, 247, 0.3); border-radius: 12px; padding: 16px; text-align: center;">
              <div style="font-size: 26px; margin-bottom: 4px;">🎲</div>
              <div style="font-size: 14px; font-weight: 800; margin-bottom: 4px;">No Matches Generated Yet</div>
              <div style="font-size: 11px; color: var(--text-muted); margin-bottom: 12px; max-width: 400px; margin-left:auto; margin-right:auto;">
                Randomly generate round-robin or King of the Court tournament sets for the ${allPlayerIds.length} players in this pool.
              </div>
              <button type="button" class="btn btn-sm" style="background: linear-gradient(135deg, #a855f7, #ec4899); border: none; color: white; font-weight: 800; padding: 8px 16px; border-radius: 8px;" onclick="window.openRandomTeamsModalForGame('${game.id}')">
                🎲 Random Generate Matches
              </button>
            </div>
          ` : `
            <div style="display: flex; flex-direction: column; gap: 8px;">
              ${game.subMatches.map((m, mIdx) => {
                const s1Val = (m.team1Score !== undefined && m.team1Score !== null) ? m.team1Score : "";
                const s2Val = (m.team2Score !== undefined && m.team2Score !== null) ? m.team2Score : "";
                const mKey = m.id || mIdx;
                return `
                  <div style="background: var(--bg-card, #fff); border: 1px solid var(--border, #e2e8f0); border-radius: 10px; padding: 10px 12px;">
                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px;">
                      <span style="font-size: 11px; font-weight: 800; color: var(--accent);">MATCH ${m.matchNumber || mIdx + 1} • ${m.courtNumber || "Court #1"}</span>
                      ${m.isCompleted ? '<span style="font-size: 10px; color: #22c55e; font-weight: 800;">SCORED ✓</span>' : '<span style="font-size: 10px; color: var(--text-muted);">Scheduled</span>'}
                    </div>
                    <div style="display: flex; justify-content: space-between; align-items: center; font-weight: 700; font-size: 13px; margin-bottom: 6px;">
                      <div style="flex: 1; text-align: left;">${resolvePlayerNames(m.team1PlayerIds)}</div>
                      <span style="color: var(--text-muted); font-size: 11px; font-weight: 900; padding: 0 8px;">VS</span>
                      <div style="flex: 1; text-align: right;">${resolvePlayerNames(m.team2PlayerIds)}</div>
                    </div>
                    ${m.restingPlayerIds && m.restingPlayerIds.length > 0 ? `
                      <div style="font-size: 10px; color: var(--text-muted); margin-bottom: 6px;">
                        ⏸ Resting: ${resolvePlayerNames(m.restingPlayerIds)}
                      </div>
                    ` : ''}
                    <div style="display: flex; align-items: center; gap: 6px; padding-top: 4px; border-top: 1px solid var(--border, #f1f5f9);">
                      <span style="font-size: 11px; font-weight: 700; color: var(--text-muted);">Score:</span>
                      <input type="number" id="sub-s1-${game.id}-${mKey}" class="form-input" style="width: 52px; padding: 3px 6px; font-size: 12px; font-weight: 700; text-align: center;" placeholder="T1" value="${s1Val}">
                      <span>–</span>
                      <input type="number" id="sub-s2-${game.id}-${mKey}" class="form-input" style="width: 52px; padding: 3px 6px; font-size: 12px; font-weight: 700; text-align: center;" placeholder="T2" value="${s2Val}">
                      <button type="button" class="btn btn-sm btn-outline" style="font-size: 11px; padding: 2px 8px; margin-left: 6px;" onclick="window.updateSubMatchScoreWeb('${game.id}', '${mKey}')">
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
                <button type="button" class="btn btn-outline btn-sm" style="font-size: 11px; color: #a855f7; border-color: #d8b4fe;" onclick="window.openRandomTeamsModalForGame('${game.id}')">
                  🎲 Regenerate Matches
                </button>
              </div>
            </div>
          `}
          `}
        </div>

        <div class="match-footer" style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:8px;">
          <div style="font-size: 12px; color: var(--text-muted);">
            🕒 ${dateStr}
          </div>
          <div style="display:flex; align-items:center;">${footerButtons}</div>
        </div>
    `;
  }).join("");
}

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
          <div class="rank-name">${player.name} ${player.nickname ? `"${player.nickname}"` : ""}</div>
          <div class="rank-sub">📍 ${player.homeBeach} • <span class="badge badge-tier-${player.rating.toLowerCase()}">${player.rating}</span></div>
        </div>
        <div class="rank-stats">
          <div class="rank-elo">${player.eloRating} ELO</div>
          <div class="rank-record">${player.wins}W - ${player.losses}L (${pct}%)</div>
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
  document.getElementById("edit-profile-beach").value = user.homeBeach || "Main Beach";
  document.getElementById("edit-profile-bio").value = user.bio || "";

  window.selectedEditProfileAvatar = user.avatarEmoji || "slug";
  document.querySelectorAll("#edit-profile-avatars .avatar-btn").forEach(btn => {
    btn.classList.toggle("selected", btn.dataset.avatar === window.selectedEditProfileAvatar);
    btn.onclick = () => {
      document.querySelectorAll("#edit-profile-avatars .avatar-btn").forEach(b => b.classList.remove("selected"));
      btn.classList.add("selected");
      window.selectedEditProfileAvatar = btn.dataset.avatar;
    };
  });

  modal.classList.add("show");
};

window.closeEditProfileModal = () => {
  const modal = document.getElementById("edit-profile-modal");
  if (modal) modal.classList.remove("show");
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

// NAVIGATION
export function switchTab(tabId) {
  document.querySelectorAll(".tab-content").forEach(el => el.classList.remove("active"));
  document.querySelectorAll(".nav-item").forEach(el => el.classList.remove("active"));

  const normalizedId = (tabId === "ladder" || tabId === "popular") ? "ladders" : tabId;
  const targetTab = document.getElementById(`tab-${normalizedId}`);
  const targetNav = document.getElementById(`nav-${normalizedId}`);

  if (targetTab) targetTab.classList.add("active");
  if (targetNav) targetNav.classList.add("active");

  if (normalizedId === "matches") renderMatches();
  if (normalizedId === "matchmaker") renderPickupQueue();
  if (normalizedId === "ladders") {
    renderLadder();
    renderPopularKids();
  }
  if (normalizedId === "profile") renderProfile();
}

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
    state.saveLocal();
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
  const newPlayer = {
    id: "player-" + Date.now(),
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
  state.saveLocal();
  savePlayerToFirestore(newPlayer);

  window.closeAuthModal();
  renderHeader();
  renderProfile();
  renderLadder();
  renderMatches();
  showToast(`Welcome to Volleyball Match, ${newPlayer.name}! 🏐`);
};

window.handleLogout = () => {
  state.currentUser = null;
  localStorage.removeItem("setgames_current_user_id");
  state.saveLocal();
  renderHeader();
  window.showAuthModal();
  showToast("Logged out successfully.");
};

// GLOBAL ACTION HANDLERS (available on window)
window.joinGame = (gameId) => {
  const game = state.games.find(g => g.id === gameId);
  if (!game) return;
  if (!state.currentUser) {
    window.showAuthModal();
    return;
  }

  if (game.team1PlayerIds?.includes(state.currentUser.id) || game.team2PlayerIds?.includes(state.currentUser.id)) {
    showToast("You are already registered in this match!");
    return;
  }

  // Level Lock Check
  const allowed = (game.allowedRatings && game.allowedRatings.length > 0) ? game.allowedRatings : [game.targetRating || "B"];
  if (game.isLevelLocked && !allowed.includes(state.currentUser.rating)) {
    showToast(`Level Locked: This match is locked to ${allowed.join(", ")} players only (Your rating: ${state.currentUser.rating}).`);
    return;
  }

  const maxPerTeam = Math.max(1, Math.floor((game.maxPlayers || 4) / 2));
  if ((game.team1PlayerIds?.length || 0) < maxPerTeam) {
    game.team1PlayerIds.push(state.currentUser.id);
  } else if ((game.team2PlayerIds?.length || 0) < maxPerTeam) {
    game.team2PlayerIds.push(state.currentUser.id);
  } else {
    showToast("Sorry, this match is already full!");
    return;
  }

  // Check if game is now full
  if ((game.team1PlayerIds?.length || 0) >= maxPerTeam && (game.team2PlayerIds?.length || 0) >= maxPerTeam) {
    triggerWebPushNotification("🏐 Set Game Locked!", `${game.title} at ${game.courtLocation} is now fully locked!`);
  }

  state.saveLocal();
  saveGameToFirestore(game);
  renderMatches();
  showToast(`Joined ${game.title}! See you on the sand.`);
};

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
  const titleInput = document.getElementById("create-title");

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

  if (titleInput) {
    titleInput.value = formatDefaultGameTitle(d);
    titleInput.dataset.autoGenerated = "true";
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
  const title = document.getElementById("create-title").value.trim();
  const checkedBoxes = Array.from(document.querySelectorAll("input[name='create-tier-cb']:checked"));
  const allowedRatings = checkedBoxes.map(cb => cb.value);
  const targetRating = allowedRatings[0] || (state.currentUser?.rating || "B");
  const isLevelLocked = document.getElementById("create-level-locked").checked;
  const maxPlayers = parseInt(document.getElementById("create-max-players")?.value) || 4;
  const format = document.getElementById("create-format").value;
  const courtLocation = document.getElementById("create-beach").value;
  const courtNumber = document.getElementById("create-court").value.trim() || "Court #1";
  const scheduledDate = new Date(document.getElementById("create-date").value).toISOString();
  const notes = document.getElementById("create-notes").value.trim();

  const defaultTitle = formatDefaultGameTitle(new Date(document.getElementById("create-date").value));
  const newGame = {
    id: "game-" + Date.now(),
    title: title || defaultTitle,
    targetRating,
    allowedRatings: allowedRatings.length > 0 ? allowedRatings : [targetRating],
    isLevelLocked,
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

// Edit Match (Participants)
window.openEditMatchModal = (gameId) => {
  const game = state.games.find(g => g.id === gameId);
  if (!game) return;
  const isMember = state.currentUser && (
    game.team1PlayerIds?.includes(state.currentUser.id) ||
    game.team2PlayerIds?.includes(state.currentUser.id) ||
    game.hostPlayerId === state.currentUser.id
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
  if (document.getElementById("edit-max-players")) {
    document.getElementById("edit-max-players").value = game.maxPlayers || 4;
  }
  document.getElementById("edit-format").value = game.format || "Best of 3 Sets (21-21-15)";
  document.getElementById("edit-beach").value = game.courtLocation || "Main Beach";
  document.getElementById("edit-court").value = game.courtNumber || "Court #1";
  document.getElementById("edit-notes").value = game.notes || "";
  
  const dateInput = document.getElementById("edit-date");
  if (dateInput) {
    const d = new Date(game.scheduledDate);
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

// Cancel & Delete Game (Host only when empty, or Root user anytime)
window.deleteGame = (gameId) => {
  const game = state.games.find(g => g.id === gameId);
  if (!game) return;

  const isRoot = isRootUser(state.currentUser);
  if (!isRoot) {
    const isHost = state.currentUser && (
      (game.hostPlayerId && game.hostPlayerId === state.currentUser.id) ||
      (game.team1PlayerIds?.[0] === state.currentUser.id)
    );
    if (!isHost) {
      showToast("Only the game host or Root user can delete this game.");
      return;
    }

    const otherPlayers = [...(game.team1PlayerIds || []), ...(game.team2PlayerIds || [])].filter(id => id !== state.currentUser?.id);
    if (otherPlayers.length > 0) {
      showToast("Cannot delete game while other players are joined.");
      return;
    }
  }

  const promptMsg = isRoot 
    ? `As Root Admin, permanently delete "${game.title}" from the database?`
    : `Are you sure you want to cancel and delete "${game.title}"?`;

  if (!confirm(promptMsg)) {
    return;
  }

  state.games = state.games.filter(g => g.id !== gameId);
  state.saveLocal();
  deleteGameFromFirestore(gameId);
  renderMatches();
  showToast("Game deleted.");
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
    const formattedDate = new Date(game.scheduledTime).toLocaleDateString("en-US", {
      weekday: "short",
      month: "short",
      day: "numeric",
      hour: "numeric",
      minute: "2-digit"
    });
    detailsEl.textContent = `📍 ${game.courtLocation} • ${game.courtNumber || "Court #1"} • 📅 ${formattedDate}`;
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
    date: new Date().toISOString()
  };

  game.messages.push(newMsg);
  state.saveLocal();
  saveGameToFirestore(game);
  window.renderChatMessages();
  renderMatches();
  showToast(`Sent: "${text}"`);
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

window.handleSwitchUser = () => {
  const select = document.getElementById("switch-user-select");
  const player = state.players.find(p => p.id === select.value);
  if (player) {
    state.currentUser = player;
    state.saveLocal();
    renderHeader();
    renderProfile();
    showToast(`Switched active profile to ${player.name}`);
  }
};

window.handleJoinPickup = () => {
  if (!state.currentUser) return;
  if (!state.pickupQueue.includes(state.currentUser.id)) {
    state.pickupQueue.push(state.currentUser.id);
  }

  const queueCountEl = document.getElementById("pickup-count");
  if (queueCountEl) queueCountEl.textContent = `${state.pickupQueue.length}/4`;

  if (state.pickupQueue.length >= 4) {
    const players = state.pickupQueue.splice(0, 4);
    const fastGame = {
      id: "pickup-" + Date.now(),
      title: "Fast Pickup 2v2",
      targetRating: state.currentUser.rating,
      courtLocation: state.currentUser.homeBeach,
      courtNumber: "Court #1",
      scheduledDate: new Date(Date.now() + 3600000).toISOString(),
      status: "scheduled",
      isAutoMatched: true,
      matchedOptionName: "Instant Pickup Lobby",
      team1PlayerIds: [players[0], players[3]],
      team2PlayerIds: [players[1], players[2]],
      team1Score: 0,
      team2Score: 0,
      setScores: []
    };
    state.games.unshift(fastGame);
    state.saveLocal();
    saveGameToFirestore(fastGame);

    // Trigger Web Push Notification
    triggerWebPushNotification("⚡️ Pickup Lobby Full (4/4)!", `Your fast pickup game at ${state.currentUser.homeBeach} is locked and starting soon!`);

    showToast("⚡️ Pickup lobby full! Game scheduled on Court #1!");
    switchTab("matches");
  } else {
    showToast(`Joined pickup queue (${state.pickupQueue.length}/4). Game locks when 4 players join!`);
  }
};

window.handleSaveAvailability = (e) => {
  e.preventDefault();
  if (!state.currentUser) return;

  const date = document.getElementById("avail-date").value;
  const start = document.getElementById("avail-start").value;
  const end = document.getElementById("avail-end").value;
  const beach = document.getElementById("avail-beach").value;

  const checkedTiers = Array.from(document.querySelectorAll("input[name='avail-tier']:checked")).map(el => el.value);

  const slot = {
    id: "slot-" + Date.now(),
    playerId: state.currentUser.id,
    date,
    startTime: start,
    endTime: end,
    preferredBeach: beach,
    acceptedTiers: checkedTiers
  };

  state.availabilitySlots.push(slot);
  state.saveLocal();
  saveSlotToFirestore(slot);
  showToast("Free window saved! Matchmaker is searching for partners.");
};

// INITIALIZATION & REAL-TIME FIRESTORE LISTENERS
// ==========================================
// KING OF THE COURT & RANDOM GENERATOR MODAL
// ==========================================
window.currentGeneratedMatches = [];
window.randomGeneratorMode = 'king'; // 'king' or 'mixer'
window.currentRandomPoolPlayers = ["Player 1", "Player 2", "Player 3", "Player 4"];

window.setRandomGeneratorMode = (m) => {
  window.randomGeneratorMode = m;
  const isKing = m === 'king';

  document.getElementById("rt-mode-king")?.classList.toggle("active", isKing);
  document.getElementById("rt-mode-king")?.classList.toggle("btn-outline", !isKing);
  document.getElementById("rt-mode-mixer")?.classList.toggle("active", !isKing);
  document.getElementById("rt-mode-mixer")?.classList.toggle("btn-outline", isKing);

  const descEl = document.getElementById("rt-mode-desc");
  if (descEl) {
    descEl.textContent = isKing
      ? "4 Players per court (e.g. 12 players = 3 courts). Players 1–4 on Court 1, 5–8 on Court 2, etc. Each court plays 3 rotating sets with live individual score tracking!"
      : "Continuous social rotations across all players with an equitable resting queue.";
  }

  const numGroup = document.getElementById("rt-num-games-group");
  const courtGroup = document.getElementById("rt-court-group");
  if (numGroup) numGroup.style.display = isKing ? "none" : "block";
  if (courtGroup) courtGroup.style.gridColumn = isKing ? "span 2" : "span 1";

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
          lines += `<div style="margin-top: 2px; color: var(--text-muted);">• Court ${c + 1}: ${cPlayers.join(", ")}</div>`;
        }
        if (total % 4 !== 0) {
          const rest = window.currentRandomPoolPlayers.slice(courts * 4);
          lines += `<div style="margin-top: 4px; color: #ef4444; font-weight: 600;">⚠️ ${total % 4} Alternate/Bye: ${rest.join(", ")} (Add ${4 - (total % 4)} more for Court ${courts + 1})</div>`;
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
    const courtNum = Math.floor(idx / 4) + 1;
    return `
      <div style="display: flex; align-items: center; gap: 8px;">
        <span style="display: inline-flex; align-items: center; justify-content: center; width: 22px; height: 22px; border-radius: 50%; background: var(--accent-light); color: var(--accent); font-size: 10px; font-weight: 800;">${idx + 1}</span>
        <input type="text" class="form-input" style="padding: 4px 8px; font-size: 13px; flex: 1;" value="${pName}" onchange="window.currentRandomPoolPlayers[${idx}] = this.value.trim()">
        ${window.randomGeneratorMode === 'king' ? `
          <span style="font-size: 10px; font-weight: 700; background: rgba(255, 106, 0, 0.12); color: var(--accent); padding: 2px 6px; border-radius: 999px;">Court ${courtNum}</span>
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

window.openRandomTeamsModal = (initialPlayers, initialCourt, initialFormat) => {
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
  window.openRandomTeamsModal(names, game.courtLocation, game.format);
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
    // Group by courtGroup
    const courtCount = Math.floor(window.currentRandomPoolPlayers.length / 4);
    let html = "";

    for (let c = 1; c <= courtCount; c++) {
      const courtPlayers = window.currentRandomPoolPlayers.slice((c - 1) * 4, c * 4);
      const courtMatches = window.currentGeneratedMatches.filter(m => m.courtGroup === c);
      const standings = calculateKingStandings(courtPlayers, courtMatches);

      html += `
        <div style="background: var(--bg-card); border: 1.5px solid rgba(255, 106, 0, 0.3); border-radius: 12px; padding: 12px 14px;">
          <!-- Court Header -->
          <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
            <div style="font-size: 13px; font-weight: 800; color: var(--accent);">
              👑 COURT #${c} (PLAYERS ${(c - 1) * 4 + 1}–${c * 4})
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

    for (let c = 0; c < courtCount; c++) {
      const courtPlayers = players.slice(c * 4, (c + 1) * 4);
      const cNum = c + 1;

      // Set 1: P0 & P1 vs P2 & P3
      matches.push({
        matchNumber: globalIdx++,
        courtGroup: cNum,
        courtNumber: `Court #${cNum}`,
        setNumber: 1,
        team1: [courtPlayers[0], courtPlayers[1]],
        team2: [courtPlayers[2], courtPlayers[3]],
        s1: "",
        s2: "",
        isCompleted: false
      });

      // Set 2: P0 & P2 vs P1 & P3
      matches.push({
        matchNumber: globalIdx++,
        courtGroup: cNum,
        courtNumber: `Court #${cNum}`,
        setNumber: 2,
        team1: [courtPlayers[0], courtPlayers[2]],
        team2: [courtPlayers[1], courtPlayers[3]],
        s1: "",
        s2: "",
        isCompleted: false
      });

      // Set 3: P0 & P3 vs P1 & P2
      matches.push({
        matchNumber: globalIdx++,
        courtGroup: cNum,
        courtNumber: `Court #${cNum}`,
        setNumber: 3,
        team1: [courtPlayers[0], courtPlayers[3]],
        team2: [courtPlayers[1], courtPlayers[2]],
        s1: "",
        s2: "",
        isCompleted: false
      });
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

      matches.push({
        matchNumber: i + 1,
        courtNumber: "Court #1",
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

  window.currentGeneratedMatches.push({
    matchNumber: window.currentGeneratedMatches.length + 1,
    courtNumber: "Court #1",
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

window.addEventListener("DOMContentLoaded", () => {
  renderHeader();
  renderMatches();
  renderLadder();
  renderPopularKids();
  renderProfile();

  if (!state.currentUser) {
    window.showAuthModal();
  }

  // Bottom navigation tab click
  document.querySelectorAll(".nav-item").forEach(item => {
    item.addEventListener("click", () => {
      switchTab(item.dataset.tab);
    });
  });

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
  document.getElementById("avail-form")?.addEventListener("submit", window.handleSaveAvailability);

  // Auto-fill title on date change if user hasn't typed custom title
  const createDateInput = document.getElementById("create-date");
  const createTitleInput = document.getElementById("create-title");
  if (createDateInput && createTitleInput) {
    createDateInput.addEventListener("input", () => {
      if (createTitleInput.dataset.autoGenerated === "true") {
        const d = new Date(createDateInput.value);
        if (!isNaN(d.getTime())) {
          createTitleInput.value = formatDefaultGameTitle(d);
        }
      }
    });
    createTitleInput.addEventListener("input", () => {
      createTitleInput.dataset.autoGenerated = "false";
    });
  }

  // Hook Real-time Cloud Listeners
  subscribeToPlayers((remotePlayers) => {
    if (remotePlayers && remotePlayers.length > 0) {
      state.players = remotePlayers;
      if (state.currentUser) {
        state.currentUser = remotePlayers.find(p => p.id === state.currentUser.id) || state.currentUser;
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
    if (remoteGames && remoteGames.length > 0) {
      if (hasCompletedInitialGamesSyncWeb && state.currentUser) {
        const userId = state.currentUser.id;
        remoteGames.forEach(remoteGame => {
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
      state.games = remoteGames.filter(g => g.status !== "canceled");
      state.saveLocal();
      renderMatches();
      if (window.activeChatGameId) {
        window.renderChatMessages();
      }
      handleIncomingGameRoute();
    }
  });

  subscribeToSlots((remoteSlots) => {
    if (remoteSlots && remoteSlots.length > 0) {
      state.availabilitySlots = remoteSlots;
      state.saveLocal();
    }
  });

  // Handle incoming deep link or game route from QR scan
  handleIncomingGameRoute();
});
