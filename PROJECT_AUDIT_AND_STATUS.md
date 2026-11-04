# Project Audit and Status — 2026-11-04

## Confirmed database facts

- 114 Surah records.
- 6,236 Ayah records.
- Global Ayah numbers are unique and contiguous from 1 through 6,236.
- Each Surah's stored Ayah count matches its actual rows.
- Arabic text matches the supplied Tanzil `quran-simple.txt` file for all 6,236 Ayahs.
- SQLite `PRAGMA integrity_check` returns `ok`.
- 22 records are marked `existing_draft_needs_review`.
- 6,214 records are marked `pending_review`.
- Only 22 rows currently have non-empty transliteration, Hinglish meaning and Tafsir fields.

## Code changes in this build

- Theme preference now supports Light Green, Dark and System modes, persisted using SharedPreferences.
- Bookmarks tab recreates its view when opened so changes made in the reader are reflected instead of showing a stale in-memory list.
- App version incremented to 1.0.4+5.
- Added a content-review guide and a per-Ayah review queue CSV.

## Not verified / not complete

- Flutter/Dart compilation, analyzer and widget tests were not run because Flutter SDK is unavailable in this environment.
- No Android APK was built; this source archive does not contain a generated Android platform folder.
- Audio URLs have not been fetched or played; availability, streaming reliability, reciter identity and redistribution rights remain unverified.
- Background playback and the newly added continuous/repeat source implementation have not been verified on a real Android device.
- The 22 retained text records remain drafts; the other 6,214 records still need authentic, licensed content and qualified review.
- Search and UI interactions have been inspected in source but not exercised on a device.

This project is a development build, not a production-ready or publication-ready Quran app.


## Update 1.0.3 (4 November 2026)
- Ayah copy action includes labelled pronunciation, Hinglish meaning and Aasaan Samajh sections when available; empty sections are omitted.
- Missing audio has a visible user message.
- Theme-loading lifecycle guard and live settings theme synchronization added.
- Added `CONTENT_SOURCE_RESEARCH.md` comparing official Quran Foundation API terms, Quranpedia API documentation, and Tanzil translation restrictions.
- Database content remains unchanged: 6,214 pending and 22 draft records; no unverified religious content was generated.
- Flutter compilation/device testing remains outstanding.


## Version 1.0.4+5 update — 4 November 2026

Implemented in source (not yet Flutter-compiled):
- Bumped the bundled database filename to `quran_hinglish_v3.db`. This avoids an older installed v2 database silently taking precedence after an app update.
- Database asset installation now writes to a temporary file and renames only after the full copy, then runs SQLite `quick_check`. Concurrent first-open requests share one initialization future.
- Search now escapes SQL LIKE wildcard characters (`%`, `_`, and `\`) so a user's search text is treated literally.
- Audio playback now validates HTTPS URLs, prevents stale overlapping play requests from taking over, reports playback errors to the UI, and initializes its player-state listener only once.
- Updated source research with current Quran Foundation and Quranpedia API restrictions. No API content was bulk-copied into the app.

Validation performed: Python SQLite audit passes with 114 Surahs and 6,236 Ayahs; SQLite `quick_check` returns `ok`; the literal-search SQL was executed against the bundled database successfully. Flutter/Dart SDK is not installed in this environment, so `flutter analyze`, widget tests, APK build, and real-device audio tests remain unperformed.


## Version 1.0.5 — 5 November 2026

- Added `tools/preflight_release.py`, a repeatable read-only check for database integrity, all 114 Surahs / 6,236 Ayahs, numbering, empty Arabic rows, review status, audio URL scheme, review-queue coverage, app asset declaration and in-app attribution/disclosure.
- Added `QURAN_FOUNDATION_CONTENT_SYNC_INTEGRATION.md` describing the required backend, approved credentials, Content Sync flow, weekly sync obligation, attribution and prelive dataset limitation.
- Incremented app package version to `1.0.5+6`.
- This remains a source/data validation update, not a Flutter compile or device test.


## Version 1.0.6+7 — 5 November 2026

Implemented in source (Flutter compilation and device playback not yet verified):
- Added Surah audio queue playback with automatic progression to the next Ayah.
- Added Previous Ayah / Next Ayah controls in the Surah reader.
- Added repeat modes: Off, Repeat Surah, and Repeat Ayah.
- Queue playback skips missing or invalid (non-HTTPS) audio URLs and reports when no playable Ayah remains.
- Existing per-Ayah play/pause remains available.
- Added `RELEASE_NOTES_1.0.6.md`; package version is `1.0.6+7`.

The Python release preflight was rerun: 21 checks passed, 0 failed. SQLite integrity remains `ok`, with 114 Surahs and 6,236 Ayahs. Audio URL reachability, reciter/verse mapping, rights, background playback and real-device behavior are still unverified. Hinglish content status is unchanged: 22 draft rows and 6,214 pending rows.
