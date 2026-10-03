import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'khatma_service.dart';
import 'mushaf_reader.dart';
import 'mushaf_service.dart';
import 'notification_service.dart';

class KhatmaScreen extends StatefulWidget {
  const KhatmaScreen({Key? key}) : super(key: key);

  @override
  State<KhatmaScreen> createState() => _KhatmaScreenState();
}

class _KhatmaScreenState extends State<KhatmaScreen> {
  Khatma? k;
  int sel = 30;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final x = await loadKhatma();
    if (!mounted) return;
    setState(() => k = x);
  }

  Future<void> _resched() async {
    try {
      await rescheduleAll(force: true);
    } catch (_) {}
  }

  Future<void> _start() async {
    await startKhatma(sel);
    await _load();
  }

  Future<void> _stop() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إيقاف الختمة'),
        content: const Text('سيُمسح تقدّمك بهذه الختمة. متأكد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('إيقاف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await stopKhatma();
    await _resched();
    await _load();
  }

  Future<void> _open() async {
    final p = await getLastPage();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MushafReader(startPage: p ?? 1)),
    );
    _load();
  }

  Future<void> _remind(bool on) async {
    final x = k!;
    if (on) {
      try {
        await requestNotificationPermissions();
      } catch (_) {}
    }
    await setKhatmaReminder(on, x.remindMinutes);
    await _resched();
    await _load();
  }

  Future<void> _time() async {
    final x = k!;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: x.remindMinutes ~/ 60,
        minute: x.remindMinutes % 60,
      ),
    );
    if (t == null) return;
    await setKhatmaReminder(x.remind, t.hour * 60 + t.minute);
    await _resched();
    await _load();
  }

  Widget _line(String label, String value, double v) {
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

  Widget _startCard(Khatma x) {
    final perDay = (604 / sel).ceil();
    return Card(
      color: kCardBackground,
      child: Padding(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (x.completed > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'ختماتك المكتملة: ${x.completed} 🎉',
                  style: const TextStyle(
                    color: kGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Text(
              'ابدأ ختمة جديدة',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const Text('مدة الختمة:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final d in const [15, 30, 60, 90, 120])
                  ChoiceChip(
                    label: Text('$d يوم'),
                    selected: sel == d,
                    onSelected: (_) => setState(() => sel = d),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'ورد يومي: حوالي $perDay صفحة '
              '(${(604 / sel / 20).toStringAsFixed(1)} جزء)',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _start,
                icon: const Icon(Icons.play_arrow),
                label: const Text('ابدأ الختمة'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activeCard(Khatma x) {
    final f = x.finishDate;
    return Column(
      children: [
        Card(
          color: kCardBackground,
          child: Padding(
            padding: const EdgeInsets.all(kPaddingMedium),
            child: Column(
              children: [
                SizedBox(
                  width: 170,
                  height: 170,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: CircularProgressIndicator(
                          value: x.done / 604,
                          strokeWidth: 12,
                          color: kGreen,
                          backgroundColor: kGreen.withOpacity(0.2),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(x.done * 100 / 604).round()}%',
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('${x.done} / 604 صفحة'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _line(
                  'ورد اليوم',
                  '${x.todayDone} / ${x.todayTarget} صفحة',
                  x.todayTarget == 0 ? 1.0 : x.todayDone / x.todayTarget,
                ),
                ListTile(
                  title: const Text('المتبقي'),
                  trailing: Text('${x.left} صفحة، ${x.daysLeft} يوم'),
                ),
                ListTile(
                  title: const Text('تاريخ الإنهاء المتوقع'),
                  trailing: Text('${f.year}/${f.month}/${f.day}'),
                ),
                if (x.completed > 0)
                  ListTile(
                    title: const Text('ختماتك المكتملة'),
                    trailing: Text('${x.completed}'),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _open,
                    icon: const Icon(Icons.menu_book),
                    label: const Text('متابعة القراءة'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: kPaddingMedium),
        Card(
          color: kCardBackground,
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('تذكير يومي بالورد'),
                value: x.remind,
                activeColor: kGreen,
                onChanged: _remind,
              ),
              if (x.remind)
                ListTile(
                  title: const Text('وقت التذكير'),
                  trailing: Text(
                    TimeOfDay(
                      hour: x.remindMinutes ~/ 60,
                      minute: x.remindMinutes % 60,
                    ).format(context),
                  ),
                  onTap: _time,
                ),
            ],
          ),
        ),
        TextButton(
          onPressed: _stop,
          child: const Text(
            'إيقاف الختمة',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final x = k;
    return Scaffold(
      appBar: AppBar(title: const Text('ختمتي')),
      body: x == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(kPaddingMedium),
              children: [x.active ? _activeCard(x) : _startCard(x)],
            ),
    );
  }
}
