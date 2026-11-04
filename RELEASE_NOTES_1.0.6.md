# Indian Quran (in Hinglish) — Version 1.0.6

## Implemented in source

- Added Surah-level audio queue playback from the selected Surah's first Ayah.
- Added automatic next-Ayah playback when the current audio finishes.
- Added Previous Ayah and Next Ayah controls while reading a Surah.
- Added repeat modes: Off, Repeat Surah, and Repeat Ayah.
- Audio queue skips entries whose URL is missing or is not a valid HTTPS URL.
- Existing single-Ayah play/pause remains available on each Ayah card.
- Incremented package version to `1.0.6+7`.

## Verification performed

- Release data preflight: 21 checks passed, 0 failed.
- SQLite integrity: `ok`.
- Quran structure: 114 Surahs and 6,236 Ayahs.
- Review state: 22 draft entries and 6,214 pending entries remain explicitly unverified.
- ZIP archive integrity: verified after packaging.

## Not verified / still required

- Flutter/Dart SDK is not installed in the current build environment, so `flutter pub get`, `flutter analyze`, `flutter test`, and Android APK/AAB builds were not run.
- Audio URLs are structurally HTTPS only; reachability, reciter identity, mapping, and redistribution rights have not been verified.
- Continuous playback behavior needs testing on a real Android device, including background playback and interruptions.
- Hinglish transliteration, translation, and Tafsir remain incomplete and require licensed source material and qualified review. No AI-generated religious text was inserted.
- Quran Foundation production API credentials and backend deployment are still not configured. Do not put API client secrets in the mobile app.
