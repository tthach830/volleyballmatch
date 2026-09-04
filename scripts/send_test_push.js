#!/usr/bin/env node
const path = require("path");
const fs = require("fs");
const apn = require(path.join(__dirname, "..", "functions", "node_modules", "@parse", "node-apn"));

const keyPath = path.join(__dirname, "..", "functions", "keys", "AuthKey_C84ZV9L33Y.p8");

if (!fs.existsSync(keyPath)) {
  console.error("❌ Key file not found at:", keyPath);
  process.exit(1);
}

const keyId = "C84ZV9L33Y";
const teamId = "N3DW2PW8GA";
const bundleId = "com.peterthach.SetGames";

// Check if device token provided via CLI argument
const targetToken = process.argv[2];

if (!targetToken) {
  console.log("Usage: node scripts/send_test_push.js <64-char-device-token> [title] [body]");
  console.log("Fetching registered players with device tokens from Firestore...");
  
  const https = require("https");
  const url = "https://firestore.googleapis.com/v1/projects/volleyballmatch-13d66/databases/(default)/documents/players?key=AIzaSyDZZo-WxBBrfU-ctKyWDM0MP-ErTDt1QBg";
  
  https.get(url, { rejectUnauthorized: false }, (res) => {
    let data = "";
    res.on("data", chunk => data += chunk);
    res.on("end", () => {
      try {
        const json = JSON.parse(data);
        const docs = json.documents || [];
        const playersWithTokens = docs.filter(d => d.fields && d.fields.deviceToken);
        
        if (playersWithTokens.length === 0) {
          console.log("\n⚠️ No players have registered a deviceToken in Firestore yet.");
          console.log("👉 Open the SetGames app on your iPhone once to register your device token!");
        } else {
          console.log(`\nFound ${playersWithTokens.length} player(s) with registered device tokens:`);
          playersWithTokens.forEach(p => {
            const name = p.fields.name?.stringValue || "Unknown";
            const token = p.fields.deviceToken?.stringValue;
            console.log(` - ${name}: ${token}`);
          });
          console.log("\nTo send a test push, run:");
          console.log(`node scripts/send_test_push.js "${playersWithTokens[0].fields.deviceToken.stringValue}"`);
        }
      } catch (err) {
        console.error("Error parsing players:", err.message);
      }
    });
  }).on("error", err => console.error("Request failed:", err.message));
  
  return;
}

const title = process.argv[3] || "🏐 SetGames Remote Push";
const body = process.argv[4] || "Remote background notifications are working on your iPhone!";

console.log(`Connecting to Apple APNs (Sandbox)...`);
const apnProvider = new apn.Provider({
  token: {
    key: keyPath,
    keyId: keyId,
    teamId: teamId
  },
  production: false
});

const note = new apn.Notification();
note.expiry = Math.floor(Date.now() / 1000) + 3600;
note.badge = 1;
note.sound = "default";
note.alert = {
  title: title,
  body: body
};
note.topic = bundleId;
note.payload = { test: true, timestamp: Date.now() };

console.log(`Sending to token: ${targetToken}...`);
apnProvider.send(note, targetToken).then(result => {
  if (result.sent.length > 0) {
    console.log("🎉 SUCCESS! Push notification delivered to Apple APNs.");
    console.log("Your iPhone should ring and display the banner now!");
  }
  if (result.failed.length > 0) {
    console.error("⚠️ APNs delivery failed:", result.failed);
  }
  apnProvider.shutdown();
}).catch(err => {
  console.error("Fatal APNs Error:", err);
  apnProvider.shutdown();
});
