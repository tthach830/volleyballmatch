import { initializeApp } from "https://www.gstatic.com/firebasejs/11.4.0/firebase-app.js";
import { 
  getFirestore, 
  collection, 
  doc, 
  setDoc, 
  deleteDoc, 
  onSnapshot 
} from "https://www.gstatic.com/firebasejs/11.4.0/firebase-firestore.js";
import { 
  getAnalytics, 
  isSupported, 
  logEvent 
} from "https://www.gstatic.com/firebasejs/11.4.0/firebase-analytics.js";

const firebaseConfig = {
  apiKey: "AIzaSyDZZo-WxBBrfU-ctKyWDM0MP-ErTDt1QBg",
  authDomain: "volleyballmatch-13d66.firebaseapp.com",
  projectId: "volleyballmatch-13d66",
  storageBucket: "volleyballmatch-13d66.firebasestorage.app",
  messagingSenderId: "539381527858",
  appId: "1:539381527858:web:setgames"
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);

// Safe Firebase Analytics initialization with fallback
let analyticsInstance = null;
isSupported().then(supported => {
  if (supported) {
    try {
      analyticsInstance = getAnalytics(app);
      console.log("📊 Firebase Analytics initialized");
    } catch (e) {
      console.warn("Firebase Analytics init notice:", e);
    }
  }
}).catch(() => {});

// Unified event tracking for both Firebase Analytics & Microsoft Clarity
export function trackEvent(eventName, params = {}) {
  // 1. Log to Firebase Analytics
  try {
    if (analyticsInstance) {
      logEvent(analyticsInstance, eventName, params);
    }
  } catch (e) {
    console.warn("Firebase logEvent error:", eventName, e);
  }

  // 2. Tag Microsoft Clarity
  try {
    if (typeof window !== "undefined" && window.clarity) {
      window.clarity("event", eventName);
      if (params.page_title || params.screen_name) {
        window.clarity("set", "active_tab", params.page_title || params.screen_name);
      }
    }
  } catch (e) {
    console.warn("Clarity event notice:", e);
  }
}

// Associate user identity with Clarity & Firebase
export function setUserAnalyticsIdentity(user) {
  if (!user) return;
  try {
    if (typeof window !== "undefined" && window.clarity) {
      window.clarity("identify", user.id, undefined, undefined, user.name);
      window.clarity("set", "user_tier", user.rating || "Unrated");
      window.clarity("set", "user_beach", user.homeBeach || "Main Beach");
    }
  } catch (e) {}
}

// Save or update player in Firestore
export async function savePlayerToFirestore(player) {
  try {
    const playerRef = doc(db, "players", player.id);
    await setDoc(playerRef, player, { merge: true });
  } catch (error) {
    console.error("Error saving player to Firestore:", error);
  }
}

// Delete player from Firestore
export async function deletePlayerFromFirestore(playerId) {
  try {
    const playerRef = doc(db, "players", playerId);
    await deleteDoc(playerRef);
  } catch (error) {
    console.error("Error deleting player from Firestore:", error);
  }
}

// Save or update game in Firestore
export async function saveGameToFirestore(game) {
  try {
    const gameRef = doc(db, "games", game.id);
    await setDoc(gameRef, game, { merge: true });
  } catch (error) {
    console.error("Error saving game to Firestore:", error);
  }
}

// Delete game from Firestore
export async function deleteGameFromFirestore(gameId) {
  try {
    const gameRef = doc(db, "games", gameId);
    await deleteDoc(gameRef);
  } catch (error) {
    console.error("Error deleting game from Firestore:", error);
  }
}

// Save or update availability slot in Firestore
export async function saveSlotToFirestore(slot) {
  try {
    const slotRef = doc(db, "availabilitySlots", slot.id);
    await setDoc(slotRef, slot, { merge: true });
  } catch (error) {
    console.error("Error saving availability slot to Firestore:", error);
  }
}

// Delete availability slot from Firestore
export async function deleteSlotFromFirestore(slotId) {
  try {
    const slotRef = doc(db, "availabilitySlots", slotId);
    await deleteDoc(slotRef);
  } catch (error) {
    console.error("Error deleting availability slot from Firestore:", error);
  }
}

// Deterministic UUID matching iOS SetGame.parseUUID
function getDeterministicUUID(str) {
  if (!str) return "";
  const s = String(str).trim();
  if (/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(s)) {
    return s.toUpperCase();
  }
  const bytes = new TextEncoder().encode(s);
  const hash = new Uint8Array(16);
  for (let i = 0; i < bytes.length; i++) hash[i % 16] ^= bytes[i];
  hash[6] = (hash[6] & 0x0F) | 0x40;
  hash[8] = (hash[8] & 0x3F) | 0x80;
  const hex = Array.from(hash).map(b => b.toString(16).padStart(2, "0").toUpperCase()).join("");
  return `${hex.slice(0,8)}-${hex.slice(8,12)}-${hex.slice(12,16)}-${hex.slice(16,20)}-${hex.slice(20,32)}`;
}

// Real-time listener for players collection
export function subscribeToPlayers(onUpdate) {
  return onSnapshot(collection(db, "players"), (snapshot) => {
    const rawDocs = [];
    snapshot.forEach((doc) => {
      const data = doc.data();
      const id = (data.id != null && String(data.id).trim() !== "") ? data.id : doc.id;
      rawDocs.push({ ...data, id, _docId: doc.id });
    });

    const fullPlayers = [];
    const stubs = [];
    for (const p of rawDocs) {
      if (!p.name && !p.nickname && p.deviceToken) {
        stubs.push(p);
      } else {
        fullPlayers.push(p);
      }
    }

    // Attach deviceToken from any standalone stubs to their corresponding full player
    for (const stub of stubs) {
      const stubUUID = stub._docId.toUpperCase();
      const target = fullPlayers.find(p => 
        String(p.id).toUpperCase() === stubUUID || 
        getDeterministicUUID(p.id) === stubUUID
      );
      if (target && !target.deviceToken) {
        target.deviceToken = stub.deviceToken;
      }
    }

    onUpdate(fullPlayers);
  }, (error) => {
    console.warn("Firestore players listener warning:", error);
  });
}

// Real-time listener for games collection
export function subscribeToGames(onUpdate) {
  return onSnapshot(collection(db, "games"), (snapshot) => {
    const games = [];
    snapshot.forEach((doc) => {
      games.push({ id: doc.id, ...doc.data() });
    });
    onUpdate(games);
  }, (error) => {
    console.warn("Firestore games listener warning:", error);
  });
}

// Real-time listener for availabilitySlots collection
export function subscribeToSlots(onUpdate) {
  return onSnapshot(collection(db, "availabilitySlots"), (snapshot) => {
    const slots = [];
    snapshot.forEach((doc) => {
      slots.push({ id: doc.id, ...doc.data() });
    });
    onUpdate(slots);
  }, (error) => {
    console.warn("Firestore slots listener warning:", error);
  });
}
