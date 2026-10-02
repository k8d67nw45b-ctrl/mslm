import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'hisn_service.dart';
import 'nawawi_data.dart';
import 'nawawi_service.dart';
import 'quran_text.dart';

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
  try {
    final all = await loadAllAyahs();
    if (all.isEmpty) return null;
    final start = (_dayIndex() * 37) % all.length;
    for (var k = 0; k < 30; k++) {
      final a = all[(start + k) % all.length];
      if (a.text.length >= 25 && a.text.length <= 220) {
        return DailyItem(a.text, '${a.surahName}: ${a.ayah}');
      }
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
  final n = DateTime.now();
  final key = 'dod_${n.year}-${n.month}-${n.day}';
  final p = await SharedPreferences.getInstance();
  final saved = p.getString(key);
  if (saved != null) {
    try {
      final m = jsonDecode(saved);
      return DailyItem(m['t'] as String, m['s'] as String);
    } catch (_) {}
  }
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
    final pick = c[_dayIndex() % c.length];
    await p.setString(key, jsonEncode({'t': pick.text, 's': pick.source}));
    return pick;
  } catch (_) {
    return null;
  }
}
