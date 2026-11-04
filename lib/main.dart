import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/audio_service.dart';
import 'screens/home_screen.dart';
import 'screens/surah_list_screen.dart';
import 'screens/bookmarks_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  QuranAudioService.instance.init();
  runApp(const IndianQuranApp());
}

class IndianQuranApp extends StatefulWidget {
  const IndianQuranApp({super.key});

  @override
  State<IndianQuranApp> createState() => _IndianQuranAppState();
}

class _IndianQuranAppState extends State<IndianQuranApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadThemeSetting();
  }

  Future<void> _loadThemeSetting() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      final saved = prefs.getString('themeMode') ?? 'light';
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == saved,
        orElse: () => ThemeMode.light,
      );
    });
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.name);
  }

  @override
  Widget build(BuildContext context) {
    const brandInk = Color(0xFF173D35);
    const brandGreen = Color(0xFF1F594B);
    const brandCream = Color(0xFFF4F8F0);
    const softGreen = Color(0xFFDCEBDD);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Indian Quran (in Hinglish)',
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: brandCream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F8B62),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: brandCream,
          foregroundColor: brandInk,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: softGreen, width: 1),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandGreen,
          brightness: Brightness.dark,
        ),
      ),
      home: MainShell(
        themeMode: _themeMode,
        onThemeChanged: _setThemeMode,
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  const MainShell({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentTab = 0;
  int _bookmarkRefreshToken = 0;

  @override
  Widget build(BuildContext context) {
    const brandGreen = Color(0xFF1F594B);

    final pages = [
      HomeScreen(
        onNavigateToSurahs: () => setState(() => _currentTab = 1),
        onOpenSettings: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SettingsScreen(
                themeMode: widget.themeMode,
                onThemeChanged: widget.onThemeChanged,
              ),
            ),
          );
        },
      ),
      const SurahListScreen(),
      BookmarksScreen(key: ValueKey(_bookmarkRefreshToken)),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentTab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (idx) => setState(() {
          _currentTab = idx;
          if (idx == 2) _bookmarkRefreshToken++;
        }),
        indicatorColor: const Color(0xFFDCEBDD),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: brandGreen),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book, color: brandGreen),
            label: 'Surahs',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark, color: brandGreen),
            label: 'Bookmarks',
          ),
        ],
      ),
    );
  }
}
