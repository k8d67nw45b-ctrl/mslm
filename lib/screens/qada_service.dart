import 'package:shared_preferences/shared_preferences.dart';
import 'prayer_tracker_service.dart' show addQada;

class FastQada {
  final int owed;
  final int done;
  const FastQada(this.owed, this.done);
}

class QadaPlan {
  final int daysPerDay;
  final int fastsPerWeek;
  const QadaPlan(this.daysPerDay, this.fastsPerWeek);
}

Future<List<int>> loadPrayerDone() async {
  final p = await SharedPreferences.getInstance();
  return [for (var i = 0; i < 5; i++) p.getInt('qada_done_$i') ?? 0];
}

Future<void> _changeDone(int i, int delta) async {
  final p = await SharedPreferences.getInstance();
  final v = (p.getInt('qada_done_$i') ?? 0) + delta;
  await p.setInt('qada_done_$i', v < 0 ? 0 : v);
}

Future<void> madeUpPrayer(int i) async {
  await addQada(i, -1);
  await _changeDone(i, 1);
}

Future<void> undoMadeUpPrayer(int i) async {
  await addQada(i, 1);
  await _changeDone(i, -1);
}

Future<FastQada> loadFast() async {
  final p = await SharedPreferences.getInstance();
  return FastQada(p.getInt('qf_owed') ?? 0, p.getInt('qf_done') ?? 0);
}

Future<void> addFastOwed(int n) async {
  if (n <= 0) return;
  final p = await SharedPreferences.getInstance();
  await p.setInt('qf_owed', (p.getInt('qf_owed') ?? 0) + n);
}

Future<void> madeUpFast() async {
  final p = await SharedPreferences.getInstance();
  final o = p.getInt('qf_owed') ?? 0;
  if (o <= 0) return;
  await p.setInt('qf_owed', o - 1);
  await p.setInt('qf_done', (p.getInt('qf_done') ?? 0) + 1);
}

Future<void> undoMadeUpFast() async {
  final p = await SharedPreferences.getInstance();
  final d = p.getInt('qf_done') ?? 0;
  if (d <= 0) return;
  await p.setInt('qf_done', d - 1);
  await p.setInt('qf_owed', (p.getInt('qf_owed') ?? 0) + 1);
}

Future<QadaPlan> loadPlan() async {
  final p = await SharedPreferences.getInstance();
  return QadaPlan(
    p.getInt('qada_plan_prayer') ?? 1,
    p.getInt('qada_plan_fast') ?? 1,
  );
}

Future<void> savePlan({int? daysPerDay, int? fastsPerWeek}) async {
  final p = await SharedPreferences.getInstance();
  if (daysPerDay != null && daysPerDay > 0) {
    await p.setInt('qada_plan_prayer', daysPerDay);
  }
  if (fastsPerWeek != null && fastsPerWeek > 0) {
    await p.setInt('qada_plan_fast', fastsPerWeek);
  }
}

Future<void> resetAllQada() async {
  final p = await SharedPreferences.getInstance();
  for (var i = 0; i < 5; i++) {
    await p.remove('qada_$i');
    await p.remove('qada_done_$i');
  }
  await p.remove('qf_owed');
  await p.remove('qf_done');
}
