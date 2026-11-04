# Release 1.0.11 — backend authentication foundation

- Corrected the Quran Foundation backend authentication model: it now uses OAuth2 Client Credentials with `QF_CLIENT_ID` and server-only `QF_CLIENT_SECRET`, rather than expecting a manually supplied permanent access token.
- Added prelive/production environment selection with matching OAuth and Content API hosts.
- Added access-token caching and one bounded retry after a Content API 401.
- Tightened the gateway allowlist to the Content Sync endpoint and documented resource snapshot paths; query parameters are preserved.
- Made the bind host configurable for deployment and updated health output without exposing credentials.
- Updated backend setup documentation and `.env.example`.

## Verification boundaries

- Node.js syntax and local route/health smoke tests are run for this release.
- No Quran Foundation credentials were available, so OAuth exchange, API approval, resource availability, and real Content Sync were not tested.
- This is not yet a complete sync engine or production-deployed backend.
- Flutter SDK is unavailable in the build environment; Flutter analyze/tests and APK build remain unperformed.
- Quran content remains 22 unverified draft rows and 6,214 pending rows for pronunciation, Hinglish meaning, and Tafsir.
