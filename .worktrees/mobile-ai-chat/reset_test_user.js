/**
 * Resets test user password and creates additional test accounts.
 * Run: node reset_test_user.js
 */
const https = require('https');
const fs    = require('fs');
const crypto = require('crypto');

const SA = JSON.parse(fs.readFileSync('C:/Users/USER/Downloads/campuscore-5658f-firebase-adminsdk-fbsvc-6d41edcb0d.json'));
const WEB_API_KEY = 'AIzaSyDCse7FB79lRhQFH7EOxlaY9P3UWBN_gdo';

// ── Helper: make HTTPS request ────────────────────────────────────────────────
function httpsPost(hostname, path, data, headers = {}) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify(data);
    const req = https.request({
      hostname, path, method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body), ...headers }
    }, res => {
      let b = '';
      res.on('data', d => b += d);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, body: JSON.parse(b) }); }
        catch { resolve({ status: res.statusCode, body: b }); }
      });
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

// ── Helper: get Google access token via JWT ───────────────────────────────────
async function getAccessToken() {
  const now = Math.floor(Date.now() / 1000);
  const header  = Buffer.from(JSON.stringify({ alg: 'RS256', typ: 'JWT' })).toString('base64url');
  const payload = Buffer.from(JSON.stringify({
    iss: SA.client_email,
    sub: SA.client_email,
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
    scope: 'https://www.googleapis.com/auth/firebase https://www.googleapis.com/auth/cloud-platform'
  })).toString('base64url');

  const sign    = crypto.createSign('RSA-SHA256');
  sign.update(`${header}.${payload}`);
  const sig = sign.sign(SA.private_key, 'base64url');
  const jwt = `${header}.${payload}.${sig}`;

  const res = await httpsPost('oauth2.googleapis.com', '/token', {
    grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
    assertion: jwt
  }, { 'Content-Type': 'application/x-www-form-urlencoded' });

  // Actually needs form-encoded, let's do it properly
  return new Promise((resolve, reject) => {
    const body = `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`;
    const req = https.request({
      hostname: 'oauth2.googleapis.com',
      path: '/token',
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'Content-Length': Buffer.byteLength(body) }
    }, res => {
      let b = '';
      res.on('data', d => b += d);
      res.on('end', () => {
        const parsed = JSON.parse(b);
        if (parsed.access_token) resolve(parsed.access_token);
        else reject(new Error('No access token: ' + b));
      });
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

// ── Update user via Identity Platform REST API ────────────────────────────────
async function updateUser(accessToken, localId, password) {
  return httpsPost(
    'identitytoolkit.googleapis.com',
    '/v1/projects/campuscore-5658f/accounts:update',
    { localId, password, emailVerified: true },
    { Authorization: `Bearer ${accessToken}` }
  );
}

// ── Main ──────────────────────────────────────────────────────────────────────
async function main() {
  console.log('Getting access token...');
  const token = await getAccessToken();
  console.log('Got access token.');

  // Reset test@campuscore.ng password
  console.log('\nResetting test@campuscore.ng password...');
  const r1 = await updateUser(token, 'E3a6FA2iKlUlmyMd7kJxv79dLUZ2', 'CampusCore2024!');
  if (r1.status === 200) {
    console.log('✅ test@campuscore.ng password set to: CampusCore2024!');
  } else {
    console.error('❌ Failed:', JSON.stringify(r1.body));
  }
}

main().catch(console.error);
