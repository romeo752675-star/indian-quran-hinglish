# Release notes — 1.0.8

## Changes
- Search results are now protected against out-of-order asynchronous responses. If a user types a new query while an earlier search is still running, the stale response is ignored rather than replacing the latest results.
- Clearing or changing the search query invalidates earlier in-flight requests.
- Database search now clamps the requested result limit to 1–250 rows to avoid unbounded result loads.
- App package version updated to `1.0.8+9`.

## Verification boundaries
- Source changes and Python/database release preflight are checked.
- Flutter compilation, widget tests, Android APK generation, physical-device behavior, audio reachability/licensing, and religious-content review have not been performed in this environment.
- The bundled database still contains 6,214 Ayahs with pronunciation, Hinglish meaning, and Tafsir pending review, plus 22 draft entries that are not certified.
