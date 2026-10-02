import 'package:adhan/adhan.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'location_service.dart';

const _names = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];

final FlutterLocalNotificationsPlugin _plugin =
    FlutterLocalNotificationsPlugin();
bool _ready = false;

Future<void> initNotifications() async {
  if (_ready) return;
  tz.setLocalLocation(tz.UTC);
  const android = AndroidInitializationSettings('ic_stat');
  await _plugin.initialize(const InitializationSettings(android: android));
  _ready = true;
}

Future<bool> requestNotificationPermissions() async {
  await initNotifications();
  final a = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  final ok = await a?.requestNotificationsPermission() ?? true;
  try {
    await a?.requestExactAlarmsPermission();
  } catch (_) {}
  return ok;
}

NotificationDetails _details(bool prayer) {
  return NotificationDetails(
    android: AndroidNotificationDetails(
      prayer ? 'prayer_times' : 'adhkar_reminders',
      prayer ? 'مواقيت الصلاة' : 'تذكير الأذكار',
      channelDescription:
          prayer ? 'تنبيه عند دخول وقت الصلاة' : 'تذكير بأذكار الصباح والمساء',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'ic_stat',
    ),
  );
}

Future<void> _schedule(
  int id,
  String title,
  String body,
  DateTime at,
  bool prayer,
) async {
  final when = tz.TZDateTime.from(at, tz.UTC);
  try {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      _details(prayer),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  } catch (_) {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        when,
        _details(prayer),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }
}

Future<void> sendTestNotification() async {
  await initNotifications();
  await _plugin.show(
    9999,
    'رفيق المسلم',
    'تم تفعيل التنبيهات بنجاح',
    _details(true),
  );
}

Future<void> rescheduleAll({bool force = false}) async {
  await initNotifications();
  final p = await SharedPreferences.getInstance();
  final prayersOn = p.getBool('n_prayers') ?? false;
  final morningOn = p.getBool('n_morning') ?? false;
  final eveningOn = p.getBool('n_evening') ?? false;
  if (!prayersOn && !morningOn && !eveningOn) {
    await _plugin.cancelAll();
    await p.setString('n_sig', '');
    return;
  }
  final loc = await getLocation();
  final before = p.getInt('n_before') ?? 0;
  final each = [for (var i = 0; i < 5; i++) p.getBool('n_p$i') ?? true];
  final now = DateTime.now();
  final sig = '${loc.lat.toStringAsFixed(2)},${loc.lon.toStringAsFixed(2)}'
      '|$prayersOn$morningOn$eveningOn|$before|${each.join()}'
      '|${now.year}-${now.month}-${now.day}';
  if (!force && p.getString('n_sig') == sig) return;

  await _plugin.cancelAll();
  final coords = Coordinates(loc.lat, loc.lon);
  final params = CalculationMethod.umm_al_qura.getParameters();
  params.madhab = Madhab.shafi;

  for (var d = 0; d < 7; d++) {
    final day = now.add(Duration(days: d));
    final t = PrayerTimes(coords, DateComponents.from(day), params);
    final times = [t.fajr, t.dhuhr, t.asr, t.maghrib, t.isha];
    if (prayersOn) {
      for (var k = 0; k < 5; k++) {
        if (!each[k]) continue;
        final at = times[k].subtract(Duration(minutes: before));
        if (at.isBefore(now)) continue;
        final title = before == 0
            ? 'حان وقت صلاة ${_names[k]}'
            : 'اقترب وقت صلاة ${_names[k]}';
        final body = before == 0
            ? 'حسب موقعك: ${loc.name}'
            : 'بقي $before دقائق على الأذان';
        await _schedule(d * 10 + k, title, body, at, true);
      }
    }
    if (morningOn) {
      final at = t.fajr.add(const Duration(minutes: 30));
      if (at.isAfter(now)) {
        await _schedule(
          d * 10 + 5,
          'أذكار الصباح',
          'حان وقت أذكار الصباح',
          at,
          false,
        );
      }
    }
    if (eveningOn) {
      final at = t.asr.add(const Duration(minutes: 30));
      if (at.isAfter(now)) {
        await _schedule(
          d * 10 + 6,
          'أذكار المساء',
          'حان وقت أذكار المساء',
          at,
          false,
        );
      }
    }
  }
  await p.setString('n_sig', sig);
}
