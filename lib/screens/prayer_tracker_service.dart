import 'package:shared_preferences/shared_preferences.dart';

const List<String> kPrayerNames = [
  'الفجر',
  'الظهر',
  'العصر',
  'المغرب',
  'العشاء',
];

// الحالات: 0 لم يُسجَّل، 1 صليت، 2 بالجماعة، 3 فاتتني
String ptKey(DateTime d) => 'pt_${d.year}-${d.month}-${d.day}';

List<int> _decode(String? s) {
  final out = List<int>.filled(5, 0);
  if (s == null) return out;
  for (var i = 0; i < 5 && i < s.length; i++) {
    final v = int.tryParse(s[i]) ?? 0;
    out[i] = (v >= 0 && v <= 3) ? v : 0;
  }
  return out;
}

Future<List<int>> loadDay(DateTime d) async {
  final p = await SharedPreferences.getInstance();
  return _decode(p.getString(ptKey(d)));
}

Future<List<int>> loadQada() async {
  final p = await SharedPreferences.getInstance();
  return [for (var i = 0; i < 5; i++) p.getInt('qada_$i') ?? 0];
}

Future<void> addQada(int prayer, int delta) async {
  final p = await SharedPreferences.getInstance();
  final k = 'qada_$prayer';
  final v = (p.getInt(k) ?? 0) + delta;
  await p.setInt(k, v < 0 ? 0 : v);
}

Future<void> setPrayerState(DateTime d, int prayer, int state) async {
  final p = await SharedPreferences.getInstance();
  final cur = _decode(p.getString(ptKey(d)));
  final old = cur[prayer];
  if (old == state) return;
  cur[prayer] = state;
  await p.setString(ptKey(d), cur.join());
  if (old == 3 && state != 3) await addQada(prayer, -1);
  if (state == 3 && old != 3) await addQada(prayer, 1);
}

Future<List<List<int>>> loadWeek() async {
  final p = await SharedPreferences.getInstance();
  final now = DateTime.now();
  return [
    for (var i = 6; i >= 0; i--)
      _decode(p.getString(ptKey(DateTime(now.year, now.month, now.day - i)))),
  ];
}

Future<int> perfectStreak() async {
  final p = await SharedPreferences.getInstance();
  final now = DateTime.now();
  var streak = 0;
  for (var i = 0; i < 365; i++) {
    final d = DateTime(now.year, now.month, now.day - i);
    final day = _decode(p.getString(ptKey(d)));
    final ok = day.every((s) => s == 1 || s == 2);
    if (ok) {
      streak++;
    } else if (i > 0) {
      break;
    }
  }
  return streak;
}
