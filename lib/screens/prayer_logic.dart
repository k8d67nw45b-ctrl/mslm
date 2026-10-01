import 'package:adhan/adhan.dart';
import 'location_service.dart';

class PrayerData {
  final PrayerTimes times;
  final String next;
  final String place;
  PrayerData(this.times, this.next, this.place);
}

Future<PrayerData> loadPrayerData() async {
  final loc = await getLocation();
  final coords = Coordinates(loc.lat, loc.lon);
  final params = CalculationMethod.umm_al_qura.getParameters();
  params.madhab = Madhab.shafi;
  final times = PrayerTimes.today(coords, params);
  return PrayerData(times, _nextName(times), loc.name);
}

String _nextName(PrayerTimes t) {
  switch (t.nextPrayer()) {
    case Prayer.fajr:
      return 'الفجر';
    case Prayer.sunrise:
      return 'الشروق';
    case Prayer.dhuhr:
      return 'الظهر';
    case Prayer.asr:
      return 'العصر';
    case Prayer.maghrib:
      return 'المغرب';
    case Prayer.isha:
      return 'العشاء';
    default:
      return 'الفجر';
  }
}
