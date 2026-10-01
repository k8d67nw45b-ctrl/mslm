import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'nawawi_data.dart';

const _urls = [
  'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/ara-nawawi.json',
  'https://raw.githubusercontent.com/fawazahmed0/hadith-api/1/editions/ara-nawawi.json',
];

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
  final p = await SharedPreferences.getInstance();
  final saved = p.getString('nawawi_json');
  if (saved != null) {
    return _parse(saved);
  }
  for (final u in _urls) {
    try {
      final r = await http.get(Uri.parse(u));
      if (r.statusCode == 200) {
        final raw = utf8.decode(r.bodyBytes);
        final out = _parse(raw);
        await p.setString('nawawi_json', raw);
        return out;
      }
    } catch (_) {}
  }
  throw 'تعذّر الاتصال، تأكد من الإنترنت';
}
