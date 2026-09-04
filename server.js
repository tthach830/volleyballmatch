const http = require("http");
const http2 = require("http2");
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
        const tokens = Array.isArray(body.tokens) ? body.tokens : (body.token ? [body.token] : []);
        const title = body.title || "🏐 SetGames Match";
        const msg = body.body || "New match message received";
        const gameId = body.gameId || null;

        if (tokens.length === 0) {
          res.writeHead(400, { "Content-Type": "application/json" });
          return res.end(JSON.stringify({ error: "No tokens provided" }));
        }

        console.log(`\n📲 Sending push to ${tokens.length} device(s): "${title}" - "${msg}"`);
        const results = await Promise.all(tokens.map(t => sendApnsPush(t, title, msg, gameId)));

        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ success: true, count: tokens.length, results }));
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
      res.writeHead(200, { "Content-Type": contentType });
      res.end(content);
    });
  });
});

server.listen(PORT, () => {
  console.log(`\n======================================================`);
  console.log(`🚀 SetGames Web & APNs Push Server running on:`);
  console.log(`   👉 http://localhost:${PORT}`);
  console.log(`   👉 APNs Push Endpoint: http://localhost:${PORT}/api/send-push`);
  console.log(`======================================================\n`);
});
