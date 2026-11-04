# v1.0.13 — app-side reviewed content delivery

- Added a Flutter HTTP client for a publisher-controlled reviewed-content manifest.
- Added transactional SQLite updates for reviewed transliteration, Hinglish meaning and Tafsir.
- Arabic text and Ayah numbering are immutable through this pathway.
- Added per-Ayah source, URL, license and reviewer metadata storage.
- Added a Settings action to check for reviewed content updates.
- Added backend read-only manifest endpoint and schema example.
- Version: 1.0.13+14.

## Verification boundaries

The manifest currently contains no approved content. Quran Foundation credentials, resource IDs, actual upstream sync, resource schema mapping, content licensing, Flutter compilation, APK generation and device tests remain unverified/pending. No translation, transliteration or Tafsir was fabricated.
