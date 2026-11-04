import 'dart:convert';
import 'package:http/http.dart' as http;
import 'database_service.dart';

/// Downloads a publisher-controlled, reviewer-approved content manifest.
/// Set CONTENT_SYNC_BASE_URL at build time; never put Quran Foundation secrets
/// or the backend admin key in the mobile application.
class ContentSyncService {
  static const String baseUrl = String.fromEnvironment('CONTENT_SYNC_BASE_URL');

  static Future<int> syncSourcePronunciations() async {
    if (baseUrl.isEmpty) {
      throw StateError('Content sync server is not configured for this build.');
    }
    final parsedBase = Uri.tryParse(baseUrl);
    if (parsedBase == null || parsedBase.scheme != 'https' || parsedBase.host.isEmpty) {
      throw StateError('Content sync server must use a valid HTTPS URL.');
    }
    final response = await http.get(
      parsedBase.resolve('/app/ayah-pronunciation'),
      headers: {'accept': 'application/json'},
    ).timeout(const Duration(seconds: 45));
    if (response.statusCode != 200) {
      throw StateError('Pronunciation source is not ready (HTTP ${response.statusCode}).');
    }
    if (response.bodyBytes.length > 15 * 1024 * 1024) {
      throw const FormatException('Pronunciation manifest exceeds the 15 MB safety limit.');
    }
    final payload = jsonDecode(utf8.decode(response.bodyBytes));
    if (payload is! Map || payload['schema_version'] != 1 || payload['records'] is! List ||
        payload['source_name'] is! String || payload['source_url'] is! String || payload['license'] is! String) {
      throw const FormatException('Unsupported pronunciation manifest.');
    }
    final rawRecords = payload['records'] as List;
    if (rawRecords.length > 6236 || rawRecords.any((row) => row is! Map)) {
      throw const FormatException('Pronunciation manifest contains invalid records.');
    }
    final records = rawRecords.map((row) => Map<String, dynamic>.from(row as Map)).toList(growable: false);
    return DatabaseService.instance.applySourcePronunciations(
      records: records,
      sourceName: payload['source_name'] as String,
      sourceUrl: payload['source_url'] as String,
      license: payload['license'] as String,
    );
  }

  static Future<int> syncReviewedContent() async {
    if (baseUrl.isEmpty) {
      throw StateError('Content sync server is not configured for this build.');
    }
    final parsedBase = Uri.tryParse(baseUrl);
    if (parsedBase == null || parsedBase.scheme != 'https' || parsedBase.host.isEmpty) {
      throw StateError('Content sync server must use a valid HTTPS URL.');
    }
    final uri = parsedBase.resolve('/app/ayah-content');
    final response = await http.get(uri, headers: {'accept': 'application/json'}).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw StateError('Content sync server returned HTTP ${response.statusCode}.');
    }
    if (response.bodyBytes.length > 15 * 1024 * 1024) {
      throw const FormatException('Content sync manifest exceeds the 15 MB safety limit.');
    }
    final payload = jsonDecode(utf8.decode(response.bodyBytes));
    if (payload is! Map || payload['schema_version'] != 1 || payload['records'] is! List) {
      throw const FormatException('Unsupported content sync payload.');
    }
    final rawRecords = payload['records'] as List;
    if (rawRecords.length > 6236) {
      throw const FormatException('Content sync manifest contains more records than the Quran.');
    }
    if (rawRecords.any((row) => row is! Map)) {
      throw const FormatException('Content sync manifest contains an invalid record.');
    }
    final records = rawRecords
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
    return DatabaseService.instance.applyReviewedAyahContent(records);
  }
}
