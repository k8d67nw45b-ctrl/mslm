import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import 'moon.dart';
import 'notification_service.dart';
import 'occasions.dart';

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
    return InkWell(
      onTap: () => _detail(d),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: kCardBackground,
          borderRadius: BorderRadius.circular(10),
          border: isToday ? Border.all(color: kGreen, width: 2) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${h.hDay}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${d.day}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
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
                    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
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

  Widget _calTab() {
    final today = DateTime.now();
    final first = _first(ref);
    final days = _monthDays(first);
    final last = days.last;
    final h0 = hijriOf(first);
    final lead = (first.weekday + 1) % 7;
    return ListView(
      padding: const EdgeInsets.all(kPaddingMedium),
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
                    '${_hm[h0.hMonth - 1]} ${h0.hYear}',
                    style: const TextStyle(
                      fontSize: 22,
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
        const SizedBox(height: 8),
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
        const SizedBox(height: 12),
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
        const SizedBox(height: 12),
        const Text(
          'التقويم حسابي (أم القرى) وقد يختلف بيوم عن رؤية الهلال بمنطقتك، '
          'وتقدر تعدّله من الإعدادات. أطوار القمر تقريبية للعرض فقط.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _occTile(Upcoming u) {
    final idx = kOccasions.indexOf(u.o);
    final h = hijriOf(u.date);
    final badge = u.inDays == 0 ? 'اليوم' : '${u.inDays}';
    return Card(
      color: kCardBackground,
      margin: const EdgeInsets.only(bottom: kPaddingSmall),
      child: ListTile(
        leading: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: kGreen.withOpacity(0.18),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                badge,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kGreen,
                ),
              ),
              if (u.inDays != 0)
                const Text('يوم', style: TextStyle(fontSize: 10)),
            ],
          ),
        ),
        title: Text(u.o.name),
        subtitle: Text(
          '${h.hDay} ${_hm[h.hMonth - 1]} • ${_gDate(u.date)}\n'
          '${u.o.note}'
          '${u.o.source.isEmpty ? '' : '\nالمصدر: ${u.o.source}'}',
          style: const TextStyle(fontSize: 12),
        ),
        isThreeLine: true,
        trailing: idx < 0
            ? null
            : Switch(
                value: on.contains(idx),
                activeColor: kGreen,
                onChanged: (v) => _toggle(idx, v),
              ),
      ),
    );
  }

  Widget _occTab() {
    return ListView(
      padding: const EdgeInsets.all(kPaddingMedium),
      children: [
        Card(
          color: kCardBackground,
          child: SwitchListTile(
            title: const Text('تذكير بصيام الاثنين والخميس'),
            subtitle: const Text('تنبيه مساء اليوم السابق'),
            value: weekly,
            activeColor: kGreen,
            onChanged: _toggleWeekly,
          ),
        ),
        const SizedBox(height: kPaddingSmall),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'المناسبات القادمة (فعّل الجرس للتذكير مساء اليوم السابق)',
            style: TextStyle(color: kGreen, fontWeight: FontWeight.bold),
          ),
        ),
        if (up.isEmpty) const Center(child: CircularProgressIndicator()),
        for (final u in up) _occTile(u),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('التقويم الهجري'),
          bottom: const TabBar(
            tabs: [Tab(text: 'التقويم'), Tab(text: 'المناسبات')],
          ),
        ),
        body: TabBarView(children: [_calTab(), _occTab()]),
      ),
    );
  }
}
