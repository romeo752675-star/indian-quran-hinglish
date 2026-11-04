# Quran Content Review Workflow

## Current verified technical baseline

- Arabic text: 6,236 Ayahs from the supplied Tanzil Quran Simple source, preserved verbatim.
- Surah catalogue: 114 records.
- Existing non-empty transliteration / Hinglish meaning / Tafsir: 22 draft records (Al-Fatihah and Surahs 112–114); these are **not** religiously or linguistically certified.
- Remaining records: 6,214 Ayahs marked `pending_review` with those fields intentionally blank.

## Required review for each Ayah

1. Select a named translation / transliteration / tafsir source.
2. Record the exact edition, translator or scholar, URL, licence and permission evidence.
3. Do not paraphrase a copyrighted translation into a derivative dataset unless the rights holder permits it.
4. Have the Roman pronunciation reviewed by a person qualified in Quranic recitation / tajweed. Roman text is only a reading aid and must not be presented as a substitute for learning recitation.
5. Have Hinglish meaning and separate explanation reviewed by a qualified reviewer. A translation of meaning is not the Quran itself.
6. Record reviewer, review date, source and status. Only change status to `verified` after all required checks are complete.

## Licensing gate

Tanzil's Arabic Quran text may be copied verbatim under CC BY 3.0 with attribution and a link to Tanzil. The text must not be changed. Keep the complete notice in the app and redistributed project.

Tanzil explicitly says translations offered in its translation repository are for non-commercial use, and redistribution of its list is not allowed without direct permission. Do not assume that a translation can be bundled in a commercial Play Store app merely because it can be downloaded. Obtain the translator / publisher's permission for the intended use.

No source has yet been approved for all 6,214 missing Hinglish meanings, transliterations or explanations. Therefore, no such text has been invented or bulk-filled.

## Queue file

`content_review_queue.csv` contains one row per Ayah. Draft content is retained as draft, and pending content remains blank. Fill source and review columns only after checking the actual source and permissions.
