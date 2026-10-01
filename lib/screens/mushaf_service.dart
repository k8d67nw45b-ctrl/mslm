import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<Map<int, int>> loadSurahPages() async {
  final p = await SharedPreferences.getInstance();
  var raw = p.getString('meta_pages');
  if (raw == null) {
    final r = await http.get(
      Uri.parse('https://api.alquran.cloud/v1/meta'),
    );
    if (r.statusCode != 200) {
      throw 'تعذّر الاتصال، تأكد من الإنترنت';
    }
    final body = jsonDecode(utf8.decode(r.bodyBytes));
    final refs = body['data']['pages']['references'] as List;
    raw = jsonEncode(
      refs.map((e) => [e['surah'], e['ayah']]).toList(),
    );
    await p.setString('meta_pages', raw);
  }
  final refs = jsonDecode(raw) as List;
  final out = <int, int>{};
  for (var s = 1; s <= 114; s++) {
    var page = 1;
    for (var i = 0; i < refs.length; i++) {
      final rs = refs[i][0] as int;
      final ra = refs[i][1] as int;
      if (rs < s || (rs == s && ra <= 1)) {
        page = i + 1;
      } else {
        break;
      }
    }
    out[s] = page;
  }
  return out;
}

Future<void> saveLastPage(int page) async {
  final p = await SharedPreferences.getInstance();
  await p.setInt('mushaf_last', page);
}

Future<int?> getLastPage() async {
  final p = await SharedPreferences.getInstance();
  return p.getInt('mushaf_last');
}
