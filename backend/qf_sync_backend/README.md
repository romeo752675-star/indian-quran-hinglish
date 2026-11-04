# Quran Foundation Content Sync gateway and engine

Backend-only OAuth2 gateway plus a durable file-backed Content Sync engine. The Flutter app must never contain the QF client secret.

## Authentication

- Uses OAuth2 Client Credentials with `scope=content`.
- Caches access tokens; this flow has no refresh token.
- Retries one content request once after HTTP 401.
- Supports matching `prelive` and `production` credentials/hosts.

## Configure

1. Register a **Backend/server** app in Quran Foundation Developer Console and obtain credentials/permissions.
2. Copy `.env.example` to `.env` and configure `QF_ENV`, `QF_CLIENT_ID`, `QF_CLIENT_SECRET`.
3. Set a strong random `QF_SYNC_ADMIN_KEY`.
4. Set `QF_SYNC_RESOURCES` to the exact resource IDs approved and confirmed for the app. Do not copy example IDs blindly; verify language, license, public availability, and permissions first.
5. Set `QF_SYNC_DATA_DIR` to persistent writable storage.
6. Run with Node.js 20+: `node server.mjs`.

## Routes

- `GET /health` reports configuration only; it never exposes credentials.
- `GET /qf/resources/sync?...` and `GET /qf/resources/snapshots/...` proxy the documented read-only QF endpoints.
- `POST /sync/run` executes a full bootstrap or incremental sync. Requires `Authorization: Bearer $QF_SYNC_ADMIN_KEY`.

Example:

```sh
curl -X POST http://localhost:8787/sync/run \
  -H "Authorization: Bearer $QF_SYNC_ADMIN_KEY"
```

## Sync behavior

- Bootstrap automatically when there is no checkpoint or the configured resource filter changes.
- Follows every `next_page_url` until `has_more` is false.
- Fetches full snapshots for resource create/invalidate events and replaces that resource's local JSON copy.
- Applies row create/update/delete and resource delete/update events idempotently.
- Writes `next_sync_token` only after all pages and all snapshots/mutations have succeeded.
- Stores the resource filter with the checkpoint; a changed filter triggers a fresh bootstrap.
- State and resource snapshots are written atomically to the configured data directory.

This engine is a backend sync/cache foundation. It does not yet migrate these JSON snapshots into the Flutter SQLite database; that adapter and app-side scheduled sync remain separate integration work. Do not treat prelive as a complete Quran dataset: official docs state prelive contains only Surah 1 and 2. Use production after production access is approved.

Official docs:
- https://api-docs.quran.foundation/docs/quickstart/
- https://api-docs.quran.foundation/docs/tutorials/content-sync/getting-started/

## App-side reviewed content delivery

`GET /app/ayah-content` serves the publisher-controlled `reviewed-ayah-content.json` manifest (path configurable with `QF_REVIEWED_CONTENT_FILE`). The Flutter client can fetch it when built with `--dart-define=CONTENT_SYNC_BASE_URL=https://your-domain`. The client only applies records with `reviewer_status: "approved"`, non-empty transliteration/meaning/Tafsir and source metadata. It never overwrites Arabic text or Ayah numbering. The included `.example.json` is a schema example only and contains no Quran content. Do not mark records approved until a qualified reviewer has checked them and redistribution rights are documented.

The Quran Foundation Content Sync snapshots remain raw upstream resources. Their resource-specific schemas must be mapped and licensed/approved before being transformed into this reviewed manifest; the backend deliberately does not guess that mapping.
