import { initializeApp } from "https://www.gstatic.com/firebasejs/11.4.0/firebase-app.js";
import { 
  getFirestore, 
  collection, 
  doc, 
  setDoc, 
  deleteDoc,
  onSnapshot 
} from "https://www.gstatic.com/firebasejs/11.4.0/firebase-firestore.js";

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

// Real-time listener for players collection
export function subscribeToPlayers(onUpdate) {
  return onSnapshot(collection(db, "players"), (snapshot) => {
    const players = [];
    snapshot.forEach((doc) => {
      players.push({ id: doc.id, ...doc.data() });
    });
    onUpdate(players);
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
