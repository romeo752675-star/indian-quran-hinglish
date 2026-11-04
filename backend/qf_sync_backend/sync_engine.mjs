import fs from 'node:fs/promises';
import path from 'node:path';

const VALID_GROUPS = new Set([
  'quran_core', 'mushafs', 'translations', 'word_by_word_translations',
  'word_by_word_transliterations', 'tafsirs', 'recitations',
  'chapter_recitations', 'articles',
]);

function safeResourceName(group, id) {
  if (!VALID_GROUPS.has(group) || !/^\d+$/.test(String(id))) throw new Error('Invalid resource identity');
  return `${group}__${id}`;
}

function recordKey(record) {
  if (record.record_key !== undefined && record.record_key !== null) return String(record.record_key);
  if (record.id !== undefined && record.id !== null) return String(record.id);
  throw new Error(`Sync record ${record.record_type || 'unknown'} has no record_key or id`);
}

export function parseResourceFilter(value) {
  const entries = String(value || '').split(';').map((part) => part.trim()).filter(Boolean);
  if (!entries.length) throw new Error('QF_SYNC_RESOURCES must list at least one approved resource');
  for (const entry of entries) {
    const match = /^([a-z_]+):(\d+)$/.exec(entry);
    if (!match || !VALID_GROUPS.has(match[1])) throw new Error(`Invalid sync resource: ${entry}`);
  }
  return entries;
}

export function createSyncEngine({ apiRequest, storeDir, resources }) {
  if (typeof apiRequest !== 'function') throw new Error('apiRequest is required');
  if (!storeDir) throw new Error('storeDir is required');
  const resourceFilter = parseResourceFilter(resources);
  const statePath = path.join(storeDir, 'sync-state.json');
  const recordsDir = path.join(storeDir, 'resources');
  let activeRun = null;

  async function readJson(file, fallback) {
    try { return JSON.parse(await fs.readFile(file, 'utf8')); }
    catch (error) { if (error.code === 'ENOENT') return fallback; throw error; }
  }
  async function atomicJson(file, value) {
    await fs.mkdir(path.dirname(file), { recursive: true });
    const temp = `${file}.${process.pid}.${Date.now()}.tmp`;
    await fs.writeFile(temp, JSON.stringify(value), 'utf8');
    await fs.rename(temp, file);
  }
  function normalizeApiPath(value) {
    if (typeof value !== 'string' || !value) throw new Error('Content Sync returned an invalid relative URL');
    if (value.startsWith('/api/v4/')) return `/content${value}`;
    if (value.startsWith('/content/api/v4/')) return value;
    throw new Error('Content Sync returned a URL outside the documented API path');
  }
  async function fetchAllPages(firstPath) {
    const pages = [];
    let next = normalizeApiPath(firstPath);
    while (next) {
      const response = await apiRequest(next);
      if (!response.ok) throw new Error(`Content Sync request failed (${response.status})`);
      const page = await response.json();
      pages.push(page);
      next = page.has_more ? normalizeApiPath(page.next_page_url) : null;
      if (page.has_more && !next) throw new Error('Sync response says has_more but has no next_page_url');
      if (pages.length > 10000) throw new Error('Content Sync pagination safety limit exceeded');
    }
    return pages;
  }
  async function snapshot(group, id, snapshotUrl) {
    const response = await apiRequest(snapshotUrl ? normalizeApiPath(snapshotUrl) : `/content/api/v4/resources/snapshots/${group}/${id}`);
    if (!response.ok) throw new Error(`Snapshot fetch failed for ${group}:${id} (${response.status})`);
    const payload = await response.json();
    if (!Array.isArray(payload.records)) throw new Error(`Snapshot for ${group}:${id} has no records array`);
    const rows = {};
    for (const row of payload.records) {
      const key = row.record_type ? `${row.record_type}:${recordKey(row)}` : recordKey(row);
      rows[key] = row;
    }
    await atomicJson(path.join(recordsDir, `${safeResourceName(group, id)}.json`), {
      resource_group: group, resource_id: Number(id), records: rows,
      record_count: payload.records.length, synced_at: new Date().toISOString(),
    });
    return payload.records.length;
  }
  async function applyMutation(change) {
    const group = change.resource_group;
    const id = change.resource_id;
    const file = path.join(recordsDir, `${safeResourceName(group, id)}.json`);
    const current = await readJson(file, { resource_group: group, resource_id: Number(id), records: {}, record_count: 0 });
    switch (change.type) {
      case 'RESOURCE_CREATE':
      case 'RESOURCE_INVALIDATE':
        if (!change.snapshot_url) throw new Error(`${change.type} missing snapshot_url`);
        return snapshot(group, id, change.snapshot_url);
      case 'RESOURCE_DELETE':
        await fs.rm(file, { force: true });
        return 0;
      case 'RESOURCE_UPDATE':
        current.synced_at = new Date().toISOString();
        await atomicJson(file, current);
        return Object.keys(current.records).length;
      case 'ROW_CREATE':
      case 'ROW_UPDATE': {
        if (!change.data || typeof change.data !== 'object') throw new Error(`${change.type} missing data`);
        const key = `${change.record_type || change.data.record_type || 'row'}:${String(change.record_key ?? recordKey(change.data))}`;
        current.records[key] = change.data;
        current.record_count = Object.keys(current.records).length;
        current.synced_at = new Date().toISOString();
        await atomicJson(file, current);
        return current.record_count;
      }
      case 'ROW_DELETE': {
        const key = `${change.record_type || 'row'}:${String(change.record_key)}`;
        delete current.records[key];
        current.record_count = Object.keys(current.records).length;
        current.synced_at = new Date().toISOString();
        await atomicJson(file, current);
        return current.record_count;
      }
      default:
        throw new Error(`Unsupported Content Sync mutation type: ${change.type}`);
    }
  }

  async function runInternal() {
    await fs.mkdir(recordsDir, { recursive: true });
    const previous = await readJson(statePath, {});
    const filterKey = resourceFilter.join(';');
    const sameFilter = previous.resources === filterKey;
    const query = new URLSearchParams({ resources: filterKey, per_page: '100' });
    if (!sameFilter || !previous.sync_token) query.set('bootstrap', 'true');
    else query.set('sync_token', previous.sync_token);
    const pages = await fetchAllPages(`/content/api/v4/resources/sync?${query}`);
    let changesApplied = 0;
    let snapshotsFetched = 0;
    for (const page of pages) {
      for (const change of (page.changes || [])) {
        const before = change.type;
        await applyMutation(change);
        changesApplied += 1;
        if (before === 'RESOURCE_CREATE' || before === 'RESOURCE_INVALIDATE') snapshotsFetched += 1;
      }
    }
    const finalPage = pages.at(-1) || {};
    if (!finalPage.next_sync_token) throw new Error('Final sync page did not include next_sync_token; checkpoint not advanced');
    // Commit the checkpoint only after every page and snapshot/mutation succeeded.
    await atomicJson(statePath, {
      resources: filterKey,
      sync_token: finalPage.next_sync_token,
      sync_until_sequence: finalPage.sync_until_sequence ?? null,
      completed_at: new Date().toISOString(),
      pages: pages.length,
      changes_applied: changesApplied,
      snapshots_fetched: snapshotsFetched,
    });
    return { ok: true, bootstrap: !sameFilter || !previous.sync_token, pages: pages.length, changesApplied, snapshotsFetched, syncUntilSequence: finalPage.sync_until_sequence ?? null };
  }

  async function run() {
    if (activeRun) throw new Error('A Content Sync run is already in progress');
    activeRun = runInternal();
    try { return await activeRun; }
    finally { activeRun = null; }
  }

  return { run };
}
