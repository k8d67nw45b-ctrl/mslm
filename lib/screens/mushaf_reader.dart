import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants.dart';
import 'app_settings.dart';
import 'ayah_audio.dart';
import 'ayah_sheet.dart';
import 'bookmarks.dart';
import 'khatma_service.dart';
import 'mushaf_page.dart';
import 'mushaf_service.dart';
import 'quran_text.dart';
import 'stats_service.dart';

String _latin(String s) {
  const ar = '٠١٢٣٤٥٦٧٨٩';
  var out = s;
  for (var i = 0; i < 10; i++) {
    out = out.replaceAll(ar[i], '$i');
  }
  return out;
}

Color _bgOf(int t) {
  switch (t) {
    case 2:
      return const Color(0xFFF1E4C8);
    case 3:
      return const Color(0xFF191919);
    case 4:
      return Colors.black;
    default:
      return Colors.white;
  }
}

class MushafReader extends StatefulWidget {
  final int startPage;
  const MushafReader({Key? key, required this.startPage})
      : super(key: key);

  @override
  State<MushafReader> createState() => _MushafReaderState();
}

class _MushafReaderState extends State<MushafReader> {
  static bool _hinted = false;
  late final PageController _pc;
  late int page;
  bool zoomed = false;
  bool chrome = true;
  double? slide;
  String _surah = '';
  Timer? _dwell;
  final Map<int, GlobalKey<MushafPageState>> _keys = {};

  GlobalKey<MushafPageState> _key(int i) =>
      _keys.putIfAbsent(i, () => GlobalKey<MushafPageState>());

  void _zoom(double factor) {
    _keys[page - 1]?.currentState?.zoomBy(factor);
  }

  void _precache(int p) {
    if (p < 1 || p > 604 || !mounted) return;
    precacheImage(AssetImage('assets/mushaf/p$p.webp'), context);
  }

  void _setChrome(bool v) {
    setState(() => chrome = v);
    SystemChrome.setEnabledSystemUIMode(
      v ? SystemUiMode.edgeToEdge : SystemUiMode.immersiveSticky,
    );
  }

  void _updateSurah() {
    final p = page;
    ayahsOfPage(p).then((l) {
      if (!mounted || p != page || l.isEmpty) return;
      setState(() => _surah = l.first.surahName);
    }).catchError((_) {});
  }

  void _startDwell() {
    _dwell?.cancel();
    final p = page;
    _dwell = Timer(const Duration(seconds: 3), () async {
      await recordPageRead(p);
      final fin = await khatmaMark(p);
      if (fin && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ما شاء الله! أتممت الختمة 🎉')),
        );
      }
    });
  }

  Future<void> _jump() async {
    final c = TextEditingController(text: '$page');
    final r = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('الانتقال إلى صفحة'),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(hintText: '1 - 604'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(_latin(c.text))),
            child: const Text('انتقال'),
          ),
        ],
      ),
    );
    if (r != null && r >= 1 && r <= 604) _pc.jumpToPage(r - 1);
  }

  void _pickTheme() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ValueListenableBuilder<int>(
            valueListenable: AppSettings.readTheme,
            builder: (c, v, _) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in readThemeNames.entries)
                  ChoiceChip(
                    label: Text(e.value),
                    selected: v == e.key,
                    onSelected: (_) => AppSettings.setReadTheme(e.key),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    page = widget.startPage;
    _pc = PageController(initialPage: page - 1);
    saveLastPage(page);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _precache(page + 1);
      _precache(page - 1);
      _updateSurah();
      _startDwell();
      if (!_hinted) {
        _hinted = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'اضغط الصفحة لإخفاء الأزرار، واضغط مطولاً لاختيار آية',
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _dwell?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    AyahAudio.stop();
    _pc.dispose();
    super.dispose();
  }

  Widget _fade(Widget child) {
    return IgnorePointer(
      ignoring: !chrome,
      child: AnimatedOpacity(
        opacity: chrome ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: child,
      ),
    );
  }

  Widget _player(Color fg) {
    return ValueListenableBuilder<AyahRef?>(
      valueListenable: AyahAudio.current,
      builder: (context, a, _) {
        if (a == null) return const SizedBox.shrink();
        return ListTile(
          dense: true,
          leading: const Icon(Icons.volume_up, color: kGreen),
          title: Text(
            'يُقرأ الآن: ${a.surahName}: ${a.ayah}',
            style: TextStyle(color: fg),
          ),
          trailing: IconButton(
            icon: Icon(Icons.stop_circle_outlined, color: fg),
            onPressed: AyahAudio.stop,
          ),
        );
      },
    );
  }

  Widget _bottom(Color bg, Color fg) {
    return Material(
      color: bg.withOpacity(0.95),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _player(fg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: (slide ?? page.toDouble())
                          .clamp(1.0, 604.0)
                          .toDouble(),
                      min: 1,
                      max: 604,
                      divisions: 603,
                      activeColor: kGreen,
                      onChanged: (v) => setState(() => slide = v),
                      onChangeEnd: (v) {
                        setState(() => slide = null);
                        _pc.jumpToPage(v.round() - 1);
                      },
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => showPageAyahs(context, page),
                    icon: const Icon(Icons.touch_app, color: kGreen),
                    label: Text('آية', style: TextStyle(color: fg)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final platformDark = Theme.of(context).brightness == Brightness.dark;
    return ValueListenableBuilder<int>(
      valueListenable: AppSettings.readTheme,
      builder: (context, v, _) {
        final t = v == 0 ? (platformDark ? 4 : 1) : v;
        final bg = _bgOf(t);
        final fg = t >= 3 ? Colors.white : Colors.black87;
        final top = MediaQuery.of(context).padding.top;
        return Scaffold(
          backgroundColor: bg,
          body: Stack(
            children: [
              Positioned.fill(
                child: PageView.builder(
                  controller: _pc,
                  itemCount: 604,
                  physics: zoomed
                      ? const NeverScrollableScrollPhysics()
                      : const PageScrollPhysics(),
                  onPageChanged: (i) {
                    setState(() {
                      page = i + 1;
                      zoomed = false;
                    });
                    saveLastPage(i + 1);
                    _precache(i + 2);
                    _precache(i);
                    _updateSurah();
                    _startDwell();
                  },
                  itemBuilder: (context, i) => MushafPage(
                    key: _key(i),
                    page: i + 1,
                    theme: t,
                    onZoom: (z) => setState(() => zoomed = z),
                    onTap: () => _setChrome(!chrome),
                    onLongPress: () => showPageAyahs(context, i + 1),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _fade(
                  SizedBox(
                    height: kToolbarHeight + top,
                    child: AppBar(
                      backgroundColor: bg.withOpacity(0.95),
                      foregroundColor: fg,
                      elevation: 0,
                      title: InkWell(
                        onTap: _jump,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('صفحة $page', style: TextStyle(color: fg)),
                            if (_surah.isNotEmpty)
                              Text(
                                _surah,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: fg.withOpacity(0.6),
                                ),
                              ),
                          ],
                        ),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.palette_outlined),
                          onPressed: _pickTheme,
                        ),
                        IconButton(
                          icon: const Icon(Icons.zoom_out),
                          onPressed: () => _zoom(1 / 1.5),
                        ),
                        IconButton(
                          icon: const Icon(Icons.zoom_in),
                          onPressed: () => _zoom(1.5),
                        ),
                        IconButton(
                          icon: const Icon(Icons.bookmarks_outlined),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BookmarksScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _fade(_bottom(bg, fg)),
              ),
            ],
          ),
        );
      },
    );
  }
}
