import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import 'moon.dart';
import 'notification_service.dart';
import 'occasions.dart';
import 'rf_design.dart';
import 'rf_page.dart';

const _hm = [
  'محرم',
  'صفر',
  'ربيع الأول',
  'ربيع الآخر',
  'جمادى الأولى',
  'جمادى الآخرة',
  'رجب',
  'شعبان',
  'رمضان',
  'شوال',
  'ذو القعدة',
  'ذو الحجة',
];
const _gm = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];
const _wd = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];
const _wdFull = [
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];

String _hDate(DateTime g) {
  final h = hijriOf(g);
  return '${h.hDay} ${_hm[h.hMonth - 1]} ${h.hYear}';
}

String _gDate(DateTime g) => '${g.day} ${_gm[g.month - 1]} ${g.year}';

IconData _kindIcon(String k) {
  switch (k) {
    case 'fast':
      return Icons.nightlight_round;
    case 'season':
      return Icons.star;
    case 'eid':
      return Icons.celebration;
    case 'noFast':
      return Icons.no_food;
    default:
      return Icons.event;
  }
}

class _MoonMini extends CustomPainter {
  final double age;
  _MoonMini(this.age);

  @override
  void paint(Canvas canvas, Size size) {
    paintMoon(
      canvas,
      Offset(size.width / 2, size.height / 2),
      size.width / 2 - 1,
      age,
      lit: const Color(0xFFE8D9A8),
      dark: const Color(0x55888888),
    );
  }

  @override
  bool shouldRepaint(_MoonMini old) => old.age != age;
}

class HijriCalendarScreen extends StatefulWidget {
  const HijriCalendarScreen({Key? key}) : super(key: key);

  @override
  State<HijriCalendarScreen> createState() => _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends State<HijriCalendarScreen> {
  DateTime ref = DateTime.now();
  List<Upcoming> up = [];
  Set<int> on = {};
  bool weekly = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => up = upcomingOccasions());
    });
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      weekly = p.getBool('occ_weekly') ?? false;
      on = {
        for (var i = 0; i < kOccasions.length; i++)
          if (p.getBool('occ_on_$i') ?? false) i,
      };
    });
  }

  Future<void> _resched() async {
    try {
      await rescheduleAll(force: true);
    } catch (_) {}
  }

  Future<void> _toggle(int idx, bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('occ_on_$idx', v);
    setState(() {
      if (v) {
        on.add(idx);
      } else {
        on.remove(idx);
      }
    });
    if (v) {
      try {
        await requestNotificationPermissions();
      } catch (_) {}
    }
    await _resched();
  }

  Future<void> _toggleWeekly(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('occ_weekly', v);
    setState(() => weekly = v);
    if (v) {
      try {
        await requestNotificationPermissions();
      } catch (_) {}
    }
    await _resched();
  }

  DateTime _first(DateTime d) {
    var x = DateTime(d.year, d.month, d.day);
    for (var i = 0; i < 31 && hijriOf(x).hDay != 1; i++) {
      x = DateTime(x.year, x.month, x.day - 1);
    }
    return x;
  }

  List<DateTime> _monthDays(DateTime first) {
    final hm = hijriOf(first).hMonth;
    final out = <DateTime>[];
    var x = first;
    while (out.length < 31 && hijriOf(x).hMonth == hm) {
      out.add(x);
      x = DateTime(x.year, x.month, x.day + 1);
    }
    return out;
  }

  List<Color> _dots(DateTime d) {
    final occ = occasionsOn(d);
    final out = <Color>[];
    if (occ.any((o) => o.kind == 'fast') || isMonThu(d)) out.add(kGreen);
    if (occ.any((o) => o.kind == 'season')) {
      out.add(const Color(0xFFD4AF37));
    }
    if (occ.any((o) => o.kind == 'eid' || o.kind == 'noFast')) {
      out.add(Colors.redAccent);
    }
    if (occ.any((o) => o.kind == 'event')) out.add(Colors.lightBlueAccent);
    return out;
  }

  void _detail(DateTime d) {
    final occ = occasionsOn(d);
    final age = moonAge(DateTime(d.year, d.month, d.day, 12));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _wdFull[d.weekday - 1],
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                Text(_hDate(d), style: const TextStyle(fontSize: 18)),
                Text(
                  _gDate(d),
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CustomPaint(painter: _MoonMini(age)),
                    ),
                    const SizedBox(width: 8),
                    Text('${moonName(age)} (للعرض فقط)'),
                  ],
                ),
                const SizedBox(height: 8),
                if (isMonThu(d))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'يوم ${d.weekday == DateTime.monday ? 'الاثنين' : 'الخميس'}'
                      ': يستحب صيامه',
                    ),
                    subtitle: const Text('المصدر: سنن الترمذي والنسائي'),
                  ),
                for (final o in occ)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(o.name),
                    subtitle: Text(
                      o.source.isEmpty
                          ? o.note
                          : '${o.note}\nالمصدر: ${o.source}',
                    ),
                  ),
                if (occ.isEmpty && !isMonThu(d))
                  const Text('لا مناسبات في هذا اليوم'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cell(DateTime d, DateTime today) {
    final h = hijriOf(d);
    final isToday =
        d.year == today.year && d.month == today.month && d.day == today.day;
    final age = moonAge(DateTime(d.year, d.month, d.day, 12));
    final fg = isToday ? Colors.white : null;
    return InkWell(
      onTap: () => _detail(d),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isToday ? kGreen : kGreen.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${h.hDay}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: fg,
              ),
            ),
            Text(
              '${d.day}',
              style: TextStyle(
                fontSize: 10,
                color: isToday ? Colors.white70 : Colors.grey,
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              width: 14,
              height: 14,
              child: CustomPaint(painter: _MoonMini(age)),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final c in _dots(d))
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: isToday ? Colors.white : c,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color c, String t) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(t, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _calendar() {
    final today = DateTime.now();
    final first = _first(ref);
    final days = _monthDays(first);
    final last = days.last;
    final h0 = hijriOf(first);
    final lead = (first.weekday + 1) % 7;
    return RfCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(
                  () => ref = DateTime(first.year, first.month, first.day - 1),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${_hm[h0.hMonth - 1]} ${h0.hYear} هـ',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_gm[first.month - 1]} ${first.year} - '
                      '${_gm[last.month - 1]} ${last.year}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(
                  () => ref = DateTime(last.year, last.month, last.day + 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final w in _wd)
                Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: const TextStyle(
                        color: kGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.74,
            children: [
              for (var i = 0; i < lead; i++) const SizedBox.shrink(),
              for (final d in days) _cell(d, today),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _legend(kGreen, 'صيام مستحب'),
              _legend(const Color(0xFFD4AF37), 'أيام فاضلة'),
              _legend(Colors.redAccent, 'لا يصام'),
              _legend(Colors.lightBlueAccent, 'حدث'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _occTile(Upcoming u) {
    final idx = kOccasions.indexOf(u.o);
    final h = hijriOf(u.date);
    final when = u.inDays == 0
        ? 'اليوم'
        : (u.inDays == 1 ? 'غداً' : 'بعد ${u.inDays} يوم');
    return RfCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      radius: 18,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: rfDeep,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_kindIcon(u.o.kind), color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  u.o.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$when • ${h.hDay} ${_hm[h.hMonth - 1]} ${h.hYear} هـ',
                  style: const TextStyle(color: kGreen, fontSize: 12),
                ),
                Text(
                  u.o.source.isEmpty
                      ? u.o.note
                      : '${u.o.note}\nالمصدر: ${u.o.source}',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          if (idx >= 0)
            Switch(
              value: on.contains(idx),
              activeColor: kGreen,
              onChanged: (v) => _toggle(idx, v),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = hijriOf(DateTime.now());
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          RfPageHeader(
            title: 'التقويم الإسلامي',
            subtitle: '${h.hDay} ${_hm[h.hMonth - 1]} ${h.hYear} هـ',
          ),
          _calendar(),
          RfCard(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: const Text('تذكير بصيام الاثنين والخميس'),
              subtitle: const Text('تنبيه مساء اليوم السابق'),
              secondary: const Icon(Icons.notifications_active, color: kGreen),
              value: weekly,
              activeColor: kGreen,
              onChanged: _toggleWeekly,
            ),
          ),
          const RfSection('المناسبات القادمة', icon: Icons.event),
          if (up.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          for (final u in up) _occTile(u),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'التقويم حسابي (أم القرى) وقد يختلف بيوم عن رؤية الهلال بمنطقتك، '
              'وتقدر تعدّله من الإعدادات. أطوار القمر تقريبية للعرض فقط. '
              'فعّل الجرس بجانب أي مناسبة ليذكّرك مساء اليوم السابق.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
