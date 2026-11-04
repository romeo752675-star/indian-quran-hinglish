import http from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createSyncEngine } from './sync_engine.mjs';
import { buildAyahPronunciationManifest } from './pronunciation_manifest.mjs';

const PORT = Number(process.env.PORT || 8787);
const HOST = process.env.HOST || '0.0.0.0';
const QF_ENV = (process.env.QF_ENV || 'production').toLowerCase();
const ENVIRONMENTS = {
  production: {
    api: 'https://apis.quran.foundation/content/api/v4',
    oauth: 'https://oauth2.quran.foundation/oauth2/token',
  },
  prelive: {
    api: 'https://apis-prelive.quran.foundation/content/api/v4',
    oauth: 'https://prelive-oauth2.quran.foundation/oauth2/token',
  },
};
const environment = ENVIRONMENTS[QF_ENV];
const CLIENT_ID = process.env.QF_CLIENT_ID;
const CLIENT_SECRET = process.env.QF_CLIENT_SECRET;
const SYNC_ADMIN_KEY = process.env.QF_SYNC_ADMIN_KEY;
const SYNC_RESOURCES = process.env.QF_SYNC_RESOURCES || '';
const DATA_DIR = process.env.QF_SYNC_DATA_DIR || path.join(path.dirname(fileURLToPath(import.meta.url)), 'data');
const REVIEWED_CONTENT_FILE = process.env.QF_REVIEWED_CONTENT_FILE || path.join(DATA_DIR, 'reviewed-ayah-content.json');
let cachedToken = null;
let tokenExpiresAt = 0;
let tokenRequest = null;

function send(res, status, payload) {
  res.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    'cache-control': 'no-store',
    'x-content-type-options': 'nosniff',
  });
  res.end(JSON.stringify(payload));
}

function credentialsConfigured() {
  return Boolean(environment && CLIENT_ID && CLIENT_SECRET);
}

async function getAccessToken(force = false) {
  if (!credentialsConfigured()) throw new Error('QF backend credentials or environment are not configured');
  if (!force && cachedToken && Date.now() < tokenExpiresAt - 60_000) return cachedToken;
  if (tokenRequest) return tokenRequest;

  tokenRequest = (async () => {
    const basic = Buffer.from(`${CLIENT_ID}:${CLIENT_SECRET}`).toString('base64');
    const response = await fetch(environment.oauth, {
      method: 'POST',
      headers: {
        authorization: `Basic ${basic}`,
        'content-type': 'application/x-www-form-urlencoded',
        accept: 'application/json',
      },
      body: new URLSearchParams({ grant_type: 'client_credentials', scope: 'content' }),
      signal: AbortSignal.timeout(15_000),
    });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok || !payload.access_token) {
      throw new Error(`QF OAuth token request failed (${response.status})`);
    }
    cachedToken = payload.access_token;
    tokenExpiresAt = Date.now() + (Number(payload.expires_in) || 3600) * 1000;
    return cachedToken;
  })();
  try {
    return await tokenRequest;
  } finally {
    tokenRequest = null;
  }
}

function allowedPath(pathname) {
  return pathname === '/resources/sync' ||
    /^\/resources\/snapshots\/(quran_core|mushafs|translations|word_by_word_translations|word_by_word_transliterations|tafsirs|recitations|chapter_recitations|articles)\/[0-9]+$/.test(pathname);
}

async function requestQuranFoundation(pathAndQuery, retry401 = true) {
  const url = new URL(pathAndQuery, environment.api);
  if (url.origin !== new URL(environment.api).origin || !url.pathname.startsWith('/content/api/v4/')) {
    throw new Error('Invalid upstream path');
  }
  const token = await getAccessToken();
  const response = await fetch(url, {
    headers: { 'x-auth-token': token, 'x-client-id': CLIENT_ID, accept: 'application/json' },
    signal: AbortSignal.timeout(30_000),
  });
  if (response.status === 401 && retry401) {
    cachedToken = null;
    tokenExpiresAt = 0;
    await getAccessToken(true);
    return requestQuranFoundation(pathAndQuery, false);
  }
  return response;
}

const syncEngine = SYNC_RESOURCES ? createSyncEngine({
  apiRequest: (apiPath) => requestQuranFoundation(apiPath),
  storeDir: DATA_DIR,
  resources: SYNC_RESOURCES,
}) : null;

const server = http.createServer(async (req, res) => {
  const requestUrl = new URL(req.url || '/', `http://${req.headers.host || 'localhost'}`);
  if (req.method === 'GET' && requestUrl.pathname === '/app/ayah-pronunciation') {
    try {
      const fs = await import('node:fs/promises');
      const corePath = path.join(DATA_DIR, 'resources', 'quran_core__1.json');
      const transliterationPath = path.join(DATA_DIR, 'resources', 'word_by_word_transliterations__60.json');
      const [coreRaw, transliterationRaw] = await Promise.all([
        fs.readFile(corePath, 'utf8'),
        fs.readFile(transliterationPath, 'utf8'),
      ]);
      const coreStored = JSON.parse(coreRaw);
      const transliterationStored = JSON.parse(transliterationRaw);
      const manifest = buildAyahPronunciationManifest(
        { records: Object.values(coreStored.records || {}) },
        { records: Object.values(transliterationStored.records || {}) },
      );
      return send(res, 200, manifest);
    } catch (error) {
      if (error.code === 'ENOENT') return send(res, 503, { error: 'pronunciation_resources_not_synced', message: 'Run Content Sync for quran_core:1 and word_by_word_transliterations:60 first.' });
      return send(res, 500, { error: 'pronunciation_manifest_unavailable', message: String(error?.message || 'Manifest unavailable') });
    }
  }

  if (req.method === 'GET' && requestUrl.pathname === '/app/ayah-content') {
    try {
      const raw = await import('node:fs/promises').then((fs) => fs.readFile(REVIEWED_CONTENT_FILE, 'utf8'));
      const payload = JSON.parse(raw);
      if (payload.schema_version !== 1 || !Array.isArray(payload.records) || payload.records.length > 6236) {
        return send(res, 500, { error: 'invalid_reviewed_content_manifest' });
      }
      // Never publish draft, pending, malformed, or duplicate Ayah records.
      const seen = new Set();
      const approved = payload.records.filter((row) => {
        if (!row || row.reviewer_status !== 'approved') return false;
        const surah = Number(row.surah_number);
        const ayah = Number(row.number_in_surah);
        const key = `${surah}:${ayah}`;
        const sourceUrl = (() => { try { return new URL(row.source_url); } catch { return null; } })();
        const valid = Number.isInteger(surah) && surah >= 1 && surah <= 114 &&
          Number.isInteger(ayah) && ayah >= 1 && sourceUrl?.protocol === 'https:' &&
          String(row.source_name || '').trim() && String(row.license || '').trim() &&
          String(row.transliteration || '').trim() && String(row.hinglish_translation || '').trim() &&
          String(row.tafsir || '').trim() && !seen.has(key);
        if (valid) seen.add(key);
        return Boolean(valid);
      });
      return send(res, 200, { schema_version: 1, records: approved });
    } catch (error) {
      if (error.code === 'ENOENT') return send(res, 200, { schema_version: 1, records: [] });
      return send(res, 500, { error: 'reviewed_content_unavailable' });
    }
  }

  if (req.method === 'GET' && requestUrl.pathname === '/health') {
    return send(res, 200, {
      ok: true,
      service: 'Indian Quran QF Content Sync gateway',
      environment: environment ? QF_ENV : 'invalid',
      credentialsConfigured: credentialsConfigured(),
      syncConfigured: Boolean(syncEngine && SYNC_ADMIN_KEY),
    });
  }

  if (req.method === 'POST' && requestUrl.pathname === '/sync/run') {
    if (!SYNC_ADMIN_KEY || req.headers.authorization !== `Bearer ${SYNC_ADMIN_KEY}`) {
      return send(res, 401, { error: 'unauthorized' });
    }
    if (!credentialsConfigured() || !syncEngine) {
      return send(res, 503, { error: 'sync_not_configured', message: 'Configure QF credentials and QF_SYNC_RESOURCES on the backend.' });
    }
    try {
      const result = await syncEngine.run();
      return send(res, 200, result);
    } catch (error) {
      return send(res, 502, { error: 'sync_failed', message: String(error?.message || 'Sync failed') });
    }
  }

  if (req.method !== 'GET' || !requestUrl.pathname.startsWith('/qf/')) {
    return send(res, 404, { error: 'not_found' });
  }
  if (!credentialsConfigured()) {
    return send(res, 503, { error: 'credentials_not_configured', message: 'Set QF_CLIENT_ID and QF_CLIENT_SECRET on the backend only.' });
  }

  const relativePath = requestUrl.pathname.slice('/qf'.length);
  if (!allowedPath(relativePath)) return send(res, 400, { error: 'route_not_allowed' });
  const upstreamPath = `/content/api/v4${relativePath}${requestUrl.search}`;

  try {
    const upstream = await requestQuranFoundation(upstreamPath);
    const body = await upstream.text();
    res.writeHead(upstream.status, {
      'content-type': upstream.headers.get('content-type') || 'application/json; charset=utf-8',
      'cache-control': 'no-store',
      'x-content-type-options': 'nosniff',
    });
    res.end(body);
  } catch (error) {
    // Do not return upstream URLs, credentials, or token material to clients.
    send(res, 502, { error: 'upstream_unavailable', message: String(error?.message || 'Request failed') });
  }
});

server.listen(PORT, HOST, () => {
  console.log(`QF Content Sync gateway listening on ${HOST}:${PORT} (${QF_ENV})`);
});
