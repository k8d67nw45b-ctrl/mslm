import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'quran_text.dart';

class AyahAudio {
  static final AudioPlayer _p = AudioPlayer();
  static final ValueNotifier<AyahRef?> current =
      ValueNotifier<AyahRef?>(null);
  static List<AyahRef> _queue = [];
  static int _i = 0;
  static bool _init = false;

  static void _ensure() {
    if (_init) return;
    _init = true;
    _p.onPlayerComplete.listen((_) => _next());
  }

  static String _url(AyahRef a) {
    final s = a.surah.toString().padLeft(3, '0');
    final n = a.ayah.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/Muhammad_Ayyoub_128kbps/$s$n.mp3';
  }

  static Future<void> playList(List<AyahRef> list, int index) async {
    _ensure();
    _queue = list;
    _i = index;
    await _play();
  }

  static Future<void> _play() async {
    if (_i >= _queue.length) {
      await stop();
      return;
    }
    final a = _queue[_i];
    current.value = a;
    try {
      await _p.play(UrlSource(_url(a)));
    } catch (_) {
      await stop();
    }
  }

  static Future<void> _next() async {
    _i++;
    await _play();
  }

  static Future<void> stop() async {
    await _p.stop();
    current.value = null;
  }
}
