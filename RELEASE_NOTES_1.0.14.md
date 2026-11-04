# v1.0.14 — reviewed-content sync hardening

- Require HTTPS for the configured mobile content-sync server.
- Enforce a 15 MB manifest response limit and a maximum of 6,236 records.
- Reject malformed manifest rows instead of silently coercing non-map values.
- Backend public manifest now publishes only approved, complete, source-attributed, HTTPS-linked, unique Ayah records; drafts and pending records remain private to the manifest source.
- Mobile database import validates HTTPS source URLs, explicit license metadata, reviewer approval, field-size limits, unique Ayah keys, and existence of the target Ayah before updating.
- Arabic text and Ayah numbering remain immutable.
- Version: 1.0.14+15.

## Verification boundaries

Backend syntax and automated backend tests plus Quran database preflight are run for this release. Flutter/Dart SDK is not available in this environment, so Dart analysis, Flutter tests, Android compilation, APK installation, live Quran Foundation API sync, and device testing are not claimed. No religious content was generated or marked reviewed.
