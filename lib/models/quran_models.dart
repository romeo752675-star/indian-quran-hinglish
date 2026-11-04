class SurahInfo {
  final int number;
  final String arabicName;
  final String englishName;
  final String englishTranslation;
  final int numberOfAyahs;
  final String revelationType;

  const SurahInfo({
    required this.number,
    required this.arabicName,
    required this.englishName,
    required this.englishTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
  });

  factory SurahInfo.fromMap(Map<String, dynamic> map) {
    return SurahInfo(
      number: map['number'] ?? 0,
      arabicName: map['arabic_name'] ?? '',
      englishName: map['english_name'] ?? '',
      englishTranslation: map['english_translation'] ?? '',
      numberOfAyahs: map['number_of_ayahs'] ?? 0,
      revelationType: map['revelation_type'] ?? 'Meccan',
    );
  }

  Map<String, dynamic> toMap() => {
    'number': number,
    'arabic_name': arabicName,
    'english_name': englishName,
    'english_translation': englishTranslation,
    'number_of_ayahs': numberOfAyahs,
    'revelation_type': revelationType,
  };
}

class Ayah {
  final int id;
  final int surahNumber;
  final int numberInSurah;
  final int numberInQuran;
  final String arabicText;
  final String transliteration;
  final String hinglishTranslation;
  final String? tafsir;
  final String audioUrl;
  final String contentStatus;
  final String pronunciationStatus;
  final String pronunciationSource;

  const Ayah({
    required this.id,
    required this.surahNumber,
    required this.numberInSurah,
    required this.numberInQuran,
    required this.arabicText,
    required this.transliteration,
    required this.hinglishTranslation,
    this.tafsir,
    required this.audioUrl,
    this.contentStatus = 'pending_review',
    this.pronunciationStatus = 'pending_source',
    this.pronunciationSource = '',
  });

  factory Ayah.fromMap(Map<String, dynamic> map) {
    return Ayah(
      id: map['id'] ?? 0,
      surahNumber: map['surah_number'] ?? 0,
      numberInSurah: map['number_in_surah'] ?? 0,
      numberInQuran: map['number_in_quran'] ?? 0,
      arabicText: map['arabic_text'] ?? '',
      transliteration: map['transliteration'] ?? '',
      hinglishTranslation: map['hinglish_translation'] ?? '',
      tafsir: map['tafsir'],
      audioUrl: map['audio_url'] ?? '',
      contentStatus: map['content_status'] ?? 'pending_review',
      pronunciationStatus: map['pronunciation_status'] ?? 'pending_source',
      pronunciationSource: map['pronunciation_source'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'surah_number': surahNumber,
    'number_in_surah': numberInSurah,
    'number_in_quran': numberInQuran,
    'arabic_text': arabicText,
    'transliteration': transliteration,
    'hinglish_translation': hinglishTranslation,
    'tafsir': tafsir,
    'audio_url': audioUrl,
    'content_status': contentStatus,
    'pronunciation_status': pronunciationStatus,
    'pronunciation_source': pronunciationSource,
  };
}
