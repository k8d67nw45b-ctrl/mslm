import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'prayer_tracker_service.dart';
import 'qada_service.dart';

int _toInt(String s) {
  var t = s.trim();
  const ar = '٠١٢٣٤٥٦٧٨٩';
  for (var i = 0; i < 10; i++) {
    t = t.replaceAll(ar[i], '$i');
  }
  return int.tryParse(t) ?? 0;
}

String _span(int days) {
  if (days <= 0) return 'خلصت';
  if (days < 60) return '$days يوم';
  if (days < 700) return '${(days / 30).round()} شهر';
  return '${(days / 365).toStringAsFixed(1)} سنة';
}

class QadaScreen extends StatefulWidget {
  const QadaScreen({Key? key}) : super(key: key);

  @override
  State<QadaScreen> createState() => _QadaScreenState();
}

class _QadaScreenState extends State<QadaScreen> {
  List<int> q = List.filled(5, 0);
  List<int> done = List.filled(5, 0);
  FastQada fast = const FastQada(0, 0);
  QadaPlan plan = const QadaPlan(1, 1);
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final a = await loadQada();
    final b = await loadPrayerDone();
    final c = await loadFast();
    final d = await loadPlan();
    if (!mounted) return;
    setState(() {
      q = a;
      done = b;
      fast = c;
      plan = d;
      loaded = true;
    });
  }

  Future<int?> _askNumber(String title, String label, String hint) {
    final c = TextEditingController();
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            TextField(
              controller: c,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(hintText: hint),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _toInt(c.text)),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, Future<void> Function() undo) {
    final m = ScaffoldMessenger.of(context);
    m.hideCurrentSnackBar();
    m.showSnackBar(
      SnackBar(
        content: Text(msg),
        action: SnackBarAction(
          label: 'تراجع',
          onPressed: () async {
            await undo();
            await _load();
          },
        ),
      ),
    );
  }

  Future<void> _madeUp(int i) async {
    await madeUpPrayer(i);
    await _load();
    _snack('تقبل الله، سُجّلت قضاء ${kPrayerNames[i]}',
        () => undoMadeUpPrayer(i));
  }

  Future<void> _addMissed(int i) async {
    await addQada(i, 1);
    await _load();
  }

  Future<void> _bulk() async {
    final n = await _askNumber(
      'إضافة أيام فائتة',
      'عدد الأيام التي فاتتك فيها الصلوات الخمس كلها:',
      'مثال: 10',
    );
    if (n == null || n <= 0) return;
    for (var i = 0; i < 5; i++) {
      await addQada(i, n);
    }
    await _load();
  }

  Future<void> _planPrayer() async {
    final n = await _askNumber(
      'خطة القضاء',
      'كم يوماً (خمس صلوات) تقضي باليوم؟',
      'مثال: 1',
    );
    if (n == null || n <= 0) return;
    await savePlan(daysPerDay: n);
    await _load();
  }

  Future<void> _addFast() async {
    final n = await _askNumber(
      'إضافة أيام صيام فائتة',
      'عدد الأيام التي عليك قضاؤها:',
      'مثال: 6',
    );
    if (n == null || n <= 0) return;
    await addFastOwed(n);
    await _load();
  }

  Future<void> _planFast() async {
    final n = await _askNumber(
      'خطة قضاء الصيام',
      'كم يوماً تصوم قضاءً في الأسبوع؟',
      'مثال: 2',
    );
    if (n == null || n <= 0) return;
    await savePlan(fastsPerWeek: n);
    await _load();
  }

  Future<void> _madeUpFast() async {
    await madeUpFast();
    await _load();
    _snack('تقبل الله صيامك، سُجّل يوم قضاء', undoMadeUpFast);
  }

  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تصفير القضاء'),
        content: const Text(
            'سيُصفَّر عدّاد الصلوات والصيام وكل الإنجاز المسجّل. متأكد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تصفير'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await resetAllQada();
    await _load();
  }

  Widget _bar(double v) => ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: v.clamp(0.0, 1.0).toDouble(),
          minHeight: 8,
          color: kGreen,
          backgroundColor: kGreen.withOpacity(0.2),
        ),
      );

  Widget _summary({
    required int owed,
    required int doneN,
    required String unit,
    required String estimate,
    required List<Widget> buttons,
  }) {
    final total = owed + doneN;
    final prog = total == 0 ? 0.0 : doneN / total;
    return Card(
      color: kCardBackground,
      child: Padding(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          children: [
            Text(
              '$owed',
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.bold,
                color: kGreen,
              ),
            ),
            Text('$unit متبقٍّ للقضاء'),
            const SizedBox(height: 12),
            _bar(prog),
            const SizedBox(height: 6),
            Text(
              total == 0
                  ? 'ابدأ بإضافة ما عليك'
                  : 'قضيت $doneN من $total  (${(prog * 100).round()}%)',
              style: const TextStyle(fontSize: 12),
            ),
            if (owed > 0) ...[
              const SizedBox(height: 4),
              Text(
                estimate,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: buttons,
            ),
          ],
        ),
      ),
    );
  }

  Widget _prayersTab() {
    final owed = q.fold<int>(0, (a, b) => a + b);
    final doneN = done.fold<int>(0, (a, b) => a + b);
    var mx = 0;
    for (final v in q) {
      if (v > mx) mx = v;
    }
    final per = plan.daysPerDay < 1 ? 1 : plan.daysPerDay;
    final days = (mx / per).ceil();
    return ListView(
      padding: const EdgeInsets.all(kPaddingMedium),
      children: [
        _summary(
          owed: owed,
          doneN: doneN,
          unit: 'صلاة',
          estimate:
              'بمعدل $per يوم قضاء باليوم تخلّص تقريباً بعد ${_span(days)}',
          buttons: [
            ElevatedButton.icon(
              onPressed: _bulk,
              icon: const Icon(Icons.add),
              label: const Text('إضافة أيام فائتة'),
            ),
            OutlinedButton.icon(
              onPressed: _planPrayer,
              icon: const Icon(Icons.flag_outlined),
              label: const Text('الخطة'),
            ),
          ],
        ),
        const SizedBox(height: kPaddingSmall),
        for (var i = 0; i < 5; i++)
          Card(
            color: kCardBackground,
            child: ListTile(
              title: Text(kPrayerNames[i]),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('قضيت ${done[i]}  •  متبقٍّ ${q[i]}',
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    _bar(q[i] + done[i] == 0
                        ? 0.0
                        : done[i] / (q[i] + done[i])),
                  ],
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'قضيت واحدة',
                    icon: const Icon(Icons.check_circle_outline),
                    color: kGreen,
                    onPressed: q[i] > 0 ? () => _madeUp(i) : null,
                  ),
                  IconButton(
                    tooltip: 'فاتتني واحدة',
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => _addMissed(i),
                  ),
                ],
              ),
            ),
          ),
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            '(✓) قضيت واحدة   (+) فاتتني واحدة. الصلاة اللي تعلّمها «فاتتني» '
            'بشاشة المتابعة تنضاف هنا تلقائياً. الأرقام للمتابعة الشخصية، '
            'وأحكام القضاء وترتيبه ترجع فيها لعالم أو جهة إفتاء.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _fastTab() {
    final per = plan.fastsPerWeek < 1 ? 1 : plan.fastsPerWeek;
    final days = (fast.owed / per).ceil() * 7;
    return ListView(
      padding: const EdgeInsets.all(kPaddingMedium),
      children: [
        _summary(
          owed: fast.owed,
          doneN: fast.done,
          unit: 'يوم صيام',
          estimate:
              'بمعدل $per يوم بالأسبوع تخلّص تقريباً بعد ${_span(days)}',
          buttons: [
            ElevatedButton.icon(
              onPressed: fast.owed > 0 ? _madeUpFast : null,
              icon: const Icon(Icons.check),
              label: const Text('قضيت يوماً'),
            ),
            OutlinedButton.icon(
              onPressed: _addFast,
              icon: const Icon(Icons.add),
              label: const Text('إضافة أيام'),
            ),
            OutlinedButton.icon(
              onPressed: _planFast,
              icon: const Icon(Icons.flag_outlined),
              label: const Text('الخطة'),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'مثال: أفطرت أياماً من رمضان لعذر؟ أضفها هنا وسجّل كل يوم تقضيه. '
            'أحكام القضاء والكفارة تختلف بحسب الحالة، فارجع فيها لعالم أو '
            'جهة إفتاء.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('قضاء الفوائت'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _reset,
            ),
          ],
          bottom: const TabBar(
            tabs: [Tab(text: 'الصلوات'), Tab(text: 'الصيام')],
          ),
        ),
        body: !loaded
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(children: [_prayersTab(), _fastTab()]),
      ),
    );
  }
}
