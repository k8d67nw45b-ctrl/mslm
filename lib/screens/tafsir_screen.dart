import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import 'quran_text.dart';

const _none = 'لا يوجد تفسير لهذه الآية في هذا المصدر.';

String _strip(String s) {
  return s
      .replaceAll(RegExp(r'<br\s*/?>'), '\n')
      .replaceAll(RegExp(r'</p>'), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .trim();
}

Future<String> _fetch(
  String key,
  String url,
  String Function(dynamic) pick,
) async {
  final p = await SharedPreferences.getInstance();
  final saved = p.getString(key);
  if (saved != null) return saved;
  final r = await http.get(Uri.parse(url));
  if (r.statusCode == 404) return _none;
  if (r.statusCode != 200) {
    throw 'تعذّر جلب التفسير، تأكد من الإنترنت';
  }
  final t = _strip(pick(jsonDecode(utf8.decode(r.bodyBytes))));
  if (t.isEmpty) return _none;
  await p.setString(key, t);
  return t;
}

Future<String> jalalayn(int s, int a) => _fetch(
      'tf_j_${s}_$a',
      'https://api.alquran.cloud/v1/ayah/$s:$a/ar.jalalayn',
      (j) => j['data']['text'] as String,
    );

Future<String> tabari(int s, int a) => _fetch(
      'tf_t_${s}_$a',
      'https://cdn.jsdelivr.net/gh/spa5k/tafsir_api@main/tafsir/ar-tafsir-al-tabari/$s/$a.json',
      (j) => (j['text'] ?? '') as String,
    );

class TafsirScreen extends StatelessWidget {
  final AyahRef a;
  const TafsirScreen({Key? key, required this.a}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${a.surahName}: ${a.ayah}'),
          bottom: const TabBar(
            tabs: [Tab(text: 'الجلالين'), Tab(text: 'الطبري')],
          ),
        ),
        body: TabBarView(
          children: [
            _Body(a: a, loader: () => jalalayn(a.surah, a.ayah)),
            _Body(a: a, loader: () => tabari(a.surah, a.ayah)),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  final AyahRef a;
  final Future<String> Function() loader;
  const _Body({Key? key, required this.a, required this.loader})
      : super(key: key);

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late Future<String> f;

  @override
  void initState() {
    super.initState();
    f = widget.loader();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: f,
      builder: (c, s) {
        if (s.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (s.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${s.error}', textAlign: TextAlign.center),
                const SizedBox(height: kPaddingMedium),
                ElevatedButton(
                  onPressed: () => setState(() => f = widget.loader()),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(kPaddingMedium),
          children: [
            Card(
              color: kCardBackground,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '﴿${widget.a.text}﴾',
                  style: const TextStyle(fontSize: 21, height: 1.9),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              s.data!,
              style: const TextStyle(fontSize: 18, height: 1.9),
            ),
          ],
        );
      },
    );
  }
}
