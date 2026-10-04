import 'package:hijri/hijri_calendar.dart';
import 'app_settings.dart';

class Occasion {
  final String name;
  final int month;
  final List<int> days;
  final String kind;
  final String note;
  final String source;
  const Occasion(
    this.name,
    this.month,
    this.days,
    this.kind,
    this.note,
    this.source,
  );
}

const List<Occasion> kOccasions = [
  Occasion(
    'رأس السنة الهجرية',
    1,
    [1],
    'event',
    'بداية العام الهجري الجديد',
    '',
  ),
  Occasion(
    'تاسوعاء',
    1,
    [9],
    'fast',
    'يستحب صيام التاسع مع العاشر',
    'صحيح مسلم',
  ),
  Occasion(
    'عاشوراء',
    1,
    [10],
    'fast',
    'صيام يوم عاشوراء من السنة',
    'صحيح مسلم',
  ),
  Occasion(
    'بداية شهر رمضان',
    9,
    [1],
    'event',
    'أول أيام الصيام حسب التقويم الحسابي، تأكد من الإعلان الرسمي',
    'القرآن الكريم: البقرة 185',
  ),
  Occasion(
    'العشر الأواخر من رمضان',
    9,
    [21, 22, 23, 24, 25, 26, 27, 28, 29, 30],
    'season',
    'أيام الاجتهاد في العبادة وطلب ليلة القدر',
    'متفق عليه',
  ),
  Occasion(
    'عيد الفطر',
    10,
    [1],
    'eid',
    'يحرم صيام هذا اليوم، والتاريخ حسب التقويم الحسابي',
    'متفق عليه',
  ),
  Occasion(
    'ست من شوال',
    10,
    [
      2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, //
      21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
    ],
    'season',
    'يستحب صيام ست أيام من شوال',
    'صحيح مسلم',
  ),
  Occasion(
    'العشر من ذي الحجة',
    12,
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    'season',
    'أيام العمل الصالح الفاضلة',
    'صحيح البخاري',
  ),
  Occasion(
    'يوم عرفة',
    12,
    [9],
    'fast',
    'يستحب صيامه لغير الحاج',
    'صحيح مسلم',
  ),
  Occasion(
    'عيد الأضحى',
    12,
    [10],
    'eid',
    'يحرم صيام هذا اليوم، والتاريخ حسب التقويم الحسابي',
    'متفق عليه',
  ),
  Occasion(
    'أيام التشريق',
    12,
    [11, 12, 13],
    'noFast',
    'أيام أكل وشرب وذكر لله، لا يُصام فيها',
    'صحيح مسلم',
  ),
  Occasion(
    'الأيام البيض',
    0,
    [13, 14, 15],
    'fast',
    'من سنن الصيام الشهرية',
    'سنن الترمذي والنسائي',
  ),
];

HijriCalendar hijriOf(DateTime g) {
  final d = DateTime(
    g.year,
    g.month,
    g.day + AppSettings.hijriOffset.value,
    12,
  );
  return HijriCalendar.fromDate(d);
}

bool isMonThu(DateTime d) =>
    d.weekday == DateTime.monday || d.weekday == DateTime.thursday;

List<Occasion> occasionsOn(DateTime g) {
  final h = hijriOf(g);
  return [
    for (final o in kOccasions)
      if ((o.month == 0 || o.month == h.hMonth) && o.days.contains(h.hDay)) o,
  ];
}

class Upcoming {
  final Occasion o;
  final DateTime date;
  final int inDays;
  const Upcoming(this.o, this.date, this.inDays);
}

List<Upcoming> upcomingOccasions({int maxDays = 400}) {
  final now = DateTime.now();
  final out = <Upcoming>[];
  final found = <Occasion>{};
  for (var i = 0; i <= maxDays && found.length < kOccasions.length; i++) {
    final d = DateTime(now.year, now.month, now.day + i);
    final h = hijriOf(d);
    for (final o in kOccasions) {
      if (found.contains(o)) continue;
      if ((o.month == 0 || o.month == h.hMonth) && o.days.contains(h.hDay)) {
        found.add(o);
        out.add(Upcoming(o, d, i));
      }
    }
  }
  out.sort((a, b) => a.inDays.compareTo(b.inDays));
  return out;
}
