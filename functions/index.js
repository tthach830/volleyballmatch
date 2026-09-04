const functions = require("firebase-functions");
const admin = require("firebase-admin");
const path = require("path");
const fs = require("fs");
const apn = require("@parse/node-apn");

admin.initializeApp();
const db = admin.firestore();

// APNs Provider configuration (direct to Apple APNs)
let apnProvider = null;
const keyPath = path.join(__dirname, "keys", "AuthKey_C84ZV9L33Y.p8");
if (fs.existsSync(keyPath)) {
  try {
    apnProvider = new apn.Provider({
      token: {
        key: keyPath,
        keyId: "C84ZV9L33Y",
        teamId: "N3DW2PW8GA"
      },
      production: false // Set to true when distributed on App Store / TestFlight
    });
    console.log("✅ Direct APNs Provider initialized with Key C84ZV9L33Y");
  } catch (err) {
    console.warn("⚠️ Failed to initialize APNs provider:", err.message);
  }
}

/**
 * Helper to deliver a push notification to a recipient's device token.
 * Supports both native 64-char APNs device tokens and FCM registration tokens.
 */
async function deliverPushNotification(deviceToken, { title, body, data = {} }) {
  if (!deviceToken) return;

  const isRawApnsToken = /^[0-9a-fA-F]{64}$/.test(deviceToken);

  // 1. Direct APNs delivery for 64-character iOS device tokens
  if (isRawApnsToken && apnProvider) {
    const note = new apn.Notification();
    note.expiry = Math.floor(Date.now() / 1000) + 3600; // 1 hour
    note.badge = 1;
    note.sound = "default";
    note.alert = {
      title: title,
      body: body
    };
    note.topic = "com.peterthach.SetGames";
    note.payload = data;

    try {
      const result = await apnProvider.send(note, deviceToken);
      if (result.failed && result.failed.length > 0) {
        console.error("APNs delivery error:", result.failed);
      } else {
        console.log(`✅ Direct APNs delivered to token ${deviceToken.substring(0, 10)}...`);
      }
      return result;
    } catch (err) {
      console.error("Direct APNs error:", err);
    }
  }

  // 2. Firebase Cloud Messaging delivery (for FCM tokens or Firebase-managed APNs)
  try {
    const fcmMessage = {
      token: deviceToken,
      notification: {
        title: title,
        body: body
      },
      data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
      apns: {
        headers: {
          "apns-priority": "10",
          "apns-push-type": "alert"
        },
        payload: {
          aps: {
            alert: {
              title: title,
              body: body
            },
            sound: "default",
            badge: 1,
            contentAvailable: true
          }
        }
      }
    };

    const response = await admin.messaging().send(fcmMessage);
    console.log(`✅ FCM delivered message: ${response}`);
    return response;
  } catch (err) {
    console.warn(`FCM send error for token ${deviceToken.substring(0, 10)}...:`, err.message);
  }
}

/**
 * Triggered whenever a game document in Firestore is updated.
 * Detects newly appended chat messages and sends push notifications to all other match participants.
 */
exports.onGameUpdated = functions.firestore
  .document("games/{gameId}")
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data() || {};
    const afterData = change.after.data() || {};

    const beforeMsgs = beforeData.messages || [];
    const afterMsgs = afterData.messages || [];

    // Check if new chat messages were posted
    if (afterMsgs.length > beforeMsgs.length) {
      const newMessages = afterMsgs.slice(beforeMsgs.length);
      const gameTitle = afterData.title || "Match";
      const gameId = context.params.gameId || afterData.id;

      // Collect all player IDs associated with this match
      const allPlayerIds = [
        ...(afterData.allPlayerIds || []),
        ...(afterData.waitlistPlayerIds || []),
        ...(afterData.team1PlayerIds || []),
        ...(afterData.team2PlayerIds || []),
        afterData.hostPlayerId
      ].filter(Boolean);

      const uniquePlayers = [...new Set(allPlayerIds)];

      for (const msg of newMessages) {
        // Exclude the sender
        const recipientIds = uniquePlayers.filter(id => id !== msg.senderId);
        if (recipientIds.length === 0) continue;

        const title = `💬 ${msg.senderName} (${gameTitle})`;
        const body = msg.text;

        console.log(`Delivering chat notification to ${recipientIds.length} players for game: ${gameTitle}`);

        for (const playerId of recipientIds) {
          try {
            const playerSnap = await db.collection("players").doc(playerId).get();
            if (playerSnap.exists) {
              const playerData = playerSnap.data();
              const token = playerData.deviceToken;
              if (token) {
                await deliverPushNotification(token, {
                  title,
                  body,
                  data: {
                    gameId: gameId,
                    type: "matchChat",
                    senderId: msg.senderId
                  }
                });
              }
            }
          } catch (err) {
            console.error(`Error querying player ${playerId}:`, err);
          }
        }
      }
    }
  });

/**
 * HTTP endpoint to manually test sending a remote push notification to any registered player.
 * Usage: curl "https://<region>-<project>.cloudfunctions.net/sendTestPush?playerId=..."
 */
exports.sendTestPush = functions.https.onRequest(async (req, res) => {
  const playerId = req.query.playerId || req.body.playerId;
  if (!playerId) {
    return res.status(400).json({ error: "Missing playerId query param or body" });
  }

  const playerSnap = await db.collection("players").doc(playerId).get();
  if (!playerSnap.exists) {
    return res.status(404).json({ error: "Player not found" });
  }

  const token = playerSnap.data().deviceToken;
  if (!token) {
    return res.status(400).json({ error: "Player does not have a deviceToken registered yet." });
  }

  try {
    await deliverPushNotification(token, {
      title: "🏐 SetGames Test Alert",
      body: `Hey ${playerSnap.data().name || "Player"}, remote push notifications are working perfectly!`,
      data: { type: "testAlert" }
    });
    return res.json({ success: true, message: `Push sent to ${playerSnap.data().name}` });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});
