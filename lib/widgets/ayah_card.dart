import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/quran_models.dart';
import '../services/audio_service.dart';

class AyahCard extends StatefulWidget {
  final Ayah ayah;
  final double arabicFontSize;
  final double translationFontSize;
  final double transliterationFontSize;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onAyahRead;

  const AyahCard({
    super.key,
    required this.ayah,
    required this.arabicFontSize,
    required this.translationFontSize,
    required this.transliterationFontSize,
    required this.isBookmarked,
    required this.onBookmarkToggle,
    required this.onAyahRead,
  });

  @override
  State<AyahCard> createState() => _AyahCardState();
}

class _AyahCardState extends State<AyahCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const brandInk = Color(0xFF173D35);
    const brandGreen = Color(0xFF1F594B);
    const brandGold = Color(0xFFC7A45A);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: widget.onAyahRead,
        child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFE9E2D0),
                  child: Text(
                    '${widget.ayah.numberInSurah}',
                    style: const TextStyle(fontSize: 12, color: brandGreen, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                ValueListenableBuilder<int?>(
                  valueListenable: QuranAudioService.instance.currentPlayingAyahNotifier,
                  builder: (context, currentAyah, _) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: QuranAudioService.instance.isPlayingNotifier,
                      builder: (context, isPlaying, __) {
                        final thisAyahPlaying = currentAyah == widget.ayah.numberInQuran && isPlaying;
                        return IconButton(
                          icon: Icon(
                            thisAyahPlaying ? Icons.pause_circle : Icons.play_circle_outline,
                            color: brandGreen,
                          ),
                          onPressed: () async {
                            widget.onAyahRead();
                            if (widget.ayah.audioUrl.isNotEmpty) {
                              await QuranAudioService.instance.toggleAyah(
                                widget.ayah.audioUrl,
                                widget.ayah.numberInQuran,
                              );
                              final error = QuranAudioService.instance.playbackErrorNotifier.value;
                              if (context.mounted && error != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(error)),
                                );
                              }
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Audio is not available for this Ayah yet.')),
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Copy Ayah text',
                  icon: const Icon(Icons.copy_rounded, color: brandGreen),
                  onPressed: () async {
                    final sections = <String>[
                      widget.ayah.arabicText.trim(),
                      if (widget.ayah.transliteration.trim().isNotEmpty) 'Pronunciation: ${widget.ayah.transliteration.trim()}',
                      if (widget.ayah.hinglishTranslation.trim().isNotEmpty) 'Hinglish meaning: ${widget.ayah.hinglishTranslation.trim()}',
                      if (widget.ayah.tafsir?.trim().isNotEmpty == true) 'Aasaan Samajh: ${widget.ayah.tafsir!.trim()}',
                    ];
                    final text = sections.join('\n\n');
                    await Clipboard.setData(ClipboardData(text: text.trim()));
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ayah text copied')));
                  },
                ),
                IconButton(
                  icon: Icon(widget.isBookmarked ? Icons.bookmark : Icons.bookmark_border, color: brandGreen),
                  onPressed: widget.onBookmarkToggle,
                ),
              ],
            ),
            if (widget.ayah.contentStatus == 'existing_draft_needs_review')
              const Align(alignment: Alignment.centerLeft, child: Chip(avatar: Icon(Icons.info_outline, size: 15), label: Text('Existing draft • needs review'), visualDensity: VisualDensity.compact)),
            if (widget.ayah.pronunciationStatus == 'source_unreviewed')
              const Align(alignment: Alignment.centerLeft, child: Chip(avatar: Icon(Icons.verified_outlined, size: 15), label: Text('Source transliteration • Hafiz review pending'), visualDensity: VisualDensity.compact)),
            const SizedBox(height: 12),
            Text(
              widget.ayah.arabicText,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: widget.arabicFontSize,
                height: 1.9,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : brandInk,
              ),
            ),
            const Divider(height: 28),
            const Text(
              'PRONUNCIATION',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: brandGold),
            ),
            const SizedBox(height: 6),
            Text(
              widget.ayah.transliteration.trim().isEmpty
                  ? 'Roman pronunciation is pending review.'
                  : widget.ayah.transliteration,
              style: TextStyle(
                fontSize: widget.transliterationFontSize,
                fontWeight: FontWeight.w600,
                color: widget.ayah.transliteration.trim().isEmpty ? Colors.grey : brandGreen,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'SIMPLE HINGLISH MEANING',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: brandGold),
            ),
            const SizedBox(height: 6),
            Text(
              widget.ayah.hinglishTranslation.trim().isEmpty
                  ? 'Hinglish meaning is pending review.'
                  : widget.ayah.hinglishTranslation,
              style: TextStyle(
                fontSize: widget.translationFontSize,
                height: 1.5,
                color: widget.ayah.hinglishTranslation.trim().isEmpty ? Colors.grey : null,
              ),
            ),
            ...[
              const SizedBox(height: 14),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text(
                  'Aasaan Samajh (Explanation)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: brandGold),
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C3E35) : const Color(0xFFF7F4EA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.ayah.tafsir?.trim().isNotEmpty == true ? widget.ayah.tafsir! : 'Aasaan Samajh explanation is pending review.',
                      style: TextStyle(fontSize: widget.translationFontSize - 1, height: 1.5),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }
}
