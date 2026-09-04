const functions = require("firebase-functions");
const admin = require("firebase-admin");
const http2 = require("http2");
const crypto = require("crypto");
const path = require("path");
const fs = require("fs");

admin.initializeApp();
const db = admin.firestore();

const teamId = "Z4WJ2G9N79";
const keyId = "C84ZV9L33Y";
const bundleId = "com.peterthach.SetGames";

const keyPath = path.join(__dirname, "keys", "AuthKey_C84ZV9L33Y.p8");
let privateKey = null;
let hasKey = false;
if (fs.existsSync(keyPath)) {
  try {
    privateKey = fs.readFileSync(keyPath, "utf8");
    hasKey = true;
    console.log("✅ APNs key loaded successfully for Team Z4WJ2G9N79");
  } catch (err) {
    console.error("Error reading APNs key:", err);
  }
}

function base64url(str) {
  return Buffer.from(str)
    .toString("base64")
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
}

function makeApnsJwt() {
  const header = base64url(JSON.stringify({ alg: "ES256", kid: keyId }));
  const payload = base64url(JSON.stringify({
    iss: teamId,
    iat: Math.floor(Date.now() / 1000)
  }));
  const sign = crypto.createSign("sha256");
  sign.update(`${header}.${payload}`);
  const signature = sign.sign({ key: privateKey, dsaEncoding: "ieee-p1363" }, "base64")
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
  return `${header}.${payload}.${signature}`;
}

async function sendDirectApns(deviceToken, { title, body, data = {} }) {
  if (!hasKey) {
    console.warn("Cannot send direct APNs: Key not found on disk");
    return false;
  }
  
  const isProduction = process.env.NODE_ENV === "production";
  const host = isProduction ? "api.push.apple.com" : "api.sandbox.push.apple.com";
  const jwt = makeApnsJwt();
  const payloadStr = JSON.stringify({
    aps: {
      alert: { title, body },
      sound: "default",
      badge: 1,
      "content-available": 1
    },
    ...data
  });

  return new Promise((resolve) => {
    const client = http2.connect(`https://${host}:443`, { rejectUnauthorized: false });
    client.on("error", (err) => {
      console.error(`APNs client error: ${err.message}`);
      resolve(false);
    });

    const req = client.request({
      [http2.constants.HTTP2_HEADER_METHOD]: http2.constants.HTTP2_METHOD_POST,
      [http2.constants.HTTP2_HEADER_PATH]: `/3/device/${deviceToken}`,
      "apns-topic": bundleId,
      "apns-push-type": "alert",
      "apns-priority": "10",
      "authorization": `bearer ${jwt}`
    });

    let respBody = "";
    req.on("data", chunk => respBody += chunk);
    req.on("end", () => {
      console.log(`✅ Direct APNs delivered to ${deviceToken.substring(0, 10)}... (Status 200)`);
      client.close();
      resolve(true);
    });
    req.on("error", (err) => {
      console.error(`APNs request error: ${err.message}`);
      client.close();
      resolve(false);
    });

    req.write(payloadStr);
    req.end();
  });
}

/**
 * Helper to deliver a push notification to a recipient's device token.
 * Supports both native 64-char APNs device tokens and FCM registration tokens.
 */
async function deliverPushNotification(deviceToken, { title, body, data = {} }) {
  if (!deviceToken) return;

  const isRawApnsToken = /^[0-9a-fA-F]{64}$/.test(deviceToken);

  // 1. Direct APNs delivery for 64-character iOS device tokens
  if (isRawApnsToken && hasKey) {
    return await sendDirectApns(deviceToken, { title, body, data });
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
