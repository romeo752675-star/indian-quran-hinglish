import 'package:flutter_test/flutter_test.dart';
import 'package:indian_quran/models/quran_models.dart';

void main() {
  test('SurahInfo model test', () {
    final surah = SurahInfo(
      number: 1,
      arabicName: 'الفاتحة',
      englishName: 'Al-Fatihah',
      englishTranslation: 'The Opening',
      numberOfAyahs: 7,
      revelationType: 'Meccan',
    );
    expect(surah.number, 1);
    expect(surah.numberOfAyahs, 7);
    expect(surah.englishName, 'Al-Fatihah');
  });

  test('Ayah model preserves content verification status', () {
    final ayah = Ayah.fromMap({
      'id': 1,
      'surah_number': 1,
      'number_in_surah': 1,
      'number_in_quran': 1,
      'arabic_text': 'بِسْمِ اللَّهِ',
      'transliteration': 'Bismillah',
      'hinglish_translation': 'Allah ke naam se',
      'tafsir': 'Draft explanation',
      'audio_url': '',
      'content_status': 'existing_draft_needs_review',
    });
    expect(ayah.contentStatus, 'existing_draft_needs_review');
    expect(ayah.numberInQuran, 1);
  });
}
