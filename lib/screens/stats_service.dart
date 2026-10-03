import 'package:shared_preferences/shared_preferences.dart';
import 'daily_adhkar.dart';

String dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

class Goals {
  final int pages;
  final int tasbih;
  const Goals(this.pages, this.tasbih);
}

class DayStats {
  final DateTime day;
  final int pages;
  final int tasbih;
  final double morning;
  final double evening;
  const DayStats(
    this.day,
    this.pages,
    this.tasbih,
    this.morning,
    this.evening,
  );

  bool get active => pages > 0 || tasbih > 0 || morning > 0 || evening > 0;
  double get adhkar => (morning + evening) / 2;
}

Future<Goals> loadGoals() async {
  final p = await SharedPreferences.getInstance();
  return Goals(p.getInt('goal_pages') ?? 5, p.getInt('goal_tasbih') ?? 100);
}

Future<void> saveGoals(Goals g) async {
  final p = await SharedPreferences.getInstance();
  await p.setInt('goal_pages', g.pages);
  await p.setInt('goal_tasbih', g.tasbih);
}

Future<void> recordPageRead(int page) async {
  final p = await SharedPreferences.getInstance();
  final k = 'st_pages_${dayKey(DateTime.now())}';
  final l = p.getStringList(k) ?? [];
  final s = '$page';
  if (!l.contains(s)) {
    l.add(s);
    await p.setStringList(k, l);
  }
}

Future<void> addTasbih(int n) async {
  if (n <= 0) return;
  final p = await SharedPreferences.getInstance();
  final k = 'st_tasbih_${dayKey(DateTime.now())}';
  await p.setInt(k, (p.getInt(k) ?? 0) + n);
}

double _adhkarOn(
  SharedPreferences p,
  bool morning,
  DateTime d,
  List<AdhkarItem> list,
) {
  var total = 0;
  var done = 0;
  final tag = morning ? 'm' : 'e';
  for (var i = 0; i < list.length; i++) {
    total += list[i].count;
    final c = p.getInt('dadhkar_${tag}_${dayKey(d)}_$i') ?? 0;
    done += c > list[i].count ? list[i].count : c;
  }
  return total == 0 ? 0.0 : done / total;
}

DayStats _statsFor(
  SharedPreferences p,
  DateTime d,
  List<AdhkarItem> m,
  List<AdhkarItem> e,
) {
  final k = dayKey(d);
  return DayStats(
    d,
    (p.getStringList('st_pages_$k') ?? []).length,
    p.getInt('st_tasbih_$k') ?? 0,
    _adhkarOn(p, true, d, m),
    _adhkarOn(p, false, d, e),
  );
}

Future<List<AdhkarItem>> _safe(bool morning) async {
  try {
    return await loadAdhkar(morning);
  } catch (_) {
    return <AdhkarItem>[];
  }
}

Future<DayStats> loadToday() async {
  final p = await SharedPreferences.getInstance();
  return _statsFor(p, DateTime.now(), await _safe(true), await _safe(false));
}

Future<List<DayStats>> loadWeek() async {
  final p = await SharedPreferences.getInstance();
  final m = await _safe(true);
  final e = await _safe(false);
  final now = DateTime.now();
  return [
    for (var i = 6; i >= 0; i--)
      _statsFor(p, DateTime(now.year, now.month, now.day - i), m, e),
  ];
}

Future<int> loadStreak() async {
  final p = await SharedPreferences.getInstance();
  final m = await _safe(true);
  final e = await _safe(false);
  final now = DateTime.now();
  var streak = 0;
  for (var i = 0; i < 120; i++) {
    final d = DateTime(now.year, now.month, now.day - i);
    final s = _statsFor(p, d, m, e);
    if (s.active) {
      streak++;
    } else if (i > 0) {
      break;
    }
  }
  return streak;
}
