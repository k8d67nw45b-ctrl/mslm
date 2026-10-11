import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'growth_service.dart' show stageOf, kStageDays;
import 'prayer_tracker_service.dart' show perfectStreak;
import 'stats_service.dart' show dayKey, loadStreak;

const List<int> kPlantDays = [0, 1, 3, 7, 15, 30];
const List<String> kPlantStages = [
  'بذرة',
  'برعم',
  'نبتة',
  'تتفتح',
  'مزهرة',
  'مزدهرة',
];

int plantLevel(int days) {
  var s = 0;
  for (var i = 1; i < kPlantDays.length; i++) {
    if (days >= kPlantDays[i]) s = i;
  }
  return s;
}

class GardenData {
  final int quranDays;
  final int adhkarDays;
  final int prayerDays;
  final int totalDays;
  final int streak;
  final int perfectDays;
  final bool quranToday;
  final bool adhkarToday;
  final int prayersToday;
  const GardenData({
    required this.quranDays,
    required this.adhkarDays,
    required this.prayerDays,
    required this.totalDays,
    required this.streak,
    required this.perfectDays,
    required this.quranToday,
    required this.adhkarToday,
    required this.prayersToday,
  });
}

Future<GardenData> loadGarden() async {
  final p = await SharedPreferences.getInstance();
  final today = dayKey(DateTime.now());
  final quran = <String>{};
  final adhkar = <String>{};
  final prayer = <String>{};
  for (final k in p.getKeys()) {
    if (k.startsWith('st_pages_')) {
      final l = p.getStringList(k);
      if (l != null && l.isNotEmpty) quran.add(k.substring(9));
    } else if (k.startsWith('st_tasbih_')) {
      if ((p.getInt(k) ?? 0) > 0) adhkar.add(k.substring(10));
    } else if (k.startsWith('dadhkar_m_') || k.startsWith('dadhkar_e_')) {
      if ((p.getInt(k) ?? 0) > 0) {
        final rest = k.substring(10);
        final i = rest.lastIndexOf('_');
        if (i > 0) adhkar.add(rest.substring(0, i));
      }
    } else if (k.startsWith('pt_')) {
      final s = p.getString(k) ?? '';
      if (s.contains('1') || s.contains('2')) prayer.add(k.substring(3));
    }
  }
  final all = <String>{...quran, ...adhkar, ...prayer};
  final ts = p.getString('pt_$today') ?? '';
  var pToday = 0;
  for (var i = 0; i < ts.length && i < 5; i++) {
    if (ts[i] == '1' || ts[i] == '2') pToday++;
  }
  return GardenData(
    quranDays: quran.length,
    adhkarDays: adhkar.length,
    prayerDays: prayer.length,
    totalDays: all.length,
    streak: await loadStreak(),
    perfectDays: await perfectStreak(),
    quranToday: quran.contains(today),
    adhkarToday: adhkar.contains(today),
    prayersToday: pToday,
  );
}

class GardenBadge {
  final String title;
  final String hint;
  final IconData icon;
  final bool got;
  const GardenBadge(this.title, this.hint, this.icon, this.got);
}

List<GardenBadge> badgesOf(GardenData g) => [
      GardenBadge('البداية', 'أول يوم نشاط', Icons.spa, g.totalDays >= 1),
      GardenBadge('أسبوع متواصل', '7 أيام متتالية',
          Icons.local_fire_department, g.streak >= 7),
      GardenBadge('شهر متواصل', '30 يوماً متتالية', Icons.whatshot,
          g.streak >= 30),
      GardenBadge('صديق القرآن', '30 يوم قراءة', Icons.menu_book,
          g.quranDays >= 30),
      GardenBadge('ذاكر', '30 يوم أذكار', Icons.auto_awesome,
          g.adhkarDays >= 30),
      GardenBadge('محافظ على الصلاة', '30 يوم صلاة', Icons.mosque,
          g.prayerDays >= 30),
      GardenBadge('يوم كامل', 'خمس صلوات في يوم', Icons.check_circle,
          g.perfectDays >= 1),
      GardenBadge('حديقة مثمرة', 'أعلى مرحلة', Icons.park,
          stageOf(g.totalDays) >= kStageDays.length - 1),
    ];

String gardenShareText(GardenData g) =>
    '🌿 حديقتي الإيمانية في تطبيق رفيق المسلم\n'
    '🌱 أيام النشاط: ${g.totalDays}\n'
    '🔥 الأيام المتتالية: ${g.streak}\n'
    '📖 قرآن: ${g.quranDays} يوم\n'
    '📿 أذكار: ${g.adhkarDays} يوم\n'
    '🕌 صلاة: ${g.prayerDays} يوم\n'
    'تعال نتسابق بالخير!';
