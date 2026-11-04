import 'dart:async';
import 'package:flutter/material.dart';
import '../models/quran_models.dart';
import '../services/database_service.dart';
import 'reader_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  String? _error;
  int _searchRequestId = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final requestId = ++_searchRequestId;
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() { _results = []; _loading = false; _error = null; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final rows = await DatabaseService.instance.searchAyahs(value);
        if (!mounted || requestId != _searchRequestId) return;
        setState(() { _results = rows; _loading = false; });
      } catch (e) {
        if (!mounted || requestId != _searchRequestId) return;
        setState(() { _error = 'Search could not be completed.'; _loading = false; });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF1F594B);
    return Scaffold(
      appBar: AppBar(title: const Text('Search Quran')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: TextField(
            controller: _controller,
            autofocus: true,
            onChanged: _onChanged,
            decoration: InputDecoration(
              hintText: 'Search Arabic, Roman or Hinglish...',
              prefixIcon: const Icon(Icons.search, color: green),
              suffixIcon: _controller.text.isEmpty ? null : IconButton(
                onPressed: () { _controller.clear(); _onChanged(''); },
                icon: const Icon(Icons.close),
              ),
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
        ),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        if (_error != null) Padding(padding: const EdgeInsets.all(16), child: Text(_error!)),
        Expanded(child: _controller.text.trim().isEmpty
          ? const Center(child: Text('Search Surah names, Arabic, pronunciation, Hinglish meaning or Tafsir.'))
          : _results.isEmpty && !_loading
            ? const Center(child: Text('No matching Ayahs found.'))
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _results.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final row = _results[index];
                  final surahNum = row['surah_number'] as int;
                  final ayahNum = row['number_in_surah'] as int;
                  return Card(child: ListTile(
                    title: Text('${row['surah_english_name']} • Ayah $ayahNum', style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text((row['arabic_text'] ?? '').toString(), textDirection: TextDirection.rtl, textAlign: TextAlign.right, style: const TextStyle(fontSize: 20, height: 1.7)),
                      if ((row['transliteration'] ?? '').toString().trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          row['transliteration'].toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87),
                        ),
                      ],
                      if ((row['hinglish_translation'] ?? '').toString().trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(row['hinglish_translation'].toString(), maxLines: 3, overflow: TextOverflow.ellipsis),
                      ] else
                        const Text('Hinglish meaning pending review', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      if ((row['tafsir'] ?? '').toString().trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Aasaan Samajh: ${row['tafsir']}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: green),
                        ),
                      ],
                      if ((row['content_status'] ?? 'pending_review') != 'verified')
                        const Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Text(
                            'Content review pending',
                            style: TextStyle(fontSize: 11, color: Colors.deepOrange),
                          ),
                        ),
                    ]),
                    trailing: const Icon(Icons.chevron_right, color: green),
                    onTap: () async {
                      final surahs = await DatabaseService.instance.getSurahs();
                      if (!context.mounted) return;
                      final surah = surahs.firstWhere((s) => s.number == surahNum);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ReaderScreen(surah: surah, initialAyah: ayahNum)));
                    },
                  ));
                },
              )),
      ]),
    );
  }
}
