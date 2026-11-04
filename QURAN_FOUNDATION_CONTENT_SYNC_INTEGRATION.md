# Quran Foundation content integration — implementation requirements

**Status: architecture decision; no API credentials or live sync are configured.**

This project must not download Quran Foundation (QF) content through ordinary read endpoints and then silently copy it into the bundled SQLite database. QF's current Developer Terms restrict long-term caching of API content. If a resource is supported by Content Sync, Content Sync is the required route for an offline copy. A QF content database must not be distributed as a prepackaged dataset unless the relevant redistribution permission is expressly granted.

## Recommended architecture

1. Register the application in the QF Developer Console and obtain approved production access.
2. Run a small developer-controlled HTTPS backend. Keep client secrets and token exchange on that backend; never embed a client secret in the Flutter APK.
3. The Flutter app requests only the content needed for its reader from the backend.
4. For resources intended for offline use, the backend/client follows QF Content Sync bootstrap, snapshot, incremental mutation, and token rules. Store a separate sync token for each exact resource filter.
5. Keep the local database as a cache of synchronized resources, not as a redistribution package. Apply snapshots atomically per resource and mutations idempotently.
6. When connectivity permits, perform the next sync at least every seven days and apply corrections. Sync promptly after connectivity returns from a longer outage.
7. Display the named translation, tafsir edition, reciter and QF source attribution in the app. Publish a privacy policy and terms of use before release.

## Resource groups documented for Content Sync

- `quran_core`
- `translations`
- `word_by_word_translations`
- `word_by_word_transliterations`
- `tafsirs`
- `recitations`
- `chapter_recitations`
- `mushafs`
- `articles`

A documented example resource filter is `translations:19;tafsirs:151;word_by_word_transliterations:60;chapter_recitations:159;mushafs:1`. These IDs are examples from the documentation, not an endorsement that those exact editions are appropriate for this app's Indian Hinglish audience. Confirm the selected resources, language, edition, and rights in the production console before implementation.

## Critical environment warning

QF documentation states that the prelive dataset is limited to Al-Fatihah and Al-Baqarah. It is not a full-Quran substitute for the canonical production `quran_core:1` resource. Do not mistake a successful prelive test for verification of all 114 Surahs / 6,236 Ayahs.

## What remains blocked

- No QF Developer Console account, client ID, approved production credentials, or backend deployment is available in this project workspace.
- No exact translation, tafsir, or transliteration edition has been selected and approved for the app's target audience.
- No qualified reviewer has certified the existing 22 draft Ayahs or any future Hinglish adaptation.
- The current bundled SQLite database is retained as the existing Arabic-text foundation. Do not populate missing Hinglish fields from AI-generated guesses or from an API response without following the provider's licence and storage rules.

## Official documentation

- Developer Terms: https://api-docs.quran.com/legal/developer-terms/
- Content Sync getting started: https://api-docs.quran.foundation/docs/tutorials/content-sync/getting-started/
- Offline cache patterns: https://api-docs.quran.com/docs/tutorials/content-sync/offline-cache-patterns/
- Connected Apps and attribution: https://api-docs.quran.foundation/docs/connected-apps/
