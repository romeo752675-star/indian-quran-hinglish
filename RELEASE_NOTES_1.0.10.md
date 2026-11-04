# Release notes — 1.0.10

- Added a Node.js Quran Foundation Content Sync gateway starter under `backend/qf_sync_backend/`.
- Added `.env.example` with placeholders; no credentials included.
- Gateway only allows QF Content Sync routes (`resources/sync` and `resources/snapshots`) and returns `503` until credentials are configured.
- Added `CONTENT_SYNC_NEXT_STEPS.md` describing setup and remaining integration work.

## Verification boundary
- Node syntax check and route behavior can be tested locally.
- This is a starter gateway, not a production backend or full Content Sync implementation.
- No QF credentials, source edition selections, backend deployment, Flutter sync integration, APK build, or device tests are present.
