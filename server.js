const http = require("http");
const http2 = require("http2");
const https = require("https");
const crypto = require("crypto");
const fs = require("fs");
const path = require("path");

const PORT = parseInt(process.argv[2] || process.env.PORT || "8080", 10);
const WEB_DIR = path.join(__dirname, "web");

// APNs Configuration
const keyPath = path.join(__dirname, "functions", "keys", "AuthKey_C84ZV9L33Y.p8");
let privateKey = null;
if (fs.existsSync(keyPath)) {
  privateKey = fs.readFileSync(keyPath, "utf8");
  console.log("🔑 APNs Private Key loaded successfully from:", keyPath);
} else {
  console.warn("⚠️ Warning: APNs key file not found at:", keyPath);
}

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

let cachedJwt = null;
let cachedJwtTime = 0;

function getJwt() {
  const now = Math.floor(Date.now() / 1000);
  if (cachedJwt && now - cachedJwtTime < 3000) {
    return cachedJwt;
  }
  if (!privateKey) throw new Error("Private key not loaded");

  const header = base64url(JSON.stringify({ alg: "ES256", kid: keyId }));
  const payload = base64url(JSON.stringify({ iss: teamId, iat: now }));
  const sign = crypto.createSign("sha256");
  sign.update(`${header}.${payload}`);
  const signature = sign.sign({ key: privateKey, dsaEncoding: "ieee-p1363" }, "base64")
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");

  cachedJwt = `${header}.${payload}.${signature}`;
  cachedJwtTime = now;
  return cachedJwt;
}

const pushedTokensRecently = new Map(); // Deduplication cache

function sendApnsPush(deviceToken, title, body, gameId = null, useSandbox = true) {
  return new Promise((resolve) => {
    const host = useSandbox ? "api.sandbox.push.apple.com" : "api.push.apple.com";
    let jwt;
    try {
      jwt = getJwt();
    } catch (e) {
      console.error("JWT Error:", e.message);
      return resolve({ success: false, error: e.message });
    }

    const payload = JSON.stringify({
      aps: {
        alert: { title, body },
        sound: "default",
        badge: 1
      },
      ...(gameId ? { gameId } : {})
    });

    const client = http2.connect(`https://${host}:443`, { rejectUnauthorized: false });
    client.on("error", (err) => {
      console.error(`APNs client error for (${deviceToken.slice(0, 8)}...):`, err.message);
      resolve({ success: false, error: err.message });
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
        console.log(`✅ [APNs] Push successfully delivered to ${deviceToken.slice(0, 8)}... via ${host}!`);
      } else if (status === 400 && useSandbox) {
        console.log(`ℹ️ [APNs] Sandbox returned 400. Retrying production gateway...`);
        client.close();
        return resolve(sendApnsPush(deviceToken, title, body, gameId, false));
      } else {
        console.warn(`⚠️ [APNs] Returned status ${status} from ${host}`);
      }
    });

    req.on("data", chunk => resp += chunk);
    req.on("end", () => {
      client.close();
      resolve({ success: true, response: resp });
    });
    req.on("error", (err) => {
      client.close();
      resolve({ success: false, error: err.message });
    });

    req.write(payload);
    req.end();
  });
}

const MIME_TYPES = {
  ".html": "text/html",
  ".css": "text/css",
  ".js": "application/javascript",
  ".json": "application/json",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".gif": "image/gif",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon",
  ".woff": "font/woff",
  ".woff2": "font/woff2",
  ".ttf": "font/ttf"
};

const server = http.createServer((req, res) => {
  // Enable CORS
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    res.writeHead(204);
    return res.end();
  }

  const parsedUrl = new URL(req.url, `http://${req.headers.host}`);
  const pathname = parsedUrl.pathname;

  // API: Send Push
  if (req.method === "POST" && pathname === "/api/send-push") {
    let bodyData = "";
    req.on("data", chunk => bodyData += chunk);
    req.on("end", async () => {
      try {
        const body = JSON.parse(bodyData || "{}");
        const rawTokens = Array.isArray(body.tokens) ? body.tokens : (body.token ? [body.token] : []);
        // Strictly deduplicate device tokens
        const tokens = Array.from(new Set(rawTokens.map(t => typeof t === "string" ? t.trim() : "").filter(Boolean)));
        const title = body.title || "🏐 Volleyball Match Alert";
        const msg = body.body || "New match message received";
        const gameId = body.gameId || null;
        const messageId = body.messageId || null;

        if (messageId) {
          seenMsgIds.add(messageId);
        }

        if (tokens.length === 0) {
          res.writeHead(400, { "Content-Type": "application/json" });
          return res.end(JSON.stringify({ error: "No tokens provided" }));
        }

        const now = Date.now();
        const tokensToSend = [];
        for (const t of tokens) {
          const pushKey = `${t}:::${title}:::${msg}`;
          const lastPushed = pushedTokensRecently.get(pushKey) || 0;
          if (now - lastPushed > 15000) {
            pushedTokensRecently.set(pushKey, now);
            tokensToSend.push(t);
          } else {
            console.log(`ℹ️ [API] Debouncing duplicate push for token ${t.slice(0, 8)}...`);
          }
        }

        if (tokensToSend.length === 0) {
          res.writeHead(200, { "Content-Type": "application/json" });
          return res.end(JSON.stringify({ success: true, count: 0, debounced: true }));
        }

        console.log(`\n📲 [API] Sending push to ${tokensToSend.length} device(s): "${title}" - "${msg}"`);
        const results = await Promise.all(tokensToSend.map(t => sendApnsPush(t, title, msg, gameId)));

        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ success: true, count: tokensToSend.length, results }));
      } catch (err) {
        console.error("API error:", err);
        res.writeHead(500, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ error: err.message }));
      }
    });
    return;
  }

  // API: Health / Status
  if (pathname === "/api/health") {
    res.writeHead(200, { "Content-Type": "application/json" });
    return res.end(JSON.stringify({ status: "ok", apnsLoaded: !!privateKey }));
  }

  // Static File Serving
  let relativePath = pathname;
  if (relativePath === "/" || relativePath === "") {
    relativePath = "/index.html";
  }

  let filePath = path.join(WEB_DIR, relativePath);

  // Security: prevent directory traversal
  if (!filePath.startsWith(WEB_DIR)) {
    res.writeHead(403);
    return res.end("Forbidden");
  }

  fs.stat(filePath, (err, stats) => {
    if (err || !stats.isFile()) {
      // SPA Fallback: serve index.html
      filePath = path.join(WEB_DIR, "index.html");
    }

    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || "application/octet-stream";

    fs.readFile(filePath, (readErr, content) => {
      if (readErr) {
        res.writeHead(500);
        return res.end("Server Error");
      }
      res.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
      res.writeHead(200, { "Content-Type": contentType });
      res.end(content);
    });
  });
});

// =======================================================
// Automatic Firestore Real-Time Watcher ($0 Serverless Push)
// Ensures any message added to Firestore sends an APNs push
// =======================================================
const FIRESTORE_API_KEY = "AIzaSyDZZo-WxBBrfU-ctKyWDM0MP-ErTDt1QBg";
const FIRESTORE_PROJECT = "volleyballmatch-13d66";
const seenMsgIds = new Set();
let isInitialWatcherRun = true;

function fetchJson(url) {
  return new Promise((resolve, reject) => {
    https.get(url, { rejectUnauthorized: false }, res => {
      let d = "";
      res.on("data", c => d += c);
      res.on("end", () => {
        try { resolve(JSON.parse(d)); } catch (e) { reject(e); }
      });
    }).on("error", reject);
  });
}

async function getPlayerTokens() {
  try {
    const url = `https://firestore.googleapis.com/v1/projects/${FIRESTORE_PROJECT}/databases/(default)/documents/players?key=${FIRESTORE_API_KEY}`;
    const data = await fetchJson(url);
    const tokenMap = {};
    (data.documents || []).forEach(doc => {
      const pid = doc.name.split("/").pop();
      const token = doc.fields?.deviceToken?.stringValue;
      if (token && token.trim()) {
        tokenMap[pid] = token.trim();
      }
    });
    return tokenMap;
  } catch (err) {
    return {};
  }
}

async function checkFirestoreNewMessages() {
  try {
    const url = `https://firestore.googleapis.com/v1/projects/${FIRESTORE_PROJECT}/databases/(default)/documents/games?key=${FIRESTORE_API_KEY}`;
    const data = await fetchJson(url);
    const games = data.documents || [];

    for (const doc of games) {
      const gameId = doc.name.split("/").pop();
      const title = doc.fields?.title?.stringValue || "Match";
      const msgs = doc.fields?.messages?.arrayValue?.values || [];
      const team1 = (doc.fields?.team1PlayerIds?.arrayValue?.values || []).map(v => v.stringValue);
      const team2 = (doc.fields?.team2PlayerIds?.arrayValue?.values || []).map(v => v.stringValue);
      const waitlist = (doc.fields?.waitlistPlayerIds?.arrayValue?.values || []).map(v => v.stringValue);
      const host = doc.fields?.hostPlayerId?.stringValue;
      const allParticipants = Array.from(new Set([...team1, ...team2, ...waitlist, ...(host ? [host] : [])]));

      for (const m of msgs) {
        const fields = m.mapValue?.fields || {};
        const msgId = fields.id?.stringValue;
        const origin = fields.origin?.stringValue;
        const senderId = fields.senderId?.stringValue;
        const senderName = fields.senderName?.stringValue || "Player";
        const text = fields.text?.stringValue || "";
        if (!msgId) continue;

        if (isInitialWatcherRun) {
          seenMsgIds.add(msgId);
          continue;
        }

        // Messages created on iOS already had direct APNs pushes dispatched by the iOS client.
        if (origin === "ios") {
          seenMsgIds.add(msgId);
          continue;
        }

        if (!seenMsgIds.has(msgId)) {
          seenMsgIds.add(msgId);
          console.log(`\n🔔 [Watcher] New match message: "${text}" by ${senderName} in "${title}"`);
          
          const tokenMap = await getPlayerTokens();
          // Exclude the sender from receiving a remote push for their own message
          const targetParticipantIds = allParticipants.filter(pid => pid !== senderId);
          const targetTokens = Array.from(new Set(targetParticipantIds.map(pid => tokenMap[pid]).filter(t => t && typeof t === "string" && t.trim().length > 0)));

          for (const token of targetTokens) {
            const pushKey = `${token}:::🏐 Volleyball Match Alert:::${senderName} (${title}): "${text}"`;
            const now = Date.now();
            const lastPushed = pushedTokensRecently.get(pushKey) || 0;
            if (now - lastPushed > 15000) {
              pushedTokensRecently.set(pushKey, now);
              console.log(`📲 [Watcher] Dispatching APNs push to token (${token.slice(0, 8)}...)`);
              sendApnsPush(token, "🏐 Volleyball Match Alert", `${senderName} (${title}): "${text}"`, gameId);
            } else {
              console.log(`ℹ️ [Watcher] Skipping duplicate push for (${token.slice(0, 8)}...) within 15s`);
            }
          }
        }
      }
    }
    isInitialWatcherRun = false;
    
    // Prune stale cache entries
    if (pushedTokensRecently.size > 200) {
      const now = Date.now();
      for (const [k, timestamp] of pushedTokensRecently.entries()) {
        if (now - timestamp > 60000) {
          pushedTokensRecently.delete(k);
        }
      }
    }
  } catch (err) {
    // Ignore polling blips
  }
}

server.on("error", (err) => {
  if (err.code === "EADDRINUSE") {
    console.error(`\n⚠️  Port ${PORT} is already in use by another process.`);
    console.error(`   To free port ${PORT}, run:`);
    console.error(`   kill -9 $(lsof -t -i :${PORT})\n`);
    console.error(`   Or specify a different port:`);
    console.error(`   node server.js ${PORT + 1}\n`);
    process.exit(1);
  } else {
    console.error("Server error:", err);
    process.exit(1);
  }
});

server.listen(PORT, () => {
  console.log(`\n======================================================`);
  console.log(`🚀 SetGames Web & APNs Push Server running on:`);
  console.log(`   👉 http://localhost:${PORT}`);
  console.log(`   👉 APNs Push Endpoint: http://localhost:${PORT}/api/send-push`);
  console.log(`   👉 Active Firestore Message Watcher: ENABLED`);
  console.log(`======================================================\n`);
  
  // Start Firestore watcher polling every 1.5s
  setInterval(checkFirestoreNewMessages, 1500);
  setTimeout(checkFirestoreNewMessages, 500);
});
