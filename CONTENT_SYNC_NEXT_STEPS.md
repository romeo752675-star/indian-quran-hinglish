# Indian Quran — Content Sync next steps (current state)

## Prepared in this project
- Added a minimal Node.js gateway starter under `backend/qf_sync_backend/`.
- It keeps QF credentials on the backend, limits upstream routes to Content Sync sync/snapshot paths, and refuses requests until credentials are configured.
- This is a starter scaffold only. It is not deployed and does not yet sync records into the app database.

## What requires account-owner action
1. Create/register the app in Quran Foundation Developer Console.
2. Obtain production `client_id` and approved access/token flow.
3. Decide which translation, tafsir, transliteration, and recitation editions are suitable and permitted for this app. Resource IDs in docs are examples, not editorial recommendations.
4. Deploy the backend with HTTPS and backend-to-app authentication.

## Implementation still needed after credentials
- Implement token lifecycle and full Content Sync bootstrap/pagination/snapshot/mutation logic.
- Implement safe local cache updates and sync token persistence.
- Map selected source editions into the app's four separate fields.
- Confirm source terms permit the intended in-app display and offline behavior.
- Qualified review of Hinglish adaptation and Tafsir.

## Important limitation
Quran Foundation API content may be displayed in an app under its terms, but QF content must not be redistributed as a standalone dataset. Offline content must use Content Sync and remain updated at least every 7 days when connectivity permits. Prepackaged QF content is not automatically permitted just because Content Sync supports offline use.
