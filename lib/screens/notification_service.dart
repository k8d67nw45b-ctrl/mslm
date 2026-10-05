import 'package:adhan/adhan.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'app_settings.dart';
import 'location_service.dart';
import 'occasions.dart';

const _names = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];

const int kPrayer = 0;
const int kAdhkar = 1;
const int kWird = 2;
const int kOcc = 3;
const int kAdhan = 4;
const int kFajr = 5;

final FlutterLocalNotificationsPlugin _plugin =
    FlutterLocalNotificationsPlugin();
bool _ready = false;
String lastNotifError = '';

String _two(int n) => n.toString().padLeft(2, '0');

class PendingItem {
  final String title;
  final String when;
  final DateTime sort;
  const PendingItem(this.title, this.when, this.sort);
}

class NotifStatus {
  final bool? enabled;
  final bool? exact;
  final int pending;
  final String error;
  final List<PendingItem> items;
  const NotifStatus(
    this.enabled,
    this.exact,
    this.pending,
    this.error,
    this.items,
  );
}

AndroidFlutterLocalNotificationsPlugin? get _android =>
    _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

Future<void> initNotifications() async {
  if (_ready) return;
  tz.setLocalLocation(tz.UTC);
  const android = AndroidInitializationSettings('ic_stat');
  await _plugin.initialize(const InitializationSettings(android: android));
  _ready = true;
}

Future<bool> requestNotificationPermissions() async {
  await initNotifications();
  return await _android?.requestNotificationsPermission() ?? true;
}

Future<void> requestExactAlarms() async {
  await initNotifications();
  try {
    await _android?.requestExactAlarmsPermission();
  } catch (e) {
    lastNotifError = '$e';
  }
}

Future<NotifStatus> notifStatus() async {
  await initNotifications();
  final a = _android;
  bool? enabled;
  bool? exact;
  var pending = 0;
  final items = <PendingItem>[];
  try {
    enabled = await a?.areNotificationsEnabled();
  } catch (_) {}
  try {
    exact = await a?.canScheduleExactNotifications();
  } catch (_) {}
  try {
    final list = await _plugin.pendingNotificationRequests();
    pending = list.length;
    for (final r in list) {
      final pl = r.payload ?? '';
      final title = r.title ?? '';
      if (pl.startsWith('daily|')) {
        items.add(PendingItem(
          title,
          'يومياً ${pl.substring(6)}',
          DateTime.fromMillisecondsSinceEpoch(0),
        ));
      } else {
        final t = DateTime.tryParse(pl);
        if (t == null) continue;
        final l = t.toLocal();
        items.add(PendingItem(
          title,
          '${l.day}/${l.month} ${_two(l.hour)}:${_two(l.minute)}',
          l,
        ));
      }
    }
    items.sort((x, y) => x.sort.compareTo(y.sort));
  } catch (_) {}
  return NotifStatus(enabled, exact, pending, lastNotifError, items);
}

NotificationDetails _details(int kind) {
  const ids = [
    'prayer_times_v2',
    'adhkar_reminders_v2',
    'wird_reminders_v2',
    'occasions_reminders_v2',
    'adhan_madinah_v1',
    'adhan_fajr_v1',
  ];
  const titles = [
    'تنبيهات الصلاة',
    'تذكير الأذكار',
    'ورد القرآن',
    'المناسبات',
    'أذان المدينة المنورة',
    'أذان الفجر',
  ];
  AndroidNotificationSound? sound;
  var usage = AudioAttributesUsage.notification;
  if (kind == kAdhan) {
    sound = RawResourceAndroidNotificationSound('adhan_madinah');
    usage = AudioAttributesUsage.alarm;
  } else if (kind == kFajr) {
    sound = RawResourceAndroidNotificationSound('adhan_fajr');
    usage = AudioAttributesUsage.alarm;
  }
  return NotificationDetails(
    android: AndroidNotificationDetails(
      ids[kind],
      titles[kind],
      importance: Importance.max,
      priority: Priority.high,
      icon: 'ic_stat',
      playSound: true,
      sound: sound,
      audioAttributesUsage: usage,
    ),
  );
}

Future<bool> _schedule(
  int id,
  String title,
  String body,
  DateTime at,
  int kind, {
  bool daily = false,
}) async {
  final when = tz.TZDateTime.from(at, tz.UTC);
  final l = at.toLocal();
  final payload =
      daily ? 'daily|${_two(l.hour)}:${_two(l.minute)}' : at.toUtc().toIso8601String();
  Future<void> go(AndroidScheduleMode mode) {
    return _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      _details(kind),
      androidScheduleMode: mode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: daily ? DateTimeComponents.time : null,
      payload: payload,
    );
  }

  try {
    await go(AndroidScheduleMode.exactAllowWhileIdle);
    return true;
  } catch (e) {
    lastNotifError = '$e';
    try {
      await go(AndroidScheduleMode.inexactAllowWhileIdle);
      return true;
    } catch (e2) {
      lastNotifError = '$e2';
      return false;
    }
  }
}

DateTime _nextAt(int minutes, DateTime now) {
  var d = DateTime(now.year, now.month, now.day, minutes ~/ 60, minutes % 60);
  if (!d.isAfter(now)) {
    d = DateTime(now.year, now.month, now.day + 1, minutes ~/ 60, minutes % 60);
  }
  return d;
}

Future<String?> sendTest(int kind) async {
  try {
    await initNotifications();
    final body = kind == kFajr
        ? 'تجربة أذان الفجر'
        : kind == kAdhan
            ? 'تجربة أذان المدينة المنورة'
            : 'تم تفعيل التنبيهات بنجاح';
    await _plugin.show(9990 + kind, 'رفيق المسلم', body, _details(kind));
    return null;
  } catch (e) {
    lastNotifError = '$e';
    return '$e';
  }
}

Future<String?> scheduleTestIn(int seconds, int kind) async {
  try {
    await initNotifications();
    final at = DateTime.now().add(Duration(seconds: seconds));
    final ok = await _schedule(
      9980 + kind,
      'رفيق المسلم',
      'نجحت الجدولة، التنبيهات المؤجلة تعمل',
      at,
      kind,
    );
    return ok ? null : lastNotifError;
  } catch (e) {
    lastNotifError = '$e';
    return '$e';
  }
}

Future<bool> enableDefaultNotifications() async {
  final p = await SharedPreferences.getInstance();
  await p.setBool('n_prayers', true);
  await p.setBool('n_morning', true);
  await p.setBool('n_evening', true);
  final ok = await requestNotificationPermissions();
  await requestExactAlarms();
  try {
    await rescheduleAll(force: true);
  } catch (_) {}
  return ok;
}

Future<int> _scheduleOccasions(SharedPreferences p, DateTime now) async {
  var count = 0;
  final weekly = p.getBool('occ_weekly') ?? false;
  final enabled = [
    for (var i = 0; i < kOccasions.length; i++) p.getBool('occ_on_$i') ?? false,
  ];
  for (var d = 1; d <= 8; d++) {
    final day = DateTime(now.year, now.month, now.day + d);
    final at = DateTime(day.year, day.month, day.day - 1, 20, 0);
    if (at.isBefore(now)) continue;
    for (final o in occasionsOn(day)) {
      final i = kOccasions.indexOf(o);
      if (i < 0 || !enabled[i]) continue;
      if (await _schedule(
        200 + d * 20 + i,
        'غداً: ${o.name}',
        o.note,
        at,
        kOcc,
      )) {
        count++;
      }
    }
    if (weekly && isMonThu(day)) {
      final nm = day.weekday == DateTime.monday ? 'الاثنين' : 'الخميس';
      if (await _schedule(
        200 + d * 20 + 19,
        'غداً يوم $nm',
        'يستحب صيامه',
        at,
        kOcc,
      )) {
        count++;
      }
    }
  }
  return count;
}

Future<int> rescheduleAll({bool force = false}) async {
  await initNotifications();
  final p = await SharedPreferences.getInstance();
  final prayersOn = p.getBool('n_prayers') ?? false;
  final morningOn = p.getBool('n_morning') ?? false;
  final eveningOn = p.getBool('n_evening') ?? false;
  final adhanOn = p.getBool('n_adhan_sound') ?? true;
  final mMin = p.getInt('n_morning_min') ?? 6 * 60 + 30;
  final eMin = p.getInt('n_evening_min') ?? 17 * 60 + 30;
  final khOn =
      (p.getBool('kh_active') ?? false) && (p.getBool('kh_remind') ?? false);
  final occOn = (p.getBool('occ_weekly') ?? false) ||
      [
        for (var i = 0; i < kOccasions.length; i++)
          p.getBool('occ_on_$i') ?? false,
      ].any((b) => b);
  final other = morningOn || eveningOn || khOn || occOn;
  if (!prayersOn && !other) {
    await _plugin.cancelAll();
    await p.setString('n_sig', '');
    return 0;
  }

  LatLon? loc;
  if (prayersOn) {
    try {
      loc = await getLocation();
    } catch (_) {
      if (!other) rethrow;
    }
  }

  final before = p.getInt('n_before') ?? 0;
  final each = [for (var i = 0; i < 5; i++) p.getBool('n_p$i') ?? true];
  final khTime = p.getInt('kh_time') ?? 21 * 60;
  final now = DateTime.now();
  final occSig = [
    for (var i = 0; i < kOccasions.length; i++)
      (p.getBool('occ_on_$i') ?? false) ? '1' : '0',
  ].join();
  final sig = 'v3|${loc?.lat.toStringAsFixed(2)},${loc?.lon.toStringAsFixed(2)}'
      '|$prayersOn$morningOn$eveningOn$adhanOn|$mMin|$eMin|$before'
      '|${each.join()}|${now.year}-${now.month}-${now.day}'
      '|${p.getString('calc_method')}|${p.getString('madhab')}'
      '|${p.getDouble('angle_fajr')}|${p.getDouble('angle_isha')}'
      '|$khOn|$khTime|$occSig|${p.getBool('occ_weekly')}'
      '|${AppSettings.hijriOffset.value}';
  if (!force && p.getString('n_sig') == sig) return 0;

  await _plugin.cancelAll();
  var count = 0;

  if (prayersOn && loc != null) {
    final coords = Coordinates(loc.lat, loc.lon);
    final params = await loadCalcParams();
    for (var d = 0; d < 7; d++) {
      final day = now.add(Duration(days: d));
      final t = PrayerTimes(coords, DateComponents.from(day), params);
      final times = [t.fajr, t.dhuhr, t.asr, t.maghrib, t.isha];
      for (var k = 0; k < 5; k++) {
        if (!each[k]) continue;
        final at = times[k];
        final kind = adhanOn ? (k == 0 ? kFajr : kAdhan) : kPrayer;
        if (at.isAfter(now)) {
          if (await _schedule(
            d * 10 + k,
            'حان وقت صلاة ${_names[k]}',
            'حسب موقعك: ${loc.name}',
            at,
            kind,
          )) {
            count++;
          }
        }
        if (before > 0) {
          final pre = at.subtract(Duration(minutes: before));
          if (pre.isAfter(now)) {
            if (await _schedule(
              700 + d * 10 + k,
              'اقترب وقت صلاة ${_names[k]}',
              'بقي $before دقائق على الأذان',
              pre,
              kPrayer,
            )) {
              count++;
            }
          }
        }
      }
    }
  }

  if (morningOn) {
    if (await _schedule(
      300,
      'أذكار الصباح',
      'حان وقت أذكار الصباح',
      _nextAt(mMin, now),
      kAdhkar,
      daily: true,
    )) {
      count++;
    }
  }
  if (eveningOn) {
    if (await _schedule(
      301,
      'أذكار المساء',
      'حان وقت أذكار المساء',
      _nextAt(eMin, now),
      kAdhkar,
      daily: true,
    )) {
      count++;
    }
  }

  if (khOn) {
    for (var d = 0; d < 7; d++) {
      final at = DateTime(
        now.year,
        now.month,
        now.day + d,
        khTime ~/ 60,
        khTime % 60,
      );
      if (at.isBefore(now)) continue;
      if (await _schedule(
        100 + d,
        'ورد القرآن اليومي',
        'حان وقت وردك من القرآن لتكمل ختمتك',
        at,
        kWird,
      )) {
        count++;
      }
    }
  }

  if (occOn) {
    count += await _scheduleOccasions(p, now);
  }

  await p.setString('n_sig', sig);
  return count;
}
