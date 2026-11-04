# Content source research — 4 November 2026

## Decision: do not bulk-import unlicensed text

The current app contains the complete Arabic verse text, but most Roman pronunciation, Hinglish meaning and Aasaan Samajh fields are intentionally marked pending. A dataset being publicly downloadable does not itself grant redistribution rights. No generated or machine-translated Quran meaning/tafsir has been inserted.

## Candidate 1 — Quran Foundation / Quran.com Content APIs

- Official docs expose chapters, verses, translations, tafsirs and recitations.
- The Developer Terms currently permit an app to display QF content in its end-user experience, including an app with ads, subscriptions or donations, subject to the terms.
- QF content/raw API data must not be sold, sublicensed or separately redistributed. A separately distributed offline content package/dataset requires a signed commercial licence.
- The official quickstart says mobile apps must not embed a backend client secret; use a developer-controlled backend/proxy for Content API credentials.
- Their connected-app guidance says external translations, tafsir editions and recitations need verifiable rights and source attribution. Supported offline resources have sync/update obligations.
- Implication: potentially suitable for an online reading mode after registering an app, getting production approval, selecting a specific translation/tafsir edition, and implementing a secure backend. Not a drop-in source for bundling raw data in this ZIP.

Official references:
- Developer Terms: https://api-docs.quran.com/legal/developer-terms/
- Content API reference: https://api-docs.quran.com/docs/api-reference/
- OAuth2 quickstart: https://api-docs.quran.com/docs/quickstart/
- Connected Apps content/rights guidance: https://api-docs.quran.com/docs/connected-apps/

## Candidate 2 — Quranpedia API

- Public documentation describes a free read-only API for Quran text, translations, tafsirs and reciters, with no authentication required.
- Its documentation says attribution is optional for apps querying the API live, but required when publishing downloadable datasets/dumps.
- Before production use, each exact translation and tafsir edition still needs review for its author, language, theological/editorial provenance, completeness, and any edition-specific restrictions. API-level access should not be treated as blanket permission to package or redistribute every underlying work.
- Implication: a promising live API candidate for a prototype, but do not bundle its responses offline until the specific content rights are confirmed.

Official reference: https://quranpedia.net/api-docs

## Candidate 3 — Tanzil translations

The Tanzil translation repository notes non-commercial restrictions for its hosted translations and requires permission for other uses; redistribution is restricted. Therefore these translations are not assumed suitable for a public Play Store app or bundled database without written permission for the exact edition.

## What is required before filling the 6,214 pending Ayahs

1. Choose a named, traceable transliteration edition and obtain reuse permission or a clear licence.
2. Choose a named Hindi/Urdu/Hinglish translation source. A Hinglish rendering is a derivative translation and needs qualified linguistic/religious review plus rights clearance.
3. Choose a named tafsir edition and obtain rights to display it. Keep tafsir separate from translation.
4. Record edition, author/publisher, source URL, licence/permission evidence, reviewer and review date per content set.
5. Have qualified reviewers check Arabic-to-meaning alignment and pronunciation before marking any content verified.

## App changes in this iteration

- Copy Ayah now includes each available section with labels and blank sections omitted; it includes Aasaan Samajh when present.
- Missing audio now produces a user-facing message instead of silently doing nothing.
- Theme loading checks that the app is still mounted before calling setState.
- Settings screen synchronizes its selected theme if the parent theme changes while it is open.

These source changes have not been compiled or device-tested because the Flutter SDK is not available in the current build environment.


## Integration decision update — 4 November 2026

### Quran Foundation (Quran.com) APIs

Official developer terms now explicitly permit displaying Quran Foundation content inside an end-user app, including a paid/freemium app, but prohibit selling or redistributing the raw content. A normal API response may not be used to create a permanent offline database: content available through Content Sync must be obtained and maintained through Content Sync, with a sync at least every seven days when connectivity permits. A prepackaged database containing QF content is not automatically permitted. Content API credentials must stay on a developer-controlled backend; a mobile app must not contain a client secret. The app must also provide a public privacy policy and terms of use and credit the named translation, tafsir edition, and recitation source.

Decision: do not copy Quran Foundation API responses into this project's bundled SQLite database. A compliant integration needs a small secured backend, approved credentials, documented Content Sync support for the selected resources, and an in-app source/edition display.

Official references: [Developer Terms](https://api-docs.quran.com/legal/developer-terms/), [Content API Quickstart](https://api-docs.quran.com/docs/quickstart/), [Content and attribution requirements](https://api-docs.quran.foundation/docs/connected-apps/).

### Quranpedia API

Quranpedia documents free live API access for app integrations and provides Quran text, translations, tafsir books, reciters and related resources. Its policy explicitly says the API is not a bulk-scraping/mirroring service and that its content is corrected over time. The API's live-use permission should not be interpreted as permission to download and bundle its full corpus. Each selected translation/tafsir edition still needs content-level suitability and source review for an Indian Hinglish audience.

Decision: suitable for further live-endpoint evaluation and source discovery; do not bulk-import its dumps or claim that it supplies an approved Hinglish translation without verifying the exact edition and rights.

Official references: [Quranpedia API docs and usage policy](https://quranpedia.net/api-docs), [Quranpedia data downloads and version notes](https://api.quranpedia.net/dumps?lang=en).

### Current project content decision

The bundled database remains Arabic text plus clearly marked unreviewed draft/pending fields. No translation, transliteration, tafsir, or audio attribution has been silently fabricated or bulk-imported. Before public release, select exact named editions, obtain and record their licences/permissions, and arrange qualified review of Roman pronunciation and Hinglish wording.
