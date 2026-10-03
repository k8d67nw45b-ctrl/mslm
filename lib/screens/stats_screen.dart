import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'stats_service.dart';

const _dn = [
  'الإثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Goals goals = const Goals(5, 100);
  DayStats? today;
  List<DayStats> week = [];
  int streak = 0;
  int mode = 0;
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final g = await loadGoals();
    final t = await loadToday();
    final w = await loadWeek();
    final s = await loadStreak();
    if (!mounted) return;
    setState(() {
      goals = g;
      today = t;
      week = w;
      streak = s;
      loaded = true;
    });
  }

  Widget _row(String label, String value, double v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label),
              const Spacer(),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: v.clamp(0.0, 1.0).toDouble(),
              minHeight: 8,
              color: kGreen,
              backgroundColor: kGreen.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepper(
    String label,
    String value,
    VoidCallback minus,
    VoidCallback plus,
  ) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: minus,
        ),
        SizedBox(
          width: 44,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: plus,
        ),
      ],
    );
  }

  Future<void> _editGoals() async {
    var pg = goals.pages;
    var tg = goals.tasbih;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('أهدافك اليومية'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _stepper(
                'صفحات القرآن',
                '$pg',
                () => set(() {
                  if (pg > 1) pg--;
                }),
                () => set(() {
                  if (pg < 100) pg++;
                }),
              ),
              _stepper(
                'التسبيح',
                '$tg',
                () => set(() {
                  tg = (tg - (tg > 100 ? 50 : 10)).clamp(10, 5000).toInt();
                }),
                () => set(() {
                  tg = (tg + (tg >= 100 ? 50 : 10)).clamp(10, 5000).toInt();
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      final g = Goals(pg, tg);
      await saveGoals(g);
      if (mounted) setState(() => goals = g);
    }
  }

  Widget _chart() {
    final vals = <double>[
      for (final d in week)
        mode == 0
            ? d.pages.toDouble()
            : mode == 1
                ? d.tasbih.toDouble()
                : d.adhkar * 100,
    ];
    var mx = mode == 0
        ? goals.pages.toDouble()
        : mode == 1
            ? goals.tasbih.toDouble()
            : 100.0;
    for (final v in vals) {
      if (v > mx) mx = v;
    }
    if (mx <= 0) mx = 1;
    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < vals.length; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    vals[i] == 0 ? '' : '${vals[i].round()}',
                    style: const TextStyle(fontSize: 10),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    height: 100 * (vals[i] / mx),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: i == vals.length - 1
                          ? kGreen
                          : kGreen.withOpacity(0.5),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _dn[week[i].day.weekday - 1],
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded || today == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('الإحصائيات')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final t = today!;
    return Scaffold(
      appBar: AppBar(title: const Text('الإحصائيات')),
      body: ListView(
        padding: const EdgeInsets.all(kPaddingMedium),
        children: [
          Card(
            color: kCardBackground,
            child: ListTile(
              leading: const Text('🔥', style: TextStyle(fontSize: 30)),
              title: Text(
                streak == 0 ? 'ابدأ سلسلتك اليوم' : '$streak أيام متتالية',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: const Text('أي نشاط (قرآن، أذكار، تسبيح) يحسب اليوم'),
            ),
          ),
          Card(
            color: kCardBackground,
            child: Padding(
              padding: const EdgeInsets.all(kPaddingMedium),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'أهداف اليوم',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.tune),
                        onPressed: _editGoals,
                      ),
                    ],
                  ),
                  _row(
                    'صفحات القرآن',
                    '${t.pages} / ${goals.pages}',
                    t.pages / goals.pages,
                  ),
                  _row(
                    'التسبيح',
                    '${t.tasbih} / ${goals.tasbih}',
                    t.tasbih / goals.tasbih,
                  ),
                  _row(
                    'أذكار الصباح',
                    '${(t.morning * 100).round()}%',
                    t.morning,
                  ),
                  _row(
                    'أذكار المساء',
                    '${(t.evening * 100).round()}%',
                    t.evening,
                  ),
                ],
              ),
            ),
          ),
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
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final e in const {
                        0: 'القرآن (صفحات)',
                        1: 'التسبيح',
                        2: 'الأذكار %',
                      }.entries)
                        ChoiceChip(
                          label: Text(e.value),
                          selected: mode == e.key,
                          onSelected: (_) => setState(() => mode = e.key),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _chart(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
