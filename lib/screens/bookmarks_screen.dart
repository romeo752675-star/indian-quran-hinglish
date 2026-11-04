import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quran_models.dart';
import '../services/database_service.dart';
import 'reader_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<String> _bookmarkedKeys = [];
  bool _isLoading = true;
  late Future<List<SurahInfo>> _surahsFuture;

  @override
  void initState() {
    super.initState();
    _surahsFuture = DatabaseService.instance.getSurahs();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _bookmarkedKeys = prefs.getStringList('bookmarked_ayahs') ?? [];
      _isLoading = false;
    });
  }

  Future<void> _removeBookmark(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _bookmarkedKeys.remove(key);
    });
    await prefs.setStringList('bookmarked_ayahs', _bookmarkedKeys);
  }

  @override
  Widget build(BuildContext context) {
    const brandGreen = Color(0xFF1F594B);
    const brandGold = Color(0xFFC7A45A);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bookmarked Ayat',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            const Text('Your saved verses for quick reflection', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: brandGreen))
                : _bookmarkedKeys.isEmpty
                    ? const Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bookmark_border, size: 54, color: brandGold),
                              SizedBox(height: 12),
                              Text('No bookmarked Ayat yet', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      )
                    : Expanded(
                        child: ListView.separated(
                          itemCount: _bookmarkedKeys.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final key = _bookmarkedKeys[index];
                            final parts = key.split(':');
                            final surahNum = int.tryParse(parts[0]) ?? 1;
                            final ayahNum = int.tryParse(parts.length > 1 ? parts[1] : '1') ?? 1;

                            return FutureBuilder<List<SurahInfo>>(
                              future: _surahsFuture,
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const SizedBox.shrink();
                                final surahs = snapshot.data!;
                                final surah = surahs.firstWhere(
                                  (s) => s.number == surahNum,
                                  orElse: () => surahs.first,
                                );

                                return Card(
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: Color(0xFFE9E2D0),
                                      child: Icon(Icons.bookmark, color: brandGreen),
                                    ),
                                    title: Text(
                                      '${surah.englishName} (Surah $surahNum)',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text('Ayah $ayahNum'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      onPressed: () => _removeBookmark(key),
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ReaderScreen(
                                            surah: surah,
                                            initialAyah: ayahNum,
                                          ),
                                        ),
                                      ).then((_) => _loadBookmarks());
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ],
        ),
      ),
    );
  }
}
