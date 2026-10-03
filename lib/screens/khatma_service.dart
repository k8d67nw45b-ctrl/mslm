import 'package:shared_preferences/shared_preferences.dart';

String _dk(DateTime d) => '${d.year}-${d.month}-${d.day}';

class Khatma {
  final bool active;
  final DateTime? start;
  final int days;
  final int done;
  final int completed;
  final int todayDone;
  final bool remind;
  final int remindMinutes;
  const Khatma(
    this.active,
    this.start,
    this.days,
    this.done,
    this.completed,
    this.todayDone,
    this.remind,
    this.remindMinutes,
  );

  int get left => 604 - done;

  int get elapsed {
    final s = start;
    if (s == null) return 0;
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day)
        .difference(DateTime(s.year, s.month, s.day))
        .inDays;
  }

  int get daysLeft {
    final d = days - elapsed;
    return d < 1 ? 1 : d;
  }

  int get todayTarget {
    final before = 604 - (done - todayDone);
    if (before <= 0) return 0;
    return (before / daysLeft).ceil();
  }

  DateTime get finishDate {
    final s = start ?? DateTime.now();
    return DateTime(s.year, s.month, s.day + days);
  }
}

Future<Khatma> loadKhatma() async {
  final p = await SharedPreferences.getInstance();
  final s = p.getString('kh_start');
  return Khatma(
    p.getBool('kh_active') ?? false,
    s == null ? null : DateTime.tryParse(s),
    p.getInt('kh_days') ?? 30,
    (p.getStringList('kh_read') ?? []).length,
    p.getInt('kh_completed') ?? 0,
    p.getInt('kh_td_${_dk(DateTime.now())}') ?? 0,
    p.getBool('kh_remind') ?? false,
    p.getInt('kh_time') ?? 21 * 60,
  );
}

Future<void> startKhatma(int days) async {
  final p = await SharedPreferences.getInstance();
  await p.setBool('kh_active', true);
  await p.setString('kh_start', DateTime.now().toIso8601String());
  await p.setInt('kh_days', days);
  await p.remove('kh_read');
  await p.remove('kh_td_${_dk(DateTime.now())}');
}

Future<void> stopKhatma() async {
  final p = await SharedPreferences.getInstance();
  await p.setBool('kh_active', false);
  await p.remove('kh_read');
  await p.setBool('kh_remind', false);
}

Future<bool> khatmaMark(int page) async {
  final p = await SharedPreferences.getInstance();
  if (!(p.getBool('kh_active') ?? false)) return false;
  final l = p.getStringList('kh_read') ?? [];
  final s = '$page';
  if (l.contains(s)) return false;
  l.add(s);
  await p.setStringList('kh_read', l);
  final k = 'kh_td_${_dk(DateTime.now())}';
  await p.setInt(k, (p.getInt(k) ?? 0) + 1);
  if (l.length >= 604) {
    await p.setInt('kh_completed', (p.getInt('kh_completed') ?? 0) + 1);
    await p.setBool('kh_active', false);
    await p.setBool('kh_remind', false);
    return true;
  }
  return false;
}

Future<void> setKhatmaReminder(bool on, int minutes) async {
  final p = await SharedPreferences.getInstance();
  await p.setBool('kh_remind', on);
  await p.setInt('kh_time', minutes);
}
