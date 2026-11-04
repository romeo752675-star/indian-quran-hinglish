# Indian Quran (in Hinglish) — v1.0.15

## Focus: full-Quran Roman pronunciation ingestion

- Added a Quran Foundation word-by-word transliteration manifest builder.
- Uses the documented `quran_core:1` word ownership (`word_id`, `verse_id`, `position`, `verse_key`) and `word_by_word_transliterations:60` records.
- Joins transliteration words in their Quran verse order and emits an Ayah only when every Quran word in that Ayah has a non-empty source transliteration. Missing words are never guessed or synthesized.
- Added backend `GET /app/ayah-pronunciation` endpoint. It serves only from locally Content-Synced snapshots; it does not scrape regular endpoints.
- Added Flutter import flow and SQLite pronunciation provenance/status fields.
- Imported source transliterations are labelled `Source transliteration • Hafiz review pending`; they are not described as Hafiz-approved or religiously certified.
- Existing non-empty transliterations are not overwritten.
- Added source attribution in Settings.

## Required backend configuration

Use approved production credentials and set:

`QF_ENV=production`

`QF_SYNC_RESOURCES=quran_core:1;word_by_word_transliterations:60`

Run the backend Content Sync job first. Then the app can call `/app/ayah-pronunciation` with `CONTENT_SYNC_BASE_URL` configured to the HTTPS backend origin.

Quran Foundation documentation currently identifies production transliteration resource `60` as English word-by-word transliteration, with 77,429 word rows. This does not by itself prove that all 6,236 Ayahs are complete; the manifest builder calculates coverage from actual snapshots and excludes incomplete Ayahs. Resource access and Developer Terms must be confirmed for the app's approved account.

## Verification boundaries

- Node unit tests cover verse-word mapping, ordering, missing-word handling, and invalid payload rejection.
- Database release preflight remains separate from Flutter compilation.
- No live Quran Foundation sync was possible without approved API credentials.
- No real 6,214-Ayah source manifest was downloaded in this environment; therefore no claim is made that 6,214 pronunciations have been populated.
- Flutter SDK is not available in this environment; APK build/device testing remains pending.
- A Hafiz should review pronunciation rendering and Roman reading before final publication.
