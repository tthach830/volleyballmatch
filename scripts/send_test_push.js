#!/usr/bin/env node
const http2 = require("http2");
const crypto = require("crypto");
const fs = require("fs");
const path = require("path");
const https = require("https");

const keyPath = path.join(__dirname, "..", "functions", "keys", "AuthKey_C84ZV9L33Y.p8");
if (!fs.existsSync(keyPath)) {
  console.error("❌ Key file not found at:", keyPath);
  process.exit(1);
}
const privateKey = fs.readFileSync(keyPath, "utf8");

const keyId = "C84ZV9L33Y";
const teamId = "Z4WJ2G9N79";
const bundleId = "com.peterthach.SetGames";

function base64url(str) {
  return Buffer.from(str)
    .toString("base64")
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
}

function makeJwt() {
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

async function sendPush(deviceToken, title, body) {
  const host = "api.sandbox.push.apple.com";
  const jwt = makeJwt();
  const payload = JSON.stringify({
    aps: {
      alert: { title, body },
      sound: "default",
      badge: 1
    }
  });

  return new Promise((resolve) => {
    const client = http2.connect(`https://${host}:443`, { rejectUnauthorized: false });
    client.on("error", (err) => {
      console.error(`APNs Connection Error: ${err.message}`);
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

    let resp = "";
    req.on("response", (headers) => {
      const status = headers[http2.constants.HTTP2_HEADER_STATUS];
      if (status === 200) {
        console.log(`\n🎉 SUCCESS! Apple APNs delivered the notification to your iPhone! (HTTP 200)`);
      } else {
        console.log(`APNs Status: ${status}`);
      }
    });

    req.on("data", chunk => resp += chunk);
    req.on("end", () => {
      if (resp) console.log(`APNs Body: ${resp}`);
      client.close();
      resolve(true);
    });
    req.on("error", (err) => {
      console.error(`Request Error: ${err.message}`);
      client.close();
      resolve(false);
    });

    req.write(payload);
    req.end();
  });
}

async function main() {
  const targetToken = process.argv[2];
  const title = process.argv[3] || "🏐 SetGames Alert";
  const body = process.argv[4] || "Hello! Remote background notifications are working on your iPhone!";

  if (targetToken) {
    console.log(`Sending push to token: ${targetToken.substring(0, 10)}...`);
    await sendPush(targetToken, title, body);
    return;
  }

  console.log("Fetching registered players from Firestore...");
  const url = "https://firestore.googleapis.com/v1/projects/volleyballmatch-13d66/databases/(default)/documents/players?key=AIzaSyDZZo-WxBBrfU-ctKyWDM0MP-ErTDt1QBg";
  
  https.get(url, { rejectUnauthorized: false }, (res) => {
    let data = "";
    res.on("data", chunk => data += chunk);
    res.on("end", async () => {
      try {
        const json = JSON.parse(data);
        const docs = json.documents || [];
        const playersWithTokens = docs.filter(d => d.fields && d.fields.deviceToken);

        if (playersWithTokens.length === 0) {
          console.log("⚠️ No player device tokens found in Firestore yet.");
          return;
        }

        console.log(`Found ${playersWithTokens.length} player(s) with registered tokens:`);
        for (const p of playersWithTokens) {
          const name = p.fields.name?.stringValue || "Unknown";
          const token = p.fields.deviceToken?.stringValue;
          console.log(`\n📲 Sending live test push to ${name}...`);
          await sendPush(token, title, body);
        }
      } catch (err) {
        console.error("Error parsing response:", err.message);
      }
    });
  }).on("error", err => console.error("Fetch failed:", err.message));
}

main();
