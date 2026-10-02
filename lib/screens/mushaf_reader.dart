import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'ayah_audio.dart';
import 'ayah_sheet.dart';
import 'bookmarks.dart';
import 'mushaf_page.dart';
import 'mushaf_service.dart';
import 'quran_text.dart';

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
  final Map<int, GlobalKey<MushafPageState>> _keys = {};

  GlobalKey<MushafPageState> _key(int i) =>
      _keys.putIfAbsent(i, () => GlobalKey<MushafPageState>());

  void _zoom(double factor) {
    _keys[page - 1]?.currentState?.zoomBy(factor);
  }

  @override
  void initState() {
    super.initState();
    page = widget.startPage;
    _pc = PageController(initialPage: page - 1);
    saveLastPage(page);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hinted && mounted) {
        _hinted = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'اضغط على الصفحة لاختيار آية: مشاركة، حفظ، تفسير، استماع',
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
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
        title: Text('صفحة $page'),
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
