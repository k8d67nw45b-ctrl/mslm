import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';

class PrayerData {
  final PrayerTimes times;
  final String next;
  PrayerData(this.times, this.next);
}

Future<PrayerData> loadPrayerData() async {
  final enabled = await Geolocator.isLocationServiceEnabled();
  if (!enabled) {
    throw 'فعّل خدمة الموقع (GPS) بالجوال';
  }
  var perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    perm = await Geolocator.requestPermission();
  }
  if (perm == LocationPermission.denied ||
      perm == LocationPermission.deniedForever) {
    throw 'يلزم السماح بالوصول إلى الموقع';
  }
  final pos = await Geolocator.getCurrentPosition();
  final coords = Coordinates(pos.latitude, pos.longitude);
  final params = CalculationMethod.umm_al_qura.getParameters();
  params.madhab = Madhab.shafi;
  final times = PrayerTimes.today(coords, params);
  return PrayerData(times, _nextName(times));
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
