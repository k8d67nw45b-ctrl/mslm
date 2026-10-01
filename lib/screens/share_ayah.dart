import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/constants.dart';
import 'quran_text.dart';

Future<void> shareAyahText(AyahRef a) async {
  await Share.share('﴿${a.text}﴾\n[${a.surahName}: ${a.ayah}]');
}

class ShareImageDialog extends StatefulWidget {
  final AyahRef a;
  const ShareImageDialog({Key? key, required this.a}) : super(key: key);

  @override
  State<ShareImageDialog> createState() => _ShareImageDialogState();
}

class _ShareImageDialogState extends State<ShareImageDialog> {
  final _key = GlobalKey();
  bool busy = false;

  Future<void> _share() async {
    setState(() => busy = true);
    try {
      final b = _key.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 3);
      final bd = await img.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final f = File(
        '${dir.path}/ayah_${widget.a.surah}_${widget.a.ayah}.png',
      );
      await f.writeAsBytes(bd!.buffer.asUint8List());
      await Share.shareXFiles([XFile(f.path)]);
    } catch (_) {}
    if (mounted) setState(() => busy = false);
  }

  Widget _card() {
    final a = widget.a;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF005C42), Color(0xFF0B3B2E)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '﴿ ${a.text} ﴾',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              height: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${a.surahName}: ${a.ayah}',
            style: const TextStyle(color: Color(0xFFB6F36B), fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            appName,
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: RepaintBoundary(key: _key, child: _card()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              onPressed: busy ? null : _share,
              icon: const Icon(Icons.share),
              label: const Text('مشاركة الصورة'),
            ),
          ),
        ],
      ),
    );
  }
}
