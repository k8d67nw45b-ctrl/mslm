import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefixes = [
  'st_pages_',
  'st_tasbih_',
  'goal_',
  'kh_',
  'bookmarks',
  'adhkar_favs',
  'tasbih_',
  'cards_',
  'n_p',
  'n_morning',
  'n_evening',
  'n_before',
  'n_adhan_sound',
  'calc_method',
  'madhab',
  'angle_',
  'hijri_offset',
  'font_scale',
  'read_theme',
  'amoled',
  'dark_mode',
  'mushaf_last',
  'nawawi_favs',
  'loc_',
  'occ_',
  'pt_',
  'qada_',
  'zk_',
  'ram_',
];

bool _wanted(String k) => _prefixes.any((p) => k.startsWith(p));

Future<String> exportBackup() async {
  final p = await SharedPreferences.getInstance();
  final list = <Map<String, dynamic>>[];
  for (final k in p.getKeys()) {
    if (!_wanted(k)) continue;
    final v = p.get(k);
    if (v is bool) {
      list.add({'k': k, 't': 'b', 'v': v});
    } else if (v is int) {
      list.add({'k': k, 't': 'i', 'v': v});
    } else if (v is double) {
      list.add({'k': k, 't': 'd', 'v': v});
    } else if (v is String) {
      list.add({'k': k, 't': 's', 'v': v});
    } else if (v is List) {
      list.add({'k': k, 't': 'l', 'v': v.map((e) => '$e').toList()});
    }
  }
  return jsonEncode({
    'app': 'rafiq_almuslim',
    'v': 1,
    'time': DateTime.now().toIso8601String(),
    'data': list,
  });
}

Future<int> importBackup(String text) async {
  final m = jsonDecode(text.trim());
  if (m is! Map || m['app'] != 'rafiq_almuslim') {
    throw 'نسخة غير صالحة';
  }
  final p = await SharedPreferences.getInstance();
  var n = 0;
  for (final e in (m['data'] as List)) {
    final k = e['k'] as String;
    if (!_wanted(k)) continue;
    switch (e['t']) {
      case 'b':
        await p.setBool(k, e['v'] as bool);
        break;
      case 'i':
        await p.setInt(k, e['v'] as int);
        break;
      case 'd':
        await p.setDouble(k, (e['v'] as num).toDouble());
        break;
      case 's':
        await p.setString(k, e['v'] as String);
        break;
      case 'l':
        await p.setStringList(k, List<String>.from(e['v'] as List));
        break;
      default:
        continue;
    }
    n++;
  }
  return n;
}

Future<File> writeBackupFile(String json) async {
  final dir = await getTemporaryDirectory();
  final d = DateTime.now();
  final f = File(
    '${dir.path}/rafiq_backup_${d.year}-${d.month}-${d.day}.json',
  );
  await f.writeAsString(json);
  return f;
}
