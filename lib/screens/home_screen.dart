import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import 'reader_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToSurahs;
  final VoidCallback onOpenSettings;

  const HomeScreen({
    super.key,
    required this.onNavigateToSurahs,
    required this.onOpenSettings,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _lastReadSurahName = 'Al-Fatihah';
  int _lastReadSurahNum = 1;
  int _lastReadAyah = 1;
  bool _isLoadingLastRead = true;

  static const deepGreen = Color(0xFF174D3B);
  static const leafGreen = Color(0xFF4F8B62);
  static const paleGreen = Color(0xFFE8F3E7);
  static const gold = Color(0xFFC6A45A);
  static const ink = Color(0xFF183B30);

  @override
  void initState() {
    super.initState();
    _loadLastRead();
  }

  Future<void> _loadLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _lastReadSurahName = prefs.getString('lastReadSurahName') ?? 'Al-Fatihah';
      _lastReadSurahNum = prefs.getInt('lastReadSurahNum') ?? 1;
      _lastReadAyah = prefs.getInt('lastReadAyah') ?? 1;
      _isLoadingLastRead = false;
    });
  }

  Future<void> _continueReading() async {
    final surahs = await DatabaseService.instance.getSurahs();
    if (surahs.isEmpty || !mounted) return;
    final surah = surahs.firstWhere(
      (s) => s.number == _lastReadSurahNum,
      orElse: () => surahs.first,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderScreen(surah: surah, initialAyah: _lastReadAyah),
      ),
    ).then((_) => _loadLastRead());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : ink;
    final cardColor = isDark ? const Color(0xFF1E3028) : Colors.white;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [deepGreen, leafGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.menu_book_rounded, color: gold, size: 27),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('INDIAN QURAN', style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900,
                      letterSpacing: 1.35, color: textColor,
                    )),
                    Text('Quran ko aasaan Hinglish mein samjhein',
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Search Quran',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                icon: Icon(Icons.search_rounded, color: textColor),
              ),
              IconButton(
                tooltip: 'Settings',
                onPressed: widget.onOpenSettings,
                icon: Icon(Icons.tune_rounded, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Assalamu Alaikum', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: textColor)),
          const SizedBox(height: 4),
          Text('Aaj Quran ki tilawat aur samajh ke liye waqt nikalein.', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF174D3B), Color(0xFF397957), Color(0xFF65996C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(color: deepGreen.withOpacity(0.18), blurRadius: 20, offset: const Offset(0, 9)),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -12, top: -18,
                  child: Icon(Icons.mosque_rounded, size: 112, color: Colors.white.withOpacity(0.08)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withOpacity(0.18)),
                      ),
                      child: const Text('YOUR QURAN COMPANION',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
                    ),
                    const SizedBox(height: 18),
                    const Text('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(color: Colors.white, fontSize: 25, height: 1.9, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    const Text(
                      'Allah ke naam se shuru, jo bahut meherbaan aur baar-baar reham karne wala hai.',
                      style: TextStyle(color: Colors.white, fontSize: 13, height: 1.55),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: widget.onNavigateToSurahs,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE5D09A),
                        foregroundColor: deepGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.auto_stories_rounded, size: 18),
                      label: const Text('Explore all Surahs', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: _StatCard(value: '114', label: 'Surahs', icon: Icons.menu_book_rounded, cardColor: cardColor, textColor: textColor)),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(value: '6,236', label: 'Ayahs', icon: Icons.format_list_numbered_rounded, cardColor: cardColor, textColor: textColor)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Text('Continue reading', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor))),
              TextButton(onPressed: widget.onNavigateToSurahs, child: const Text('All Surahs')),
            ],
          ),
          const SizedBox(height: 8),
          _isLoadingLastRead
              ? const Center(child: Padding(padding: EdgeInsets.all(18), child: CircularProgressIndicator(color: leafGreen)))
              : Material(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(19),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(19),
                    onTap: _continueReading,
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        children: [
                          Container(
                            width: 46, height: 46,
                            decoration: BoxDecoration(color: paleGreen, borderRadius: BorderRadius.circular(14)),
                            child: const Icon(Icons.play_arrow_rounded, color: deepGreen, size: 29),
                          ),
                          const SizedBox(width: 13),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_lastReadSurahName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor)),
                              const SizedBox(height: 3),
                              Text('Surah $_lastReadSurahNum  •  Ayah $_lastReadAyah',
                                style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
                            ],
                          )),
                          const Icon(Icons.chevron_right_rounded, color: leafGreen),
                        ],
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 22),
          Text('Made for easy understanding', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor)),
          const SizedBox(height: 10),
          _InfoTile(icon: Icons.record_voice_over_rounded, title: 'Roman pronunciation', subtitle: 'Read Arabic pronunciation in Roman letters.', cardColor: cardColor, textColor: textColor),
          _InfoTile(icon: Icons.translate_rounded, title: 'Simple Hinglish meaning', subtitle: 'Everyday language, kept separate from explanation.', cardColor: cardColor, textColor: textColor),
          _InfoTile(icon: Icons.lightbulb_outline_rounded, title: 'Aasaan Samajh', subtitle: 'A separate explanation section for each Ayah.', cardColor: cardColor, textColor: textColor),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF26382E) : const Color(0xFFF0F6E9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFDCE9D6)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_outlined, color: leafGreen, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'Arabic Quran text is available offline. Hinglish pronunciation, meaning and explanation are being reviewed; unverified content is clearly marked.',
                  style: TextStyle(fontSize: 11, height: 1.45, color: isDark ? Colors.white70 : ink),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color cardColor;
  final Color textColor;

  const _StatCard({required this.value, required this.label, required this.icon, required this.cardColor, required this.textColor});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFDCE9D6))),
    child: Row(children: [
      Icon(icon, color: const Color(0xFF4F8B62), size: 23),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: textColor)),
        Text(label, style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.65))),
      ]),
    ]),
  );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color cardColor;
  final Color textColor;

  const _InfoTile({required this.icon, required this.title, required this.subtitle, required this.cardColor, required this.textColor});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFDCE9D6))),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      leading: Container(width: 40, height: 40,
        decoration: BoxDecoration(color: const Color(0xFFE8F3E7), borderRadius: BorderRadius.circular(13)),
        child: Icon(icon, color: const Color(0xFF286044), size: 21)),
      title: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.62))),
    ),
  );
}
