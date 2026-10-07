import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import 'app_settings.dart';
import 'khatma_screen.dart';
import 'khatma_service.dart';
import 'location_service.dart';
import 'occasions.dart';
import 'prayer_helpers.dart';

const _wd = [
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];

String _t(DateTime d) => '${fmtTime(d)} ${ampm(d)}';

class _RDay {
  final int n;
  final DateTime date;
  final DateTime fajr;
  final DateTime maghrib;
  const _RDay(this.n, this.date, this.fajr, this.maghrib);
}

class _Cd extends StatefulWidget {
  final _RDay today;
  final DateTime nextFajr;
  final int margin;
  const _Cd({
    Key? key,
    required this.today,
    required this.nextFajr,
    required this.margin,
  }) : super(key: key);

  @override
  State<_Cd> createState() => _CdState();
}

class _CdState extends State<_Cd> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final m = Duration(minutes: widget.margin);
    final imsak = widget.today.fajr.subtract(m);
    DateTime target;
    String label;
    if (now.isBefore(imsak)) {
      target = imsak;
      label = 'باقي على الإمساك';
    } else if (now.isBefore(widget.today.maghrib)) {
      target = widget.today.maghrib;
      label = 'باقي على الإفطار';
    } else {
      target = widget.nextFajr.subtract(m);
      label = 'باقي على إمساك الغد';
    }
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        Text(
          hms(target.difference(now)),
          style: const TextStyle(
            color: Color(0xFFB6F36B),
            fontSize: 38,
            fontWeight: FontWeight.bold,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class RamadanScreen extends StatefulWidget {
  const RamadanScreen({Key? key}) : super(key: key);

  @override
  State<RamadanScreen> createState() => _RamadanScreenState();
}

class _RamadanScreenState extends State<RamadanScreen> {
  bool loading = true;
  String? error;
  String place = '';
  List<_RDay> days = [];
  int hYear = 0;
  int todayIdx = -1;
  int daysToStart = 0;
  DateTime? start;
  Map<int, int> fast = {};
  int margin = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final p = await SharedPreferences.getInstance();
      final loc = await getLocation();
      final params = await loadCalcParams();
      final coords = Coordinates(loc.lat, loc.lon);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final h = hijriOf(today);
      DateTime? st;
      var toStart = 0;
      if (h.hMonth == 9) {
        st = DateTime(today.year, today.month, today.day - (h.hDay - 1));
      } else {
        for (var i = 1; i <= 400; i++) {
          final d = DateTime(today.year, today.month, today.day + i);
          final x = hijriOf(d);
          if (x.hMonth == 9 && x.hDay == 1) {
            st = d;
            toStart = i;
            break;
          }
        }
      }
      if (st == null) throw 'تعذّر تحديد بداية رمضان';
      final yr = hijriOf(st).hYear;
      final list = <_RDay>[];
      for (var n = 0; n < 30; n++) {
        final d = DateTime(st.year, st.month, st.day + n);
        if (hijriOf(d).hMonth != 9) break;
        final t = PrayerTimes(coords, DateComponents.from(d), params);
        list.add(_RDay(n + 1, d, t.fajr, t.maghrib));
      }
      final f = <int, int>{};
      for (final x in list) {
        final v = p.getString('ram_${yr}_${x.n}');
        if (v == '1') f[x.n] = 1;
        if (v == '2') f[x.n] = 2;
      }
      final idx = list.indexWhere((x) => x.date == today);
      if (!mounted) return;
      setState(() {
        place = loc.name;
        days = list;
        hYear = yr;
        todayIdx = idx;
        daysToStart = toStart;
        start = st;
        fast = f;
        margin = p.getInt('ram_imsak') ?? 0;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = '$e';
        loading = false;
      });
    }
  }

  Future<void> _setMargin(int m) async {
    setState(() => margin = m);
    final p = await SharedPreferences.getInstance();
    await p.setInt('ram_imsak', m);
  }

  Future<void> _cycle(_RDay x) async {
    final n = DateTime.now();
    final td = DateTime(n.year, n.month, n.day);
    if (x.date.isAfter(td)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم يحن هذا اليوم بعد')),
      );
      return;
    }
    final cur = fast[x.n] ?? 0;
    final nxt = (cur + 1) % 3;
    final p = await SharedPreferences.getInstance();
    final k = 'ram_${hYear}_${x.n}';
    if (nxt == 0) {
      await p.remove(k);
    } else {
      await p.setString(k, '$nxt');
    }
    setState(() {
      if (nxt == 0) {
        fast.remove(x.n);
      } else {
        fast[x.n] = nxt;
      }
    });
  }

  Future<void> _startKhatma() async {
    final k = await loadKhatma();
    if (k.active) {
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('ختمة رمضان'),
          content: const Text(
            'عندك ختمة جارية، والبدء بختمة جديدة يمسح تقدّمها. متأكد؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ابدأ'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    await startKhatma(30);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const KhatmaScreen()),
    );
  }

  Widget _hero() {
    final inRam = todayIdx >= 0;
    final s = start;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B3B2E), Color(0xFF1B2447)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            'رمضان $hYear هـ',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(place, style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 14),
          if (inRam) ...[
            Text(
              'اليوم ${todayIdx + 1} من ${days.length}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            _Cd(
              today: days[todayIdx],
              nextFajr: todayIdx + 1 < days.length
                  ? days[todayIdx + 1].fajr
                  : days[todayIdx].fajr.add(const Duration(days: 1)),
              margin: margin,
            ),
            const SizedBox(height: 10),
            Text(
              'الإمساك ${_t(days[todayIdx].fajr.subtract(Duration(minutes: margin)))}'
              '   •   الإفطار ${_t(days[todayIdx].maghrib)}',
              style: const TextStyle(color: Colors.white70),
            ),
          ] else ...[
            Text(
              'باقي $daysToStart يوم',
              style: const TextStyle(
                color: Color(0xFFB6F36B),
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (s != null)
              Text(
                'يبدأ تقريباً ${s.day}/${s.month}/${s.year}',
                style: const TextStyle(color: Colors.white70),
              ),
          ],
        ],
      ),
    );
  }

  Widget _row(_RDay x) {
    final isToday = days.indexOf(x) == todayIdx;
    final st = fast[x.n] ?? 0;
    final m = Duration(minutes: margin);
    Widget icon;
    if (st == 1) {
      icon = const Icon(Icons.check_circle, color: kGreen);
    } else if (st == 2) {
      icon = const Icon(Icons.cancel, color: Colors.redAccent);
    } else {
      icon = const Icon(Icons.radio_button_unchecked, color: Colors.grey);
    }
    return Card(
      color: isToday ? kGreen.withOpacity(0.18) : kCardBackground,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        onTap: () => _cycle(x),
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: kGreen,
          child: Text(
            '${x.n}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        title: Text('${_wd[x.date.weekday - 1]} ${x.date.day}/${x.date.month}'),
        subtitle: Text(
          'الإمساك ${_t(x.fajr.subtract(m))}   •   الإفطار ${_t(x.maghrib)}',
        ),
        trailing: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('رمضان')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('رمضان')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _load,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final fasted = fast.values.where((v) => v == 1).length;
    final missed = fast.values.where((v) => v == 2).length;
    return Scaffold(
      appBar: AppBar(title: const Text('رمضان')),
      body: ListView(
        padding: const EdgeInsets.all(kPaddingMedium),
        children: [
          _hero(),
          const SizedBox(height: kPaddingMedium),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startKhatma,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('ابدأ ختمة رمضان (30 يوماً)'),
            ),
          ),
          const SizedBox(height: kPaddingSmall),
          Card(
            color: kCardBackground,
            child: Padding(
              padding: const EdgeInsets.all(kPaddingMedium),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '$fasted',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: kGreen,
                          ),
                        ),
                        const Text('يوم صمته'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '$missed',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                        const Text('يوم عليّ قضاؤه'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('إمساك احتياطي قبل الفجر:'),
                for (final m in const [0, 5, 10])
                  ChoiceChip(
                    label: Text(m == 0 ? 'بدون' : '$m د'),
                    selected: margin == m,
                    onSelected: (_) => _setMargin(m),
                  ),
              ],
            ),
          ),
          const Text(
            'إمساكية رمضان (اضغط يوماً لتعليم صيامه)',
            style: TextStyle(color: kGreen, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (final x in days) _row(x),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'المواقيت محسوبة بطريقتك المختارة في الإعدادات، وبداية الشهر '
              'بالتقويم الحسابي (أم القرى) وقد تختلف يوماً عن الإعلان '
              'الرسمي حسب رؤية الهلال، فاعتمد إعلان جهتك.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
