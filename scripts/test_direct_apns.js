const http2 = require("http2");
const crypto = require("crypto");
const fs = require("fs");
const path = require("path");

const keyPath = path.join(__dirname, "..", "functions", "keys", "AuthKey_C84ZV9L33Y.p8");
const privateKey = fs.readFileSync(keyPath, "utf8");

const keyId = "C84ZV9L33Y";
const deviceToken = "ca8b24cd70f6eae34963c55392a16f7981891ddb8486efaaf43ba6c34811ed3f";
const bundleId = "com.peterthach.SetGames";

function base64url(str) {
  return Buffer.from(str)
    .toString("base64")
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
}

function makeJwt(teamId) {
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

async function trySend(teamId, isProduction = false) {
  const host = isProduction ? "api.push.apple.com" : "api.sandbox.push.apple.com";
  console.log(`\nTesting Team ID [${teamId}] against ${host}...`);
  
  const jwt = makeJwt(teamId);
  const body = JSON.stringify({
    aps: {
      alert: {
        title: "🏐 SetGames Alert",
        body: "Success! Remote push notification delivered directly to your iPhone!"
      },
      sound: "default",
      badge: 1
    }
  });

  return new Promise((resolve) => {
    const client = http2.connect(`https://${host}:443`, {
      rejectUnauthorized: false
    });

    client.on("error", (err) => {
      console.error(`Client Error: ${err.message}`);
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

    let respData = "";
    req.on("response", (headers) => {
      const status = headers[http2.constants.HTTP2_HEADER_STATUS];
      console.log(`APNs HTTP Status: ${status}`);
    });

    req.on("data", (chunk) => {
      respData += chunk;
    });

    req.on("end", () => {
      if (respData) {
        console.log(`APNs Response Body: ${respData}`);
      } else {
        console.log(`🎉 SUCCESS! Empty body with 200 OK means APNs accepted and pushed to your iPhone!`);
      }
      client.close();
      resolve(true);
    });

    req.write(body);
    req.end();
  });
}

async function run() {
  // Test both potential Team IDs
  console.log("Starting APNs direct test...");
  await trySend("Z4WJ2G9N79", false);
  await trySend("N3DW2PW8GA", false);
}

run();
