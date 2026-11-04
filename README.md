# Indian Quran (in Hinglish)

**Tagline:** Understand the Quran. One Ayah at a time.

A Flutter Quran reader development project for Indian readers who prefer Roman-script Hinglish.

## Current project status

This is a source-project foundation, **not yet a complete, publication-ready Hinglish Quran**.

- 114 Surah metadata records.
- 6,236 Ayah records with global and per-Surah numbering.
- Arabic Ayah text is copied verbatim from the supplied Tanzil `quran-simple.txt` source and compared against all 6,236 source records.
- 22 Ayahs (Al-Fatihah and Surahs 112–114) contain existing transliteration, Hinglish meaning and explanatory text. These remain **unverified drafts** and require qualified review.
- The other 6,214 Ayahs have blank transliteration, Hinglish meaning and Tafsir fields. The app displays a pending-review note instead of fabricated filler.
- Audio URL numbering is aligned to global Ayah numbers. Network availability, actual device playback and redistribution rights have not been independently verified.
- The project includes offline SQLite, Surah browsing, bookmarks, last-read saving, Light Green/Dark/System themes, Quran search, adjustable reading fonts, per-Ayah audio play/pause, and a source implementation for Surah queue playback with next/previous and repeat modes. Continuous/background playback still needs real-device verification.

## Content safeguards

- Translation and Aasaan Samajh explanation are separate fields.
- Placeholder sentences are not presented as real translation or Tafsir.
- Existing 22 text records are not certified by this technical audit.
- Do not publish or advertise this as a complete Hinglish translation until remaining content is sourced, translated and reviewed.

## Arabic text attribution

Arabic text source: **Tanzil Quran Text – Simple format**  
Website: https://tanzil.net  
License: **Creative Commons Attribution 3.0 (CC BY 3.0)**

The Arabic text is reproduced verbatim from the supplied source file. Preserve Tanzil attribution, applicable copyright notice and license information in distributions. Do not modify the Quran text.

## Audio and other content rights

The supplied audio URL pattern points to the Alafasy audio CDN. This audit checked URL numbering only; it did not establish commercial redistribution rights or verify that every URL is reachable. Confirm the recitation provider's current terms and obtain required permissions before Play Store or commercial distribution.

## Build

Requires Flutter SDK (Dart 3 compatible). From this directory:

```bash
flutter pub get
flutter test
flutter run
```

The bundled SQLite file uses the versioned filename `quran_hinglish_v3.db` so an older installed database does not silently override the repaired Arabic dataset.


## Visual theme
The default light appearance uses a soft light-green background, white cards with subtle pale-green borders, deep-green text/actions, and restrained gold accents. Dark mode remains available.


## Latest UI update — 4 November 2026
- Refreshed the Home screen with the light-green visual direction, clearer reading entry points, and Surah/Ayah count cards.
- Replaced any implication that all Hinglish content is verified with an explicit review-status note.
- Refined global card/navigation styling and added a clear-search affordance to the Surah catalogue.
- This is a source/UI update only. Flutter build, analyzer, emulator and device tests have not been run in this environment.


See `PROJECT_AUDIT_AND_STATUS.md` for the latest independent audit and `ANDROID_BUILD_GUIDE.md` for Android setup/build steps. This ZIP does not contain a compiled APK or generated Android platform folder.


## Release preflight and content-sync architecture — 5 November 2026

- Run `python3 tools/preflight_release.py` for a read-only database, review-queue, asset declaration and attribution preflight.
- See `QURAN_FOUNDATION_CONTENT_SYNC_INTEGRATION.md` for the compliant architecture required before using Quran Foundation content online/offline.
- The preflight does not compile Flutter, check live audio URLs, establish audio rights, or certify translation, transliteration or Tafsir.


## Audio queue update — 1.0.6

The reader now includes Play Surah, Previous Ayah, Next Ayah, and repeat-mode controls. The source audio service advances through the Surah queue and can repeat the current Ayah or the Surah. These controls are implemented in source but have not yet been compiled or tested on Android; audio URL reachability and licensing are also unverified.
