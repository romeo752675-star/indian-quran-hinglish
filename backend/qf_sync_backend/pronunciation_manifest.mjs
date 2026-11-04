/** Build complete Ayah-level Roman pronunciation from Quran Foundation's
 * word-by-word transliteration resource and quran_core word ownership rows.
 * Never invent missing words: an Ayah is emitted only when every Quran word
 * in that verse has a non-empty transliteration.
 */
export function buildAyahPronunciationManifest(coreSnapshot, transliterationSnapshot) {
  if (!Array.isArray(coreSnapshot?.records) || !Array.isArray(transliterationSnapshot?.records)) {
    throw new Error('Both quran_core and word-by-word transliteration snapshots are required');
  }
  const verses = new Map();
  const words = new Map();
  for (const row of coreSnapshot.records) {
    if (row?.record_type === 'verse' && /^\d{1,3}:\d{1,3}$/.test(String(row.verse_key || ''))) {
      verses.set(Number(row.id), { verseKey: row.verse_key, expected: 0, words: [] });
    }
  }
  for (const row of coreSnapshot.records) {
    if (row?.record_type !== 'word' || row.char_type_name && row.char_type_name !== 'word') continue;
    const verse = verses.get(Number(row.verse_id));
    if (!verse) continue;
    const wordId = Number(row.id);
    const position = Number(row.position);
    if (!Number.isSafeInteger(wordId) || !Number.isSafeInteger(position) || position < 1) continue;
    verse.expected += 1;
    const word = { verse, position, text: '' };
    verse.words.push(word);
    words.set(wordId, word);
  }
  for (const row of transliterationSnapshot.records) {
    if (row?.record_type !== 'word_transliteration') continue;
    const target = words.get(Number(row.word_id));
    const text = String(row.text || '').trim();
    if (target && text && !target.text) target.text = text;
  }
  const complete = [];
  let missingWords = 0;
  for (const verse of verses.values()) {
    const verseWords = verse.words;
    verseWords.sort((a, b) => a.position - b.position);
    const translated = verseWords.filter((word) => word.text);
    missingWords += verseWords.length - translated.length;
    if (verse.expected > 0 && translated.length === verse.expected) {
      const [surahNumber, numberInSurah] = verse.verseKey.split(':').map(Number);
      complete.push({
        surah_number: surahNumber,
        number_in_surah: numberInSurah,
        transliteration: translated.map((word) => word.text).join(' '),
        word_count: verse.expected,
      });
    }
  }
  complete.sort((a, b) => a.surah_number - b.surah_number || a.number_in_surah - b.number_in_surah);
  return {
    schema_version: 1,
    source_name: 'Quran.Foundation English word-by-word transliteration',
    source_url: 'https://api-docs.quran.foundation/docs/tutorials/content-sync/getting-started/',
    license: 'Quran Foundation Developer Terms; use only within the connected app under applicable terms',
    attribution: 'Quran data provided by Quran.Foundation. Word transliteration source: Quran.Foundation.',
    review_status: 'source_unreviewed',
    total_ayahs: 6236,
    complete_ayahs: complete.length,
    incomplete_ayahs: 6236 - complete.length,
    missing_word_transliterations: missingWords,
    records: complete,
  };
}
