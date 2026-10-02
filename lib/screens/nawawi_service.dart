import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'nawawi_data.dart';

const _urls = [
  'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/ara-nawawi.json',
  'https://raw.githubusercontent.com/fawazahmed0/hadith-api/1/editions/ara-nawawi.json',
];

List<Hadith>? _cache;

List<Hadith> _parse(String raw) {
  final list = jsonDecode(raw)['hadiths'] as List;
  return list
      .map((h) => Hadith(
            (h['hadithnumber'] as num).toInt(),
            (h['text'] as String).trim(),
            '',
            '',
          ))
      .toList();
}

Future<List<Hadith>> loadNawawi() async {
  if (_cache != null) return _cache!;
  try {
    final raw = await rootBundle.loadString('assets/data/nawawi.json');
    _cache = _parse(raw);
    return _cache!;
  } catch (_) {}
  final p = await SharedPreferences.getInstance();
  final saved = p.getString('nawawi_json');
  if (saved != null) {
    _cache = _parse(saved);
    return _cache!;
  }
  for (final u in _urls) {
    try {
      final r =
          await http.get(Uri.parse(u)).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final raw = utf8.decode(r.bodyBytes);
        final out = _parse(raw);
        await p.setString('nawawi_json', raw);
        _cache = out;
        return out;
      }
    } catch (_) {}
  }
  throw 'تعذّر الاتصال، تأكد من الإنترنت';
}
