# Release notes — 1.0.9

## Search improvements
- Search now includes Surah English translations and the separate Tafsir field, in addition to Arabic, transliteration, Hinglish translation, and Surah English names.
- Search result cards show available Roman pronunciation and a separate Aasaan Samajh excerpt without merging it into the translation.
- Results with content status other than `verified` visibly show that review is pending.
- Existing stale-request protection and bounded result limits are retained.

## Verification boundary
- Source and SQLite preflight checks are run when this package is prepared.
- Flutter/Dart SDK is not available in the packaging environment; Flutter analyzer, tests, APK build, and device playback are not claimed.
- Displaying a review label does not certify religious accuracy. The current database still has 6,214 Ayahs awaiting transliteration, Hinglish translation, and Tafsir review.
