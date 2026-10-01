import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class AyahRef {
  final int surah;
  final String surahName;
  final int ayah;
  final String text;
  final int page;
  const AyahRef(this.surah, this.surahName, this.ayah, this.text, this.page);
}

class SurahItem {
  final int number;
  final String name;
  final int ayahs;
  final int page;
  const SurahItem(this.number, this.name, this.ayahs, this.page);
}

List<AyahRef>? _all;

String _clean(int surah, int ayah, String t) {
  if (ayah == 1 && surah != 1 && surah != 9) {
    final w = t.split(' ');
    if (w.length > 4) return w.sublist(4).join(' ');
  }
  return t;
}

List<AyahRef> _parse(String raw) {
  final surahs = jsonDecode(raw)['data']['surahs'] as List;
  final out = <AyahRef>[];
  for (final s in surahs) {
    final sn = s['number'] as int;
    final name = s['name'] as String;
    for (final a in s['ayahs'] as List) {
      final n = a['numberInSurah'] as int;
      out.add(AyahRef(
        sn,
        name,
        n,
        _clean(sn, n, a['text'] as String),
        a['page'] as int,
      ));
    }
  }
  return out;
}

Future<List<AyahRef>> loadAllAyahs() async {
  if (_all != null) return _all!;
  try {
    final raw = await rootBundle.loadString('assets/data/quran_uthmani.json');
    _all = _parse(raw);
    return _all!;
  } catch (_) {}
  final dir = await getApplicationDocumentsDirectory();
  final f = File('${dir.path}/quran_uthmani.json');
  if (await f.exists()) {
    try {
      _all = _parse(await f.readAsString());
      return _all!;
    } catch (_) {}
  }
  final r = await http.get(
    Uri.parse('https://api.alquran.cloud/v1/quran/quran-uthmani'),
  );
  if (r.statusCode != 200) {
    throw 'تعذّر تحميل نص القرآن';
  }
  final raw = utf8.decode(r.bodyBytes);
  final out = _parse(raw);
  await f.writeAsString(raw);
  _all = out;
  return out;
}

Future<List<AyahRef>> ayahsOfPage(int page) async {
  final all = await loadAllAyahs();
  return all.where((a) => a.page == page).toList();
}

Future<List<SurahItem>> loadSurahItems() async {
  final all = await loadAllAyahs();
  final names = <int, String>{};
  final counts = <int, int>{};
  final pages = <int, int>{};
  for (final a in all) {
    names[a.surah] = a.surahName;
    counts[a.surah] = (counts[a.surah] ?? 0) + 1;
    pages.putIfAbsent(a.surah, () => a.page);
  }
  return [
    for (var s = 1; s <= 114; s++)
      SurahItem(s, names[s]!, counts[s]!, pages[s]!),
  ];
}
