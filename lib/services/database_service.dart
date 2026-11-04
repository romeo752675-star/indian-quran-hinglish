import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/quran_models.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  static Database? _database;
  static Future<Database>? _databaseFuture;

  Future<Database> get database {
    if (_database != null) return Future.value(_database);
    _databaseFuture ??= _initDB('quran_hinglish_v3.db').then((db) {
      _database = db;
      return db;
    }).catchError((Object error) {
      _databaseFuture = null;
      throw error;
    });
    return _databaseFuture!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    if (!await databaseExists(path)) {
      await Directory(dirname(path)).create(recursive: true);
      final data = await rootBundle.load(join('assets', 'data', fileName));
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      final temporaryPath = '$path.tmp';
      await File(temporaryPath).writeAsBytes(bytes, flush: true);
      // Rename only after the complete asset has been written.
      await File(temporaryPath).rename(path);
    }

    final db = await openDatabase(path, readOnly: false);
    final integrity = await db.rawQuery('PRAGMA quick_check');
    if (integrity.isEmpty || integrity.first.values.first != 'ok') {
      await db.close();
      await deleteDatabase(path);
      throw StateError('The bundled Quran database failed its integrity check.');
    }
    await db.execute('''CREATE TABLE IF NOT EXISTS content_sources (surah_number INTEGER NOT NULL, number_in_surah INTEGER NOT NULL, source_name TEXT NOT NULL, source_url TEXT NOT NULL, license TEXT NOT NULL, reviewer_status TEXT NOT NULL, reviewer_note TEXT NOT NULL DEFAULT '', updated_at TEXT NOT NULL, PRIMARY KEY (surah_number, number_in_surah))''');
    final ayahColumns = await db.rawQuery('PRAGMA table_info(ayahs)');
    final columnNames = ayahColumns.map((row) => row['name']).toSet();
    if (!columnNames.contains('pronunciation_status')) {
      await db.execute("ALTER TABLE ayahs ADD COLUMN pronunciation_status TEXT NOT NULL DEFAULT 'pending_source'");
    }
    if (!columnNames.contains('pronunciation_source')) {
      await db.execute("ALTER TABLE ayahs ADD COLUMN pronunciation_source TEXT NOT NULL DEFAULT ''");
    }
    return db;
  }

  Future<List<SurahInfo>> getSurahs() async {
    final db = await database;
    final result = await db.query('surahs', orderBy: 'number ASC');
    return result.map((map) => SurahInfo.fromMap(map)).toList();
  }

  Future<List<Map<String, dynamic>>> searchAyahs(String query, {int limit = 100}) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    // Keep accidental or hostile limits from loading an unbounded result set.
    final safeLimit = limit.clamp(1, 250).toInt();
    final db = await database;
    final escaped = q.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_');
    final pattern = '%$escaped%';
    return db.rawQuery('''
      SELECT ayahs.*, surahs.english_name AS surah_english_name,
             surahs.arabic_name AS surah_arabic_name
      FROM ayahs
      INNER JOIN surahs ON surahs.number = ayahs.surah_number
      WHERE ayahs.arabic_text LIKE ? ESCAPE '\\' COLLATE NOCASE
         OR ayahs.transliteration LIKE ? ESCAPE '\\' COLLATE NOCASE
         OR ayahs.hinglish_translation LIKE ? ESCAPE '\\' COLLATE NOCASE
         OR surahs.english_name LIKE ? ESCAPE '\\' COLLATE NOCASE
         OR surahs.english_translation LIKE ? ESCAPE '\\' COLLATE NOCASE
         OR ayahs.tafsir LIKE ? ESCAPE '\\' COLLATE NOCASE
      ORDER BY ayahs.number_in_quran ASC
      LIMIT ?
    ''', [pattern, pattern, pattern, pattern, pattern, pattern, safeLimit]);
  }

  /// Applies only externally reviewed, source-attributed content. Arabic text and
  /// Ayah numbering are intentionally immutable through this sync pathway.
  Future<int> applyReviewedAyahContent(List<Map<String, dynamic>> records) async {
    final db = await database;
    var applied = 0;
    final seenAyahs = <String>{};
    await db.transaction((txn) async {
      for (final row in records) {
        final surah = int.tryParse('${row['surah_number'] ?? ''}');
        final ayah = int.tryParse('${row['number_in_surah'] ?? ''}');
        final source = (row['source_name'] ?? '').toString().trim();
        final sourceUrl = (row['source_url'] ?? '').toString().trim();
        final license = (row['license'] ?? '').toString().trim();
        final reviewer = (row['reviewer_status'] ?? '').toString();
        if (surah == null || ayah == null || surah < 1 || surah > 114 || ayah < 1 ||
            source.isEmpty || source.length > 200 || reviewer != 'approved' ||
            license.isEmpty || license.length > 500) {
          continue;
        }
        final parsedSourceUrl = Uri.tryParse(sourceUrl);
        if (parsedSourceUrl == null || parsedSourceUrl.scheme != 'https' || parsedSourceUrl.host.isEmpty) continue;
        final ayahKey = '$surah:$ayah';
        if (!seenAyahs.add(ayahKey)) continue;
        final transliteration = (row['transliteration'] ?? '').toString().trim();
        final meaning = (row['hinglish_translation'] ?? '').toString().trim();
        final tafsir = (row['tafsir'] ?? '').toString().trim();
        if (transliteration.isEmpty || meaning.isEmpty || tafsir.isEmpty ||
            transliteration.length > 2000 || meaning.length > 5000 || tafsir.length > 12000) continue;
        final exists = await txn.query('ayahs',
          columns: ['id'],
          where: 'surah_number = ? AND number_in_surah = ?',
          whereArgs: [surah, ayah],
          limit: 1,
        );
        if (exists.isEmpty) continue;
        final changed = await txn.update(
          'ayahs',
          {
            'transliteration': transliteration,
            'hinglish_translation': meaning,
            'tafsir': tafsir,
            'content_status': 'reviewed',
          },
          where: 'surah_number = ? AND number_in_surah = ?',
          whereArgs: [surah, ayah],
        );
        if (changed == 1) {
          await txn.insert('content_sources', {
            'surah_number': surah,
            'number_in_surah': ayah,
            'source_name': source,
            'source_url': sourceUrl,
            'license': license,
            'reviewer_status': reviewer,
            'reviewer_note': (row['reviewer_note'] ?? '').toString().substring(0, ((row['reviewer_note'] ?? '').toString().length).clamp(0, 2000).toInt()),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
          applied++;
        }
      }
    });
    return applied;
  }

  /// Imports source-provided word-by-word transliteration without claiming
  /// Hafiz approval. Existing non-empty drafts/reviewed text are never overwritten.
  Future<int> applySourcePronunciations({
    required List<Map<String, dynamic>> records,
    required String sourceName,
    required String sourceUrl,
    required String license,
  }) async {
    final db = await database;
    final parsedUrl = Uri.tryParse(sourceUrl);
    if (sourceName.trim().isEmpty || license.trim().isEmpty || parsedUrl == null ||
        parsedUrl.scheme != 'https' || parsedUrl.host.isEmpty || records.length > 6236) {
      throw const FormatException('Invalid pronunciation source manifest.');
    }
    var applied = 0;
    final seen = <String>{};
    await db.transaction((txn) async {
      for (final row in records) {
        final surah = int.tryParse('${row['surah_number'] ?? ''}');
        final ayah = int.tryParse('${row['number_in_surah'] ?? ''}');
        final text = (row['transliteration'] ?? '').toString().trim();
        final key = '$surah:$ayah';
        if (surah == null || surah < 1 || surah > 114 || ayah == null || ayah < 1 ||
            text.isEmpty || text.length > 2000 || !seen.add(key)) continue;
        final result = await txn.rawUpdate('''
          UPDATE ayahs SET transliteration = ?, pronunciation_status = 'source_unreviewed', pronunciation_source = ?
          WHERE surah_number = ? AND number_in_surah = ? AND (transliteration IS NULL OR TRIM(transliteration) = '')
        ''', [text, sourceName, surah, ayah]);
        applied += result;
      }
    });
    return applied;
  }

  Future<List<Ayah>> getAyahsForSurah(int surahNumber) async {
    final db = await database;
    final result = await db.query(
      'ayahs',
      where: 'surah_number = ?',
      whereArgs: [surahNumber],
      orderBy: 'number_in_surah ASC',
    );

    if (result.isEmpty) {
      throw StateError('No Ayahs found for Surah $surahNumber in the bundled Quran database.');
    }
    return result.map((map) => Ayah.fromMap(map)).toList();
  }
}
