import 'package:flutter/material.dart';
import '../models/quran_models.dart';
import '../services/database_service.dart';
import 'reader_screen.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  late Future<List<SurahInfo>> _surahsFuture;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _surahsFuture = DatabaseService.instance.getSurahs();
  }

  @override
  Widget build(BuildContext context) {
    const brandInk = Color(0xFF173D35);
    const brandGreen = Color(0xFF1F594B);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'All 114 Surahs',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: brandInk,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Browse the Quran • 114 Surahs',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: brandGreen),
                    hintText: 'Search by Surah name or number...',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    suffixIcon: _searchQuery.isEmpty ? null : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<SurahInfo>>(
              future: _surahsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: brandGreen));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading Surahs: ${snapshot.error}'));
                }

                final allSurahs = snapshot.data ?? [];
                final filtered = allSurahs.where((s) {
                  final q = _searchQuery.toLowerCase();
                  return s.englishName.toLowerCase().contains(q) ||
                      s.englishTranslation.toLowerCase().contains(q) ||
                      s.arabicName.contains(q) ||
                      s.number.toString() == q;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No Surahs found matching your search.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final surah = filtered[index];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReaderScreen(surah: surah),
                            ),
                          );
                        },
                        leading: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE4F1E4),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${surah.number}',
                            style: const TextStyle(
                              color: brandGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        title: Text(
                          surah.englishName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          '${surah.englishTranslation} • ${surah.numberOfAyahs} Ayahs • ${surah.revelationType}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          surah.arabicName,
                          style: const TextStyle(
                            fontSize: 20,
                            color: brandGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
