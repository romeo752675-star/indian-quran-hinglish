import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { createSyncEngine, parseResourceFilter } from '../sync_engine.mjs';

 test('resource filter validates groups and numeric ids', () => {
  assert.deepEqual(parseResourceFilter('quran_core:1;translations:19'), ['quran_core:1', 'translations:19']);
  assert.throws(() => parseResourceFilter('made_up:1'));
  assert.throws(() => parseResourceFilter('translations:nope'));
});

test('bootstrap follows pages, snapshots resources, and saves final token last', async () => {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), 'qf-sync-'));
  const calls = [];
  const apiRequest = async (url) => {
    calls.push(url);
    if (url.includes('cursor=page2')) return new Response(JSON.stringify({
      has_more: false,
      next_sync_token: 'checkpoint-2',
      sync_until_sequence: 12,
      changes: [{ type: 'ROW_CREATE', resource_group: 'translations', resource_id: 19, record_type: 'translation', record_key: 'ayah-1', data: { id: 'ayah-1', text: 'sample' } }],
    }), { status: 200 });
    if (url.includes('/resources/sync?')) return new Response(JSON.stringify({
      has_more: true,
      next_page_url: '/api/v4/resources/sync?cursor=page2',
      changes: [{ type: 'RESOURCE_CREATE', resource_group: 'translations', resource_id: 19, snapshot_url: '/api/v4/resources/snapshots/translations/19' }],
    }), { status: 200 });
    if (url.includes('/snapshots/translations/19')) return new Response(JSON.stringify({ records: [{ id: 1, record_type: 'translation', text: 'snapshot' }] }), { status: 200 });
    throw new Error(`Unexpected URL ${url}`);
  };
  try {
    const engine = createSyncEngine({ apiRequest, storeDir: dir, resources: 'translations:19' });
    const result = await engine.run();
    assert.equal(result.ok, true);
    assert.equal(result.pages, 2);
    assert.equal(result.changesApplied, 2);
    assert.equal(result.snapshotsFetched, 1);
    assert.ok(calls.includes('/content/api/v4/resources/sync?cursor=page2'));
    const state = JSON.parse(await fs.readFile(path.join(dir, 'sync-state.json'), 'utf8'));
    assert.equal(state.sync_token, 'checkpoint-2');
    const snapshot = JSON.parse(await fs.readFile(path.join(dir, 'resources', 'translations__19.json'), 'utf8'));
    assert.equal(snapshot.records['translation:ayah-1'].text, 'sample');
  } finally { await fs.rm(dir, { recursive: true, force: true }); }
});

test('failed snapshot does not advance sync checkpoint', async () => {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), 'qf-sync-fail-'));
  const apiRequest = async (url) => {
    if (url.includes('/resources/sync?')) return new Response(JSON.stringify({
      has_more: false, next_sync_token: 'must-not-save',
      changes: [{ type: 'RESOURCE_CREATE', resource_group: 'tafsirs', resource_id: 151, snapshot_url: '/api/v4/resources/snapshots/tafsirs/151' }],
    }), { status: 200 });
    return new Response('{}', { status: 503 });
  };
  try {
    const engine = createSyncEngine({ apiRequest, storeDir: dir, resources: 'tafsirs:151' });
    await assert.rejects(() => engine.run(), /Snapshot fetch failed/);
    await assert.rejects(() => fs.access(path.join(dir, 'sync-state.json')));
  } finally { await fs.rm(dir, { recursive: true, force: true }); }
});
