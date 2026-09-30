import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SurahInfo {
  final int number;
  final String name;
  final int ayahs;
  const SurahInfo(this.number, this.name, this.ayahs);
}

Future<String> _cachedGet(String key, String url) async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(key);
  if (saved != null) return saved;
  final r = await http.get(Uri.parse(url));
  if (r.statusCode != 200) {
    throw 'تعذّر الاتصال، تأكد من الإنترنت';
  }
  final body = utf8.decode(r.bodyBytes);
  await prefs.setString(key, body);
  return body;
}

Future<List<SurahInfo>> loadSurahList() async {
  final raw = await _cachedGet(
    'quran_list',
    'https://api.alquran.cloud/v1/surah',
  );
  final list = jsonDecode(raw)['data'] as List;
  return list
      .map((s) => SurahInfo(
            s['number'] as int,
            s['name'] as String,
            s['numberOfAyahs'] as int,
          ))
      .toList();
}

Future<List<String>> loadAyahs(int surah) async {
  final raw = await _cachedGet(
    'quran_s_$surah',
    'https://api.alquran.cloud/v1/surah/$surah/quran-uthmani',
  );
  final list = jsonDecode(raw)['data']['ayahs'] as List;
  return list.map((a) => a['text'] as String).toList();
}

Future<void> saveLast(int number, String name) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('quran_last_n', number);
  await prefs.setString('quran_last_name', name);
}
