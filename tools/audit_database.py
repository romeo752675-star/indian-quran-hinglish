#!/usr/bin/env python3
"""Read-only structural audit for the bundled Quran SQLite database."""
import sqlite3
from pathlib import Path

DB = Path(__file__).resolve().parents[1] / 'assets' / 'data' / 'quran_hinglish_v3.db'
con = sqlite3.connect(DB)
try:
    integrity = con.execute('PRAGMA integrity_check').fetchone()[0]
    surahs = con.execute('SELECT COUNT(*) FROM surahs').fetchone()[0]
    ayahs = con.execute('SELECT COUNT(*) FROM ayahs').fetchone()[0]
    min_no, max_no, distinct_no = con.execute(
        'SELECT MIN(number_in_quran), MAX(number_in_quran), COUNT(DISTINCT number_in_quran) FROM ayahs'
    ).fetchone()
    mismatches = con.execute('''
        SELECT COUNT(*) FROM (
          SELECT s.number FROM surahs s LEFT JOIN ayahs a ON a.surah_number=s.number
          GROUP BY s.number HAVING COUNT(a.id) != s.number_of_ayahs
        )
    ''').fetchone()[0]
    statuses = dict(con.execute('SELECT content_status, COUNT(*) FROM ayahs GROUP BY content_status'))
    empty_fields = con.execute('''
        SELECT
          SUM(CASE WHEN TRIM(COALESCE(transliteration,''))='' THEN 1 ELSE 0 END),
          SUM(CASE WHEN TRIM(COALESCE(hinglish_translation,''))='' THEN 1 ELSE 0 END),
          SUM(CASE WHEN TRIM(COALESCE(tafsir,''))='' THEN 1 ELSE 0 END)
        FROM ayahs
    ''').fetchone()
    print(f'Database: {DB}')
    print(f'SQLite integrity: {integrity}')
    print(f'Surahs: {surahs}; Ayahs: {ayahs}')
    print(f'Global numbering: min={min_no}, max={max_no}, unique={distinct_no}')
    print(f'Surah count mismatches: {mismatches}')
    print(f'Content status counts: {statuses}')
    print(f'Empty transliteration/translation/tafsir counts: {empty_fields}')
    if integrity != 'ok' or surahs != 114 or ayahs != 6236 or (min_no, max_no, distinct_no) != (1, 6236, 6236) or mismatches:
        raise SystemExit('AUDIT FAILED')
    print('STRUCTURAL AUDIT PASSED')
finally:
    con.close()
