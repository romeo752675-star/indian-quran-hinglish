import test from 'node:test';
import assert from 'node:assert/strict';
import { buildAyahPronunciationManifest } from '../pronunciation_manifest.mjs';

test('joins word transliterations by word_id and preserves verse word order', () => {
  const core = { records: [
    { record_type: 'verse', id: 1, verse_key: '1:1' },
    { record_type: 'word', id: 10, verse_id: 1, position: 1, char_type_name: 'word' },
    { record_type: 'word', id: 11, verse_id: 1, position: 2, char_type_name: 'word' },
  ] };
  const translit = { records: [
    { record_type: 'word_transliteration', word_id: 11, text: 'llahi' },
    { record_type: 'word_transliteration', word_id: 10, text: 'bis\'mi' },
  ] };
  const result = buildAyahPronunciationManifest(core, translit);
  assert.equal(result.complete_ayahs, 1);
  assert.equal(result.records[0].transliteration, "bis'mi llahi");
});

test('does not fabricate or emit an Ayah with missing word pronunciation', () => {
  const core = { records: [
    { record_type: 'verse', id: 1, verse_key: '1:1' },
    { record_type: 'word', id: 10, verse_id: 1, position: 1, char_type_name: 'word' },
    { record_type: 'word', id: 11, verse_id: 1, position: 2, char_type_name: 'word' },
  ] };
  const translit = { records: [{ record_type: 'word_transliteration', word_id: 10, text: 'bis\'mi' }] };
  const result = buildAyahPronunciationManifest(core, translit);
  assert.equal(result.complete_ayahs, 0);
  assert.equal(result.incomplete_ayahs, 6236);
  assert.equal(result.missing_word_transliterations, 1);
});

test('rejects missing snapshot arrays', () => {
  assert.throws(() => buildAyahPronunciationManifest({}, {}), /snapshots are required/);
});
