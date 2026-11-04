# Release 1.0.12 — Content Sync engine foundation

## Implemented
- Added a durable backend Content Sync engine for bootstrap and incremental sync.
- Follows all `next_page_url` pages and fetches resource snapshots for create/invalidate events.
- Applies resource create/invalidate/delete/update and row create/update/delete mutations.
- Persists resource snapshots and sync state atomically; advances the sync token only after all pages and mutations succeed.
- Rebootstraps when the configured resource filter changes.
- Adds a protected `POST /sync/run` route requiring a backend-only admin bearer key.
- Adds Node test coverage for resource-filter validation, multi-page bootstrap/snapshot/row mutation, and checkpoint safety after snapshot failure.
- Updated app package version to `1.0.12+13`.

## Verification
- Node syntax checks: passed.
- Node test suite: 3 passed, 0 failed.
- Quran data/source preflight: 21 passed, 0 failed.
- Flutter compilation, Android APK build, real Quran Foundation API calls, and device testing were not run.

## Remaining integration work
- Confirm approved resource IDs and permissions in the Developer Console; do not assume sample IDs are approved or suitable.
- Configure credentials and persistent backend storage, then test against the matching QF environment.
- Add a Flutter SQLite adapter and app-side sync scheduling to consume backend snapshots safely.
- Review translation, transliteration, tafsir licensing and suitability; complete qualified religious/linguistic review.
