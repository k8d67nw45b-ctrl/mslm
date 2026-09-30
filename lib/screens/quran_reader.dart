import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'quran_service.dart';

class QuranReader extends StatefulWidget {
  final SurahInfo surah;
  const QuranReader({Key? key, required this.surah}) : super(key: key);

  @override
  State<QuranReader> createState() => _QuranReaderState();
}

class _QuranReaderState extends State<QuranReader> {
  List<String>? ayahs;
  String? error;
  double fontSize = 26;

  @override
  void initState() {
    super.initState();
    saveLast(widget.surah.number, widget.surah.name);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      error = null;
      ayahs = null;
    });
    try {
      final a = await loadAyahs(widget.surah.number);
      setState(() => ayahs = a);
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.surah.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_decrease),
            onPressed: () => setState(() {
              if (fontSize > 18) fontSize -= 2;
            }),
          ),
          IconButton(
            icon: const Icon(Icons.text_increase),
            onPressed: () => setState(() {
              if (fontSize < 40) fontSize += 2;
            }),
          ),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(error!),
            const SizedBox(height: kPaddingMedium),
            ElevatedButton(
              onPressed: _load,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }
    if (ayahs == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final spans = <InlineSpan>[];
    for (var i = 0; i < ayahs!.length; i++) {
      spans.add(TextSpan(text: '${ayahs![i]} '));
      spans.add(TextSpan(
        text: '﴿${i + 1}﴾ ',
        style: const TextStyle(color: kGreen),
      ));
    }
    return ListView(
      padding: const EdgeInsets.all(kPaddingMedium),
      children: [
        Text.rich(
          TextSpan(children: spans),
          textAlign: TextAlign.justify,
          style: TextStyle(fontSize: fontSize, height: 2.2),
        ),
      ],
    );
  }
}
