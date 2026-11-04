# Sources and licensing notes

## Arabic Quran text
- Source: Tanzil Quran Text, Simple format — https://tanzil.net
- License: Creative Commons Attribution 3.0 (CC BY 3.0).
- The Arabic Ayah text in the bundled SQLite database is reproduced verbatim from the supplied `quran-simple.txt` file.
- Do not modify the Quran text. Keep the copyright / license notice and a clear link to Tanzil in the app and redistributed copies.
- Required notice:

  Tanzil Quran Text  
  Copyright (C) 2007-2021 Tanzil Project  
  License: Creative Commons Attribution 3.0  
  Source: https://tanzil.net/  
  Text must be reproduced verbatim. See https://tanzil.net/docs/Text_License

## Translations and Tafsir
- 22 existing records for Al-Fatihah and Surahs 112–114 are retained as unverified drafts; technical inspection is not religious or linguistic certification.
- The remaining 6,214 Ayahs have transliteration, Hinglish meaning and Tafsir left blank and marked pending review.
- Tanzil's translation repository states that its listed translations are for non-commercial use and that redistribution of its list requires direct permission. Obtain explicit permission for any commercial / Play Store use; do not infer commercial rights from availability for download.
- Do not assume that transliteration or Tafsir content is free for commercial use. Record source, translator / author, exact edition, licence and permission for each dataset.

## Recitation audio
- The database retains audio URLs supplied in the earlier project.
- The URL numbering pattern was checked previously against global Ayah numbering, but no audio file was downloaded or played in this build.
- URL presence is not proof of availability or permission for commercial redistribution. Verify the provider, reciter, audio terms and actual playback before release.


## Audio and live API integration notes (4 November 2026)

The current database contains 6,236 HTTPS audio URLs using the Alafasy recitation path on cdn.islamic.network. URL presence is not proof that each file is reachable, that the audio edition is correctly attributed, or that redistribution/offline caching is licensed. Keep playback streaming-only until the exact recitation source and applicable rights are documented.

Quran Foundation API content must not be copied into the bundled SQLite database based on ordinary API access. Review its current Developer Terms and use the documented Content Sync flow for eligible offline resources; keep confidential credentials on a backend, never inside the Android app. Quranpedia's policy permits live API querying by apps but explicitly disallows bulk scraping/mirroring as a substitute for live access.
