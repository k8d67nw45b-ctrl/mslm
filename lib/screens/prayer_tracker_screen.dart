import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'prayer_helpers.dart';
import 'prayer_logic.dart';
import 'prayer_tracker_service.dart';
import 'qada_screen.dart';

const _wd = [
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];

class _Opt {
  final int state;
  final String label;
  final IconData icon;
  final Color color;
  const _Opt(this.state, this.label, this.icon, this.color);
}

class PrayerTrackerScreen extends StatefulWidget {
  const PrayerTrackerScreen({Key? key}) : super(key: key);

  @override
  State<PrayerTrackerScreen> createState() => _PrayerTrackerScreenState();
}

class _PrayerTrackerScreenState extends State<PrayerTrackerScreen> {
  late DateTime sel;
  List<int> day = List.filled(5, 0);
  List<int> qada = List.filled(5, 0);
  List<List<int>> week = [];
  int streak = 0;
  PrayerData? pd;

  bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    sel = DateTime(n.year, n.month, n.day);
    _load();
    _loadTimes();
  }

  Future<void> _loadTimes() async {
    try {
      final d = await loadPrayerData();
      if (mounted) setState(() => pd = d);
    } catch (_) {}
  }

  Future<void> _load() async {
    final d = await loadDay(sel);
    final q = await loadQada();
    final w = await loadWeek();
    final s = await perfectStreak();
    if (!mounted) return;
    setState(() {
      day = d;
      qada = q;
      week = w;
      streak = s;
    });
  }

  List<DateTime>? get _times {
    final p = pd;
    if (p == null) return null;
    final t = p.times;
    return [t.fajr, t.dhuhr, t.asr, t.maghrib, t.isha];
  }

  bool _locked(int i) {
    if (!_same(sel, DateTime.now())) return false;
    final t = _times;
    if (t == null) return false;
    return t[i].isAfter(DateTime.now());
  }

  void _choose(int i) {
    if (_locked(i)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم يحن وقت هذه الصلاة بعد')),
      );
      return;
    }
    const opts = [
      _Opt(1, 'صليت', Icons.check_circle, kGreen),
      _Opt(2, 'صليت بالجماعة', Icons.groups, kGreen),
      _Opt(3, 'فاتتني (تُضاف للقضاء)', Icons.cancel, Colors.redAccent),
      _Opt(0, 'مسح', Icons.radio_button_unchecked, Colors.grey),
    ];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'صلاة ${kPrayerNames[i]}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            for (final o in opts)
              ListTile(
                leading: Icon(o.icon, color: o.color),
                title: Text(o.label),
                onTap: () async {
                  Navigator.pop(ctx);
                  await setPrayerState(sel, i, o.state);
                  await _load();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusIcon(int s) {
    switch (s) {
      case 1:
        return const Icon(Icons.check_circle, color: kGreen);
      case 2:
        return const Icon(Icons.groups, color: kGreen);
      case 3:
        return const Icon(Icons.cancel, color: Colors.redAccent);
      default:
        return const Icon(Icons.radio_button_unchecked, color: Colors.grey);
    }
  }

  String _statusText(int s) {
    switch (s) {
      case 1:
        return 'صليت';
      case 2:
        return 'بالجماعة';
      case 3:
        return 'فاتتني';
      default:
        return 'لم تُسجَّل';
    }
  }

  Widget _dayChips() {
    final now = DateTime.now();
    return SizedBox(
      height: 64,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 6; i >= 0; i--)
            Builder(builder: (context) {
              final d = DateTime(now.year, now.month, now.day - i);
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text(
                    '${_wd[d.weekday - 1]}\n${d.day}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                  selected: _same(d, sel),
                  onSelected: (_) {
                    setState(() => sel = d);
                    _load();
                  },
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _weekRow() {
    final now = DateTime.now();
    return Row(
      children: [
        for (var i = 0; i < week.length; i++)
          Expanded(
            child: Builder(builder: (context) {
              final d = DateTime(now.year, now.month, now.day - (6 - i));
              final n = week[i].where((s) => s == 1 || s == 2).length;
              return Column(
                children: [
                  Text(
                    _wd[d.weekday - 1].substring(0, 2),
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kGreen.withOpacity(n / 5 * 0.85 + 0.05),
                    ),
                    child: Text(
                      '$n',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              );
            }),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final done = day.where((s) => s == 1 || s == 2).length;
    final jam = day.where((s) => s == 2).length;
    final owed = qada.fold<int>(0, (a, b) => a + b);
    final times = _times;
    final isToday = _same(sel, DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: const Text('متابعة الصلوات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QadaScreen()),
              );
              _load();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(kPaddingMedium),
        children: [
          _dayChips(),
          const SizedBox(height: kPaddingSmall),
          Card(
            color: kCardBackground,
            child: Padding(
              padding: const EdgeInsets.all(kPaddingMedium),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$done من 5',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: kGreen,
                          ),
                        ),
                        Text('بالجماعة: $jam'),
                      ],
                    ),
                  ),
                  if (streak > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: kGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text('🔥 $streak يوم كامل'),
                    ),
                ],
              ),
            ),
          ),
          for (var i = 0; i < 5; i++)
            Card(
              color: kCardBackground,
              child: ListTile(
                enabled: !_locked(i),
                leading: _statusIcon(day[i]),
                title: Text(kPrayerNames[i]),
                subtitle: Text(
                  isToday && times != null
                      ? '${fmtTime(times[i])} ${ampm(times[i])}  •  '
                          '${_statusText(day[i])}'
                      : _statusText(day[i]),
                ),
                trailing: _locked(i)
                    ? const Icon(Icons.lock_outline, size: 18)
                    : const Icon(Icons.edit_outlined, size: 18),
                onTap: () => _choose(i),
              ),
            ),
          const SizedBox(height: kPaddingSmall),
          Card(
            color: kCardBackground,
            child: Padding(
              padding: const EdgeInsets.all(kPaddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'آخر 7 أيام',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _weekRow(),
                ],
              ),
            ),
          ),
          Card(
            color: kCardBackground,
            child: ListTile(
              leading: const Icon(Icons.history, color: kGreen),
              title: const Text('قضاء الفوائت'),
              subtitle: Text('المتبقي: $owed صلاة'),
              trailing: const Icon(Icons.chevron_left, color: kGreen),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QadaScreen()),
                );
                _load();
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'التسجيل لمتابعتك الشخصية فقط، وبياناتك محفوظة على جوالك.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
