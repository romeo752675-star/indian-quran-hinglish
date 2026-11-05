import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quran_models.dart';
import '../services/database_service.dart';
import '../services/audio_service.dart';
import '../widgets/ayah_card.dart';

class ReaderScreen extends StatefulWidget {
  final SurahInfo surah;
  final int initialAyah;

  const ReaderScreen({
    super.key,
    required this.surah,
    this.initialAyah = 1,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late Future<List<Ayah>> _ayahsFuture;
  final Set<String> _bookmarkedKeys = {};
  double _arabicFontSize = 26.0;
  double _translationFontSize = 15.0;
  double _transliterationFontSize = 15.0;
  final GlobalKey _initialAyahKey = GlobalKey();
  bool _initialScrollDone = false;

  @override
  void initState() {
    super.initState();
    _ayahsFuture = DatabaseService.instance.getAyahsForSurah(widget.surah.number);
    _loadSettingsAndBookmarks();
    _saveLastRead(widget.surah.number, widget.surah.englishName, widget.initialAyah);
  }

  Future<void> _loadSettingsAndBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _arabicFontSize = prefs.getDouble('arabicFontSize') ?? 26.0;
      _translationFontSize = prefs.getDouble('translationFontSize') ?? 15.0;
      _transliterationFontSize = prefs.getDouble('transliterationFontSize') ?? 15.0;
      _bookmarkedKeys.addAll(prefs.getStringList('bookmarked_ayahs') ?? []);
    });
  }

  Future<void> _toggleBookmark(int ayahNum) async {
    final key = '${widget.surah.number}:$ayahNum';
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      if (_bookmarkedKeys.contains(key)) {
        _bookmarkedKeys.remove(key);
      } else {
        _bookmarkedKeys.add(key);
      }
    });
    await prefs.setStringList('bookmarked_ayahs', _bookmarkedKeys.toList());
  }

  Future<void> _saveLastRead(int surahNum, String surahName, int ayahNum) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastReadSurahName', surahName);
    await prefs.setInt('lastReadSurahNum', surahNum);
    await prefs.setInt('lastReadAyah', ayahNum);
  }

  @override
  Widget build(BuildContext context) {
    const brandGreen = Color(0xFF1F594B);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.surah.englishName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('${widget.surah.englishTranslation} • ${widget.surah.numberOfAyahs} Ayahs', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
      body: FutureBuilder<List<Ayah>>(
        future: _ayahsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: brandGreen));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading verses: ${snapshot.error}'));
          }

          final ayahs = snapshot.data ?? [];
          if (!_initialScrollDone && ayahs.isNotEmpty) {
            _initialScrollDone = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final target = _initialAyahKey.currentContext;
              if (mounted && target != null) Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 350), alignment: 0.08);
            });
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: brandGreen),
                child: Column(
                  children: [
                    Text(
                      widget.surah.arabicName,
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.surah.revelationType} • ${widget.surah.numberOfAyahs} Ayahs',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          tooltip: 'Previous Ayah',
                          color: Colors.white,
                          onPressed: () => QuranAudioService.instance.previous(),
                          icon: const Icon(Icons.skip_previous_rounded),
                        ),
                        FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: brandGreen,
                          ),
                          onPressed: () async {
                            final startIndex = ayahs.indexWhere((a) => a.numberInSurah == widget.initialAyah);
                            await QuranAudioService.instance.playQueue(ayahs, startIndex: startIndex < 0 ? 0 : startIndex);
                            final error = QuranAudioService.instance.playbackErrorNotifier.value;
                            if (mounted && error != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                            }
                          },
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Play Surah'),
                        ),
                        IconButton(
                          tooltip: 'Next Ayah',
                          color: Colors.white,
                          onPressed: () => QuranAudioService.instance.next(),
                          icon: const Icon(Icons.skip_next_rounded),
                        ),
                        const SizedBox(width: 4),
                        ValueListenableBuilder<QuranRepeatMode>(
                          valueListenable: QuranAudioService.instance.repeatModeNotifier,
                          builder: (context, mode, _) {
                            final label = switch (mode) {
                              QuranRepeatMode.off => 'Off',
                              QuranRepeatMode.all => 'Surah',
                              QuranRepeatMode.one => 'Ayah',
                            };
                            final icon = switch (mode) {
                              QuranRepeatMode.off => Icons.repeat,
                              QuranRepeatMode.all => Icons.repeat_on,
                              QuranRepeatMode.one => Icons.repeat_one,
                            };
                            return OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white70),
                              ),
                              onPressed: () {
                                final next = switch (mode) {
                                  QuranRepeatMode.off => QuranRepeatMode.all,
                                  QuranRepeatMode.all => QuranRepeatMode.one,
                                  QuranRepeatMode.one => QuranRepeatMode.off,
                                };
                                QuranAudioService.instance.setRepeatMode(next);
                              },
                              icon: Icon(icon, size: 18),
                              label: Text(label),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: ayahs.length,
                  itemBuilder: (context, index) {
                    final ayah = ayahs[index];
                    final isBookmarked = _bookmarkedKeys.contains('${widget.surah.number}:${ayah.numberInSurah}');

                    return AyahCard(
                      ayah: ayah,
                      arabicFontSize: _arabicFontSize,
                      translationFontSize: _translationFontSize,
                      transliterationFontSize: _transliterationFontSize,
                      isBookmarked: isBookmarked,
                      onBookmarkToggle: () => _toggleBookmark(ayah.numberInSurah),
                      key: ayah.numberInSurah == widget.initialAyah ? _initialAyahKey : ValueKey('ayah-${ayah.id}'),
                      onAyahRead: () => _saveLastRead(widget.surah.number, widget.surah.englishName, ayah.numberInSurah),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
