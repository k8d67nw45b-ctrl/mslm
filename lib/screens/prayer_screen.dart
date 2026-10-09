import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../core/theme_controller.dart';
import 'app_settings.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'occasions.dart';
import 'prayer_helpers.dart';
import 'prayer_logic.dart';
import 'rf_design.dart';

class _S {
  final String name;
  final DateTime time;
  final IconData icon;
  const _S(this.name, this.time, this.icon);
}

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({Key? key}) : super(key: key);

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  late DateTime day;
  PrayerTimes? times;
  String place = '';
  String methodName = '';
  bool alerts = false;
  String? error;
  bool loading = true;
  NextInfo? next;
  final ValueNotifier<Duration> left = ValueNotifier<Duration>(Duration.zero);
  Timer? _timer;

  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    day = DateTime(n.year, n.month, n.day);
    _load();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    left.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = times == null;
      error = null;
    });
    try {
      final p = await SharedPreferences.getInstance();
      final loc = await getLocation();
      final params = await loadCalcParams();
      final t = PrayerTimes(
        Coordinates(loc.lat, loc.lon),
        DateComponents.from(day),
        params,
      );
      final m = p.getString('calc_method') ?? 'umm_al_qura';
      if (!mounted) return;
      setState(() {
        times = t;
        place = loc.name;
        methodName = calcMethodNames[m] ?? '';
        alerts = p.getBool('n_prayers') ?? false;
        loading = false;
        next = _isToday(day) ? nextOf(t) : null;
      });
      _tick();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = '$e';
        loading = false;
      });
    }
  }

  void _tick() {
    final n = next;
    final t = times;
    if (n == null || t == null || !mounted) return;
    final now = DateTime.now();
    if (!n.time.isAfter(now)) {
      setState(() => next = nextOf(t));
      return;
    }
    left.value = n.time.difference(now);
  }

  void _shift(int d) {
    setState(() {
      day = DateTime(day.year, day.month, day.day + d);
      next = null;
    });
    _load();
  }

  void _goToday() {
    final n = DateTime.now();
    setState(() {
      day = DateTime(n.year, n.month, n.day);
      next = null;
    });
    _load();
  }

  Future<void> _pickCity() async {
    final ok = await showCityPicker(context);
    if (!ok) return;
    await _load();
    try {
      await rescheduleAll(force: true);
    } catch (_) {}
  }

  Future<void> _setAlerts(bool v) async {
    setState(() => alerts = v);
    final p = await SharedPreferences.getInstance();
    await p.setBool('n_prayers', v);
    if (v) {
      try {
        await requestNotificationPermissions();
      } catch (_) {}
    }
    try {
      await rescheduleAll(force: true);
    } catch (_) {}
  }

  Widget _dateCard() {
    final h = hijriOf(day);
    return RfCard(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _shift(-1),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      rfHijriLine(h.hDay, h.hMonth, h.hYear),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      rfGregLine(day),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _shift(1),
              ),
            ],
          ),
          if (!_isToday(day))
            TextButton(onPressed: _goToday, child: const Text('العودة لليوم')),
          InkWell(
            onTap: _pickCity,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 18, color: kGreen),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      place.isEmpty ? 'تحديد الموقع' : place,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Text(' (تغيير)', style: TextStyle(color: kGreen)),
                ],
              ),
            ),
          ),
          if (methodName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'طريقة الحساب: $methodName',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _hero(PrayerTimes t) {
    final n = next;
    final name = n != null ? n.name : 'الفجر';
    final tm = n != null ? n.time : t.fajr;
    return RfCard(
      padding: const EdgeInsets.all(18),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF12806A), Color(0xFF0B4F44)],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                n != null ? 'الصلاة القادمة' : 'أول صلاة في اليوم',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${fmtTime(tm)} ${ampm(tm)}',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
          const Spacer(),
          if (n != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ValueListenableBuilder<Duration>(
                  valueListenable: left,
                  builder: (context, l, _) => Text(
                    hms(l),
                    style: const TextStyle(
                      color: rfLime,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const Text(
                  'متبقي على الأذان',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            )
          else
            const Icon(Icons.mosque, color: Colors.white54, size: 52),
        ],
      ),
    );
  }

  Widget _row(int i, _S s, bool hot) {
    return RfCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 18,
      color: hot ? kGreen.withOpacity(0.18) : null,
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: hot ? kGreen : kGreen.withOpacity(0.15),
            child: Text(
              '${i + 1}',
              style: TextStyle(
                fontSize: 12,
                color: hot ? Colors.white : kGreen,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(s.icon, color: rfGold, size: 22),
          const SizedBox(width: 10),
          Text(
            s.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: hot ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const Spacer(),
          Text(
            fmtTime(s.time),
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          Text(
            ampm(s.time),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = times;
    final slots = t == null
        ? <_S>[]
        : [
            _S('الفجر', t.fajr, Icons.nightlight_round),
            _S('الشروق', t.sunrise, Icons.wb_twilight),
            _S('الظهر', t.dhuhr, Icons.wb_sunny),
            _S('العصر', t.asr, Icons.light_mode),
            _S('المغرب', t.maghrib, Icons.nights_stay),
            _S('العشاء', t.isha, Icons.dark_mode),
          ];
    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        RfHeader(
          title: 'مواقيت الصلاة',
          subtitle: 'حسب موقعك وطريقتك المختارة',
          height: 130,
          trailing: IconButton(
            icon: const Icon(Icons.brightness_6, color: Colors.white),
            onPressed: ThemeController.toggle,
          ),
        ),
        if (loading)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (error != null)
          RfCard(
            child: Column(
              children: [
                Text(error!, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _pickCity,
                  child: const Text('اختيار المدينة'),
                ),
                TextButton(
                  onPressed: _load,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          )
        else if (t != null) ...[
          _dateCard(),
          _hero(t),
          for (var i = 0; i < slots.length; i++)
            _row(i, slots[i], next != null && next!.name == slots[i].name),
          RfCard(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: const Text('التذكير بالأذان'),
              subtitle: const Text('تنبيه عند دخول وقت كل صلاة'),
              secondary: const Icon(Icons.notifications_active, color: kGreen),
              value: alerts,
              activeColor: kGreen,
              onChanged: _setAlerts,
            ),
          ),
        ],
      ],
    );
  }
}
