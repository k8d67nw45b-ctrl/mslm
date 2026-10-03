import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'ayah_audio.dart';
import 'ayah_sheet.dart';
import 'bookmarks.dart';
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
    _dwell = Timer(const Duration(seconds: 3), () => recordPageRead(p));
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
              'اضغط على الصفحة لاختيار آية، واضغط على رقم الصفحة للانتقال',
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _dwell?.cancel();
    AyahAudio.stop();
    _pc.dispose();
    super.dispose();
  }

  Widget _player() {
    return ValueListenableBuilder<AyahRef?>(
      valueListenable: AyahAudio.current,
      builder: (context, a, _) {
        if (a == null) return const SizedBox.shrink();
        return Material(
          color: kCardBackground,
          child: SafeArea(
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.volume_up, color: kGreen),
              title: Text('يُقرأ الآن: ${a.surahName}: ${a.ayah}'),
              trailing: IconButton(
                icon: const Icon(Icons.stop_circle_outlined),
                onPressed: AyahAudio.stop,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: _jump,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('صفحة $page'),
              if (_surah.isNotEmpty)
                Text(
                  _surah,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
        ),
        actions: [
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
              MaterialPageRoute(builder: (_) => const BookmarksScreen()),
            ),
          ),
        ],
      ),
      body: PageView.builder(
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
          dark: dark,
          onZoom: (z) => setState(() => zoomed = z),
          onTap: () {
            if (!zoomed) showPageAyahs(context, i + 1);
          },
        ),
      ),
      bottomNavigationBar: _player(),
    );
  }
}
