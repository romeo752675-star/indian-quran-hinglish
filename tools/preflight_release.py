#!/usr/bin/env python3
"""Read-only pre-release checks for the Indian Quran Flutter source project."""
from __future__ import annotations

import csv
import re
import sqlite3
import sys
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
DB = ROOT / 'assets' / 'data' / 'quran_hinglish_v3.db'
QUEUE = ROOT / 'content_review_queue.csv'
PUBSPEC = ROOT / 'pubspec.yaml'
SETTINGS = ROOT / 'lib' / 'screens' / 'settings_screen.dart'

errors: list[str] = []
notes: list[str] = []

def check(condition: bool, message: str) -> None:
    (notes if condition else errors).append(('PASS: ' if condition else 'FAIL: ') + message)

check(DB.is_file(), 'Bundled Quran SQLite database exists')
check(QUEUE.is_file(), 'Per-Ayah content review queue exists')
check(PUBSPEC.is_file(), 'Flutter pubspec exists')

if DB.is_file():
    con = sqlite3.connect(DB)
    try:
        integrity = con.execute('PRAGMA integrity_check').fetchone()[0]
        check(integrity == 'ok', f'SQLite integrity_check = {integrity}')
        tables = {r[0] for r in con.execute("SELECT name FROM sqlite_master WHERE type='table'")}
        check({'surahs', 'ayahs'}.issubset(tables), 'Required surahs and ayahs tables exist')
        if {'surahs', 'ayahs'}.issubset(tables):
            surahs = con.execute('SELECT COUNT(*) FROM surahs').fetchone()[0]
            ayahs = con.execute('SELECT COUNT(*) FROM ayahs').fetchone()[0]
            check(surahs == 114, f'Surah count = {surahs} (expected 114)')
            check(ayahs == 6236, f'Ayah count = {ayahs} (expected 6,236)')
            bounds = con.execute('SELECT MIN(number_in_quran), MAX(number_in_quran), COUNT(DISTINCT number_in_quran) FROM ayahs').fetchone()
            check(bounds == (1, 6236, 6236), f'Global Ayah numbering is contiguous and unique: {bounds}')
            empty_arabic = con.execute("SELECT COUNT(*) FROM ayahs WHERE TRIM(COALESCE(arabic_text,''))=''").fetchone()[0]
            check(empty_arabic == 0, f'Arabic text has no empty rows ({empty_arabic})')
            mismatch = con.execute('''SELECT COUNT(*) FROM (SELECT s.number FROM surahs s LEFT JOIN ayahs a ON a.surah_number=s.number GROUP BY s.number HAVING COUNT(a.id) != s.number_of_ayahs)''').fetchone()[0]
            check(mismatch == 0, f'Surah-to-Ayah counts match ({mismatch} mismatches)')
            statuses = dict(con.execute('SELECT content_status, COUNT(*) FROM ayahs GROUP BY content_status'))
            check(statuses.get('existing_draft_needs_review', 0) == 22, f'Unverified draft rows remain explicitly marked: {statuses.get("existing_draft_needs_review", 0)}')
            check(statuses.get('pending_review', 0) == 6214, f'Pending rows are not silently presented as complete: {statuses.get("pending_review", 0)}')
            bad_verified = con.execute("SELECT COUNT(*) FROM ayahs WHERE content_status='verified' AND (TRIM(COALESCE(transliteration,''))='' OR TRIM(COALESCE(hinglish_translation,''))='' OR TRIM(COALESCE(tafsir,''))='')").fetchone()[0]
            check(bad_verified == 0, f'No verified row has a missing content field ({bad_verified})')
            audio_total, https_total = con.execute("SELECT COUNT(*), SUM(CASE WHEN audio_url LIKE 'https://%' THEN 1 ELSE 0 END) FROM ayahs").fetchone()
            check(audio_total == 6236 and https_total == 6236, f'All {https_total or 0}/{audio_total} audio URL fields use HTTPS (reachability/rights NOT tested)')
    finally:
        con.close()

if QUEUE.is_file() and DB.is_file():
    with QUEUE.open(encoding='utf-8-sig', newline='') as f:
        rows = list(csv.DictReader(f))
    check(len(rows) == 6236, f'Content review queue contains {len(rows)} Ayah rows')
    if len(rows) == 6236:
        keys = [(r.get('surah_number'), r.get('ayah_number')) for r in rows]
        check(len(set(keys)) == 6236, 'Content review queue has unique Surah/Ayah keys')
        required = {'source_title', 'translator_or_author', 'source_url', 'licence_or_permission', 'reviewer', 'review_date'}
        check(required.issubset(rows[0].keys()), 'Review queue tracks source, rights and reviewer metadata')

if PUBSPEC.is_file():
    pub = PUBSPEC.read_text(encoding='utf-8')
    match = re.search(r'^version:\s*(\S+)', pub, re.M)
    check(bool(match), f'Flutter package version declared: {match.group(1) if match else "missing"}')
    check('assets/data/' in pub, 'Bundled database asset directory declared in pubspec')

if SETTINGS.is_file():
    settings = SETTINGS.read_text(encoding='utf-8')
    check('Tanzil Quran Text' in settings, 'In-app Arabic text attribution is present')
    check('6,214 Ayahs' in settings, 'In-app pending-content disclosure is present')

for line in notes + errors:
    print(line)
print(f'\nSummary: {len(notes)} passed, {len(errors)} failed.')
print('Note: this is a data/source preflight only. It does not compile Flutter, test a device, verify audio reachability/rights, or certify religious content.')
sys.exit(1 if errors else 0)
