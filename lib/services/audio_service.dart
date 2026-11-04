import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/quran_models.dart';

enum QuranRepeatMode { off, all, one }

class QuranAudioService {
  static final QuranAudioService instance = QuranAudioService._internal();
  QuranAudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);
  final ValueNotifier<int?> currentPlayingAyahNotifier = ValueNotifier(null);
  final ValueNotifier<String?> playbackErrorNotifier = ValueNotifier(null);
  final ValueNotifier<QuranRepeatMode> repeatModeNotifier =
      ValueNotifier(QuranRepeatMode.off);

  StreamSubscription<PlayerState>? _playerStateSubscription;
  bool _initialized = false;
  bool _handlingCompletion = false;
  int _requestToken = 0;
  List<Ayah> _queue = const [];
  int _queueIndex = -1;
  Uri? _singleAyahUri;
  int? _singleAyahNumber;

  void init() {
    if (_initialized) return;
    _initialized = true;
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      isPlayingNotifier.value = state.playing;
      if (state.processingState == ProcessingState.completed) {
        if (!_handlingCompletion) {
          _handlingCompletion = true;
          unawaited(_handleCompletion());
        }
      } else {
        _handlingCompletion = false;
      }
    }, onError: (Object error, StackTrace stackTrace) {
      playbackErrorNotifier.value = 'Audio playback failed. Please try again.';
      isPlayingNotifier.value = false;
      currentPlayingAyahNotifier.value = null;
      debugPrint('Quran audio stream error: $error');
    });
  }

  Future<void> toggleAyah(String url, int ayahNumber) async {
    final uri = _validAudioUri(url);
    if (uri == null) {
      playbackErrorNotifier.value = 'This audio link is invalid or unavailable.';
      return;
    }

    if (currentPlayingAyahNotifier.value == ayahNumber) {
      playbackErrorNotifier.value = null;
      if (_player.playing) {
        await _player.pause();
      } else {
        unawaited(_player.play());
      }
      return;
    }

    _queue = const [];
    _queueIndex = -1;
    _singleAyahUri = uri;
    _singleAyahNumber = ayahNumber;
    await _playUri(uri, ayahNumber);
  }

  Future<void> playQueue(List<Ayah> ayahs, {int startIndex = 0}) async {
    if (ayahs.isEmpty) return;
    _singleAyahUri = null;
    _singleAyahNumber = null;
    _queue = List<Ayah>.unmodifiable(ayahs);
    final boundedIndex = startIndex.clamp(0, _queue.length - 1).toInt();
    await _playQueueIndex(boundedIndex, direction: 1);
  }

  Future<void> next() async {
    if (_queue.isEmpty || _queueIndex < 0) return;
    final nextIndex = _queueIndex + 1;
    if (nextIndex < _queue.length) {
      await _playQueueIndex(nextIndex, direction: 1);
    } else if (repeatModeNotifier.value == QuranRepeatMode.all) {
      await _playQueueIndex(0, direction: 1);
    }
  }

  Future<void> previous() async {
    if (_queue.isEmpty || _queueIndex < 0) return;
    final previousIndex = _queueIndex - 1;
    if (previousIndex >= 0) {
      await _playQueueIndex(previousIndex, direction: -1);
    } else if (repeatModeNotifier.value == QuranRepeatMode.all) {
      await _playQueueIndex(_queue.length - 1, direction: -1);
    }
  }

  void setRepeatMode(QuranRepeatMode mode) {
    repeatModeNotifier.value = mode;
  }

  Future<void> _handleCompletion() async {
    if (_queue.isEmpty || _queueIndex < 0) {
      if (repeatModeNotifier.value == QuranRepeatMode.one &&
          _singleAyahUri != null && _singleAyahNumber != null) {
        await _playUri(_singleAyahUri!, _singleAyahNumber!);
        return;
      }
      currentPlayingAyahNotifier.value = null;
      isPlayingNotifier.value = false;
      return;
    }

    if (repeatModeNotifier.value == QuranRepeatMode.one) {
      await _playQueueIndex(_queueIndex, direction: 1);
      return;
    }

    final nextIndex = _queueIndex + 1;
    if (nextIndex < _queue.length) {
      await _playQueueIndex(nextIndex, direction: 1);
    } else if (repeatModeNotifier.value == QuranRepeatMode.all) {
      await _playQueueIndex(0, direction: 1);
    } else {
      currentPlayingAyahNotifier.value = null;
      isPlayingNotifier.value = false;
      _queue = const [];
      _queueIndex = -1;
    }
  }

  Future<void> _playQueueIndex(int index, {required int direction}) async {
    if (_queue.isEmpty) return;
    var candidate = index;
    for (var checked = 0; checked < _queue.length; checked++) {
      if (candidate < 0 || candidate >= _queue.length) {
        if (repeatModeNotifier.value != QuranRepeatMode.all) break;
        candidate = candidate < 0 ? _queue.length - 1 : 0;
      }
      final ayah = _queue[candidate];
      final uri = _validAudioUri(ayah.audioUrl);
      if (uri != null) {
        _queueIndex = candidate;
        await _playUri(uri, ayah.numberInQuran);
        return;
      }
      candidate += direction;
    }

    playbackErrorNotifier.value = 'Audio is not available for the remaining Ayahs.';
    currentPlayingAyahNotifier.value = null;
    isPlayingNotifier.value = false;
    _queue = const [];
    _queueIndex = -1;
  }

  Future<void> _playUri(Uri uri, int ayahNumber) async {
    final request = ++_requestToken;
    playbackErrorNotifier.value = null;
    try {
      await _player.stop();
      if (request != _requestToken) return;
      await _player.setUrl(uri.toString());
      if (request != _requestToken) return;
      currentPlayingAyahNotifier.value = ayahNumber;
      unawaited(_player.play().catchError((Object error) {
        if (request == _requestToken) {
          playbackErrorNotifier.value = 'Could not play this Ayah. Check your internet and try again.';
          currentPlayingAyahNotifier.value = null;
          isPlayingNotifier.value = false;
        }
        debugPrint('Quran audio playback error: $error');
      }));
    } catch (error) {
      if (request == _requestToken) {
        playbackErrorNotifier.value =
            'Could not play this Ayah. Check your internet and try again.';
        currentPlayingAyahNotifier.value = null;
        isPlayingNotifier.value = false;
      }
      debugPrint('Quran audio error: $error');
    }
  }

  Uri? _validAudioUri(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    return uri;
  }

  Future<void> stop() async {
    ++_requestToken;
    _queue = const [];
    _queueIndex = -1;
    _singleAyahUri = null;
    _singleAyahNumber = null;
    await _player.stop();
    currentPlayingAyahNotifier.value = null;
    isPlayingNotifier.value = false;
  }

  Future<void> dispose() async {
    await _playerStateSubscription?.cancel();
    await _player.dispose();
    isPlayingNotifier.dispose();
    currentPlayingAyahNotifier.dispose();
    playbackErrorNotifier.dispose();
    repeatModeNotifier.dispose();
  }
}
