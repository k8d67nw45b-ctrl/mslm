import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'hisn_service.dart';
import 'nawawi_data.dart';
import 'nawawi_service.dart';

class DailyItem {
  final String text;
  final String source;
  const DailyItem(this.text, this.source);
}

int _dayIndex() {
  final n = DateTime.now();
  return n.difference(DateTime(n.year, 1, 1)).inDays + n.year * 7;
}

String _plain(String s) {
  return s.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '');
}

Future<DailyItem?> verseOfDay() async {
  final n = DateTime.now();
  final key = 'votd_${n.year}-${n.month}-${n.day}';
  final p = await SharedPreferences.getInstance();
  final saved = p.getString(key);
  if (saved != null) {
    final m = jsonDecode(saved);
    return DailyItem(m['t'] as String, m['s'] as String);
  }
  try {
    var num = (_dayIndex() * 37) % 6236 + 1;
    for (var i = 0; i < 6; i++) {
      final r = await http.get(Uri.parse(
          'https://api.alquran.cloud/v1/ayah/$num/quran-uthmani'));
      if (r.statusCode != 200) return null;
      final d = jsonDecode(utf8.decode(r.bodyBytes))['data'];
      final text = d['text'] as String;
      if (text.length >= 25) {
        final s = '${d['surah']['name']}: ${d['numberInSurah']}';
        await p.setString(key, jsonEncode({'t': text, 's': s}));
        return DailyItem(text, s);
      }
      num = num % 6236 + 1;
    }
  } catch (_) {}
  return null;
}

Future<DailyItem?> hadithOfDay() async {
  List<Hadith> list;
  try {
    list = await loadNawawi();
  } catch (_) {
    list = nawawiList;
  }
  if (list.isEmpty) return null;
  final h = list[_dayIndex() % list.length];
  return DailyItem(h.text, 'الأربعون النووية: الحديث ${h.number}');
}

Future<DailyItem?> duaOfDay() async {
  try {
    final all = await loadHisn();
    final c = <DailyItem>[];
    for (final s in all) {
      for (final t in s.texts) {
        final x = t.trim();
        final pl = _plain(x);
        if (x.length < 15 || x.length > 160) continue;
        if (x.contains('{') || pl.contains('قال')) continue;
        if (pl.contains('صلى الله') || pl.contains('رضي الله')) continue;
        if (!pl.contains('اللهم')) continue;
        c.add(DailyItem(x, s.title));
      }
    }
    if (c.isEmpty) return null;
    return c[_dayIndex() % c.length];
  } catch (_) {
    return null;
  }
}

Future<double?> morningProgress() async {
  try {
    final all = await loadHisn();
    final s = all.firstWhere((e) => e.title.contains('الصباح والمساء'));
    final p = await SharedPreferences.getInstance();
    final n = DateTime.now();
    var total = 0;
    var done = 0;
    for (var i = 0; i < s.texts.length; i++) {
      final max = countOf(s.texts[i]);
      final c =
          p.getInt('hisn_${n.year}-${n.month}-${n.day}_${s.title}_$i') ?? 0;
      total += max;
      done += c > max ? max : c;
    }
    return total == 0 ? 0 : done / total;
  } catch (_) {
    return null;
  }
}
