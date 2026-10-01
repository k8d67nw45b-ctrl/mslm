import 'package:adhan/adhan.dart';

class NextInfo {
  final String name;
  final DateTime time;
  const NextInfo(this.name, this.time);
}

NextInfo nextOf(PrayerTimes t) {
  final now = DateTime.now();
  final list = <NextInfo>[
    NextInfo('الفجر', t.fajr),
    NextInfo('الظهر', t.dhuhr),
    NextInfo('العصر', t.asr),
    NextInfo('المغرب', t.maghrib),
    NextInfo('العشاء', t.isha),
  ];
  for (final e in list) {
    if (e.time.isAfter(now)) return e;
  }
  return NextInfo('الفجر', t.fajr.add(const Duration(days: 1)));
}

DateTime midnightOf(PrayerTimes t) {
  final fajrNext = t.fajr.add(const Duration(days: 1));
  return t.maghrib.add(fajrNext.difference(t.maghrib) ~/ 2);
}

String fmtTime(DateTime d) {
  final l = d.toLocal();
  final h = l.hour % 12 == 0 ? 12 : l.hour % 12;
  final m = l.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String ampm(DateTime d) => d.toLocal().hour < 12 ? 'AM' : 'PM';

String two(int n) => n.toString().padLeft(2, '0');

String hms(Duration d) {
  final s = d.isNegative ? Duration.zero : d;
  return '${two(s.inHours)}:${two(s.inMinutes % 60)}:${two(s.inSeconds % 60)}';
}
