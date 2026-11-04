import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/content_sync_service.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  const SettingsScreen({super.key, required this.themeMode, required this.onThemeChanged});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ThemeMode _themeMode;
  double _arabic = 26;
  double _translation = 15;
  double _transliteration = 15;
  bool _loaded = false;
  bool _syncing = false;
  String? _syncMessage;
  bool _syncingPronunciation = false;
  String? _pronunciationMessage;

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.themeMode != widget.themeMode) {
      _themeMode = widget.themeMode;
    }
  }

  @override
  void initState() { super.initState(); _themeMode = widget.themeMode; _load(); }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _arabic = p.getDouble('arabicFontSize') ?? 26;
      _translation = p.getDouble('translationFontSize') ?? 15;
      _transliteration = p.getDouble('transliterationFontSize') ?? 15;
      _loaded = true;
    });
  }
  Future<void> _save(String key, double value) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(key, value);
  }

  Future<void> _syncContent() async {
    setState(() { _syncing = true; _syncMessage = null; });
    try {
      final count = await ContentSyncService.syncReviewedContent();
      if (mounted) setState(() => _syncMessage = '$count reviewed Ayah records updated.');
    } catch (error) {
      if (mounted) setState(() => _syncMessage = error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _syncPronunciations() async {
    setState(() { _syncingPronunciation = true; _pronunciationMessage = null; });
    try {
      final count = await ContentSyncService.syncSourcePronunciations();
      if (mounted) setState(() => _pronunciationMessage = '$count Ayah pronunciations imported. Source text still needs Hafiz review.');
    } catch (error) {
      if (mounted) setState(() => _pronunciationMessage = error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _syncingPronunciation = false);
    }
  }

  Widget _fontSlider(String title, double value, double min, double max, ValueChanged<double> changed) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))), Text('${value.round()} px')]),
      Slider(value: value, min: min, max: max, divisions: (max-min).round(), activeColor: const Color(0xFF1F594B), onChanged: changed),
    ],
  );

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF1F594B);
    return Scaffold(
      appBar: AppBar(title: const Text('App Settings')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        const Text('Appearance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(value: ThemeMode.light, label: Text('Light Green'), icon: Icon(Icons.wb_sunny_outlined)),
            ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined)),
            ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.settings_suggest_outlined)),
          ],
          selected: {_themeMode},
          onSelectionChanged: (selection) {
            final mode = selection.first;
            setState(() => _themeMode = mode);
            widget.onThemeChanged(mode);
          },
        ),
        const Divider(height: 28),
        const Text('Reading preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        if (!_loaded) const LinearProgressIndicator() else ...[
          _fontSlider('Arabic text size', _arabic, 20, 40, (v) { setState(() => _arabic=v); _save('arabicFontSize',v); }),
          _fontSlider('Hinglish meaning size', _translation, 12, 24, (v) { setState(() => _translation=v); _save('translationFontSize',v); }),
          _fontSlider('Roman pronunciation size', _transliteration, 12, 24, (v) { setState(() => _transliteration=v); _save('transliterationFontSize',v); }),
        ],
        const Divider(height: 28),
        const Text('Reviewed content updates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.sync, color: green),
          title: const Text('Check for reviewed content'),
          subtitle: Text(_syncMessage ?? 'Downloads only source-attributed content marked approved by a qualified reviewer.'),
          trailing: _syncing ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : IconButton(onPressed: _syncContent, icon: const Icon(Icons.download)),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.record_voice_over, color: green),
          title: const Text('Import Roman pronunciation'),
          subtitle: Text(_pronunciationMessage ?? 'Imports Quran.Foundation English word-by-word transliteration. Hafiz verification remains required.'),
          trailing: _syncingPronunciation ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : IconButton(onPressed: _syncPronunciations, icon: const Icon(Icons.download)),
        ),
        const Divider(height: 28),
        const ListTile(leading: Icon(Icons.language, color: green), title: Text('Language'), subtitle: Text('Simple Everyday Hinglish (Roman Script)')),
        const ListTile(leading: Icon(Icons.headphones, color: green), title: Text('Reciter'), subtitle: Text('Mishary Rashid Alafasy • Online streaming')),
        const ListTile(leading: Icon(Icons.offline_pin, color: green), title: Text('Offline reading'), subtitle: Text('Arabic Quran text and Surah catalogue are stored on this device. Audio requires internet.')),
        const ListTile(leading: Icon(Icons.info_outline, color: green), title: Text('Version & source'), subtitle: Text('v1.0.15 • Arabic text: Tanzil Quran Text (CC BY 3.0). Roman transliteration: Quran.Foundation.')),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quran text attribution', style: TextStyle(fontWeight: FontWeight.w800)),
                SizedBox(height: 6),
                Text('Tanzil Quran Text. Copyright (C) 2007-2021 Tanzil Project. License: Creative Commons Attribution 3.0. Text reproduced verbatim; it must not be modified. Source: tanzil.net.\n\nQuran data provided by Quran.Foundation. Word-by-word transliteration source: Quran.Foundation; used within the connected app under its Developer Terms.'),
              ],
            ),
          ),
        ),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8), child: Text('Content status: 6,214 Ayahs are awaiting review. The 22 existing text entries are drafts, not certified translations. Do not treat pending or draft text as verified religious guidance.', style: TextStyle(color: Colors.grey, height: 1.4))),
      ]),
    );
  }
}
