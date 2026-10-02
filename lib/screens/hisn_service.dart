import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _url =
    'https://raw.githubusercontent.com/rn0x/hisn_almuslim_json/main/hisn_almuslim.json';

class HisnSection {
  final String title;
  final List<String> texts;
  final List<String> notes;
  HisnSection(this.title, this.texts, this.notes);
}

List<HisnSection>? _cache;

List<HisnSection> _parse(String raw) {
  final map = jsonDecode(raw) as Map<String, dynamic>;
  final out = <HisnSection>[];
  map.forEach((k, v) {
    if (k == 'المقدمة') return;
    out.add(HisnSection(
      k,
      List<String>.from(v['text'] ?? []),
      List<String>.from(v['footnote'] ?? []),
    ));
  });
  return out;
}

Future<List<HisnSection>> loadHisn() async {
  if (_cache != null) return _cache!;
  try {
    final raw = await rootBundle.loadString('assets/data/hisn_almuslim.json');
    _cache = _parse(raw);
    return _cache!;
  } catch (_) {}
  final prefs = await SharedPreferences.getInstance();
  var raw = prefs.getString('hisn_json');
  if (raw == null) {
    final r = await http
        .get(Uri.parse(_url))
        .timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) {
      throw 'تعذّر الاتصال، تأكد من الإنترنت';
    }
    raw = utf8.decode(r.bodyBytes);
    await prefs.setString('hisn_json', raw);
  }
  _cache = _parse(raw);
  return _cache!;
}

int countOf(String t) {
  if (t.contains('مائة مرة')) return 100;
  if (t.contains('ثلاثاً وثلاثين')) return 33;
  if (t.contains('أربعاً وثلاثين')) return 34;
  if (t.contains('سبع مرات')) return 7;
  if (t.contains('عشر مرات')) return 10;
  if (t.contains('أربع مرات')) return 4;
  if (t.contains('ثلاث مرات')) return 3;
  return 1;
}
