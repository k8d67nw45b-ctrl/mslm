import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class LatLon {
  final double lat;
  final double lon;
  final String name;
  const LatLon(this.lat, this.lon, this.name);
}

class City {
  final String name;
  final double lat;
  final double lon;
  const City(this.name, this.lat, this.lon);
}

const List<City> cities = [
  City(
    'بغداد',
    33.3152,
    44.3661,
  ),
  City(
    'البصرة',
    30.5085,
    47.7804,
  ),
  City(
    'الموصل',
    36.3350,
    43.1189,
  ),
  City(
    'أربيل',
    36.1911,
    44.0092,
  ),
  City(
    'النجف',
    32.0000,
    44.3300,
  ),
  City(
    'كربلاء',
    32.6160,
    44.0249,
  ),
  City(
    'كركوك',
    35.4681,
    44.3922,
  ),
  City(
    'السليمانية',
    35.5558,
    45.4351,
  ),
  City(
    'دهوك',
    36.8670,
    42.9880,
  ),
  City(
    'الناصرية',
    31.0580,
    46.2573,
  ),
  City(
    'العمارة',
    31.8350,
    47.1440,
  ),
  City(
    'الديوانية',
    31.9900,
    44.9250,
  ),
  City(
    'الحلة',
    32.4637,
    44.4196,
  ),
  City(
    'الرمادي',
    33.4258,
    43.2992,
  ),
  City(
    'تكريت',
    34.6000,
    43.6800,
  ),
  City(
    'سامراء',
    34.1983,
    43.8742,
  ),
  City(
    'الكوت',
    32.5130,
    45.8180,
  ),
  City(
    'السماوة',
    31.3100,
    45.2800,
  ),
  City(
    'مكة المكرمة',
    21.4225,
    39.8262,
  ),
  City(
    'المدينة المنورة',
    24.4672,
    39.6111,
  ),
  City(
    'الرياض',
    24.7136,
    46.6753,
  ),
  City(
    'الكويت',
    29.3759,
    47.9774,
  ),
];

const int _staleMs = 6 * 3600 * 1000;

Future<LatLon?> _saved() async {
  final p = await SharedPreferences.getInstance();
  final la = p.getDouble('loc_lat');
  final lo = p.getDouble('loc_lon');
  if (la == null || lo == null) return null;
  return LatLon(la, lo, p.getString('loc_name') ?? '');
}

Future<void> _save(double la, double lo, String name, bool manual) async {
  final p = await SharedPreferences.getInstance();
  await p.setDouble('loc_lat', la);
  await p.setDouble('loc_lon', lo);
  await p.setString('loc_name', name);
  await p.setBool('loc_manual', manual);
  await p.setInt('loc_time', DateTime.now().millisecondsSinceEpoch);
}

Future<void> setManualCity(City c) => _save(c.lat, c.lon, c.name, true);

Future<void> clearManual() async {
  final p = await SharedPreferences.getInstance();
  await p.setBool('loc_manual', false);
  await p.setInt('loc_time', 0);
}

Future<LatLon> getLocation() async {
  final p = await SharedPreferences.getInstance();
  final saved = await _saved();
  if (saved != null) {
    if (p.getBool('loc_manual') ?? false) return saved;
    final t = p.getInt('loc_time') ?? 0;
    if (DateTime.now().millisecondsSinceEpoch - t < _staleMs) return saved;
  }
  try {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (enabled) {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm != LocationPermission.denied &&
          perm != LocationPermission.deniedForever) {
        Position? pos;
        try {
          pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 8),
            ),
          );
        } catch (_) {
          pos = await Geolocator.getLastKnownPosition();
        }
        if (pos != null) {
          await _save(pos.latitude, pos.longitude, 'موقعك الحالي', false);
          return LatLon(pos.latitude, pos.longitude, 'موقعك الحالي');
        }
      }
    }
  } catch (_) {}
  if (saved != null) return saved;
  throw 'تعذّر تحديد موقعك. اختر مدينتك يدوياً';
}

Future<bool> showCityPicker(BuildContext context) async {
  final r = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      builder: (c, controller) => ListView(
        controller: controller,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'اختر مدينتك',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.my_location, color: kGreen),
            title: const Text('تحديد تلقائي (GPS)'),
            onTap: () async {
              await clearManual();
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
          ),
          for (final city in cities)
            ListTile(
              title: Text(city.name),
              onTap: () async {
                await setManualCity(city);
                if (ctx.mounted) Navigator.pop(ctx, true);
              },
            ),
        ],
      ),
    ),
  );
  return r ?? false;
}
