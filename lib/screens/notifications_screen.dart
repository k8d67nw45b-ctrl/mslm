import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import 'notification_service.dart';

const _pn = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool loaded = false;
  bool prayers = false;
  bool adhanSound = true;
  bool morning = false;
  bool evening = false;
  int mMin = 6 * 60 + 30;
  int eMin = 17 * 60 + 30;
  int before = 0;
  List<bool> each = List.filled(5, true);
  NotifStatus? st;
  String note = '';

  @override
  void initState() {
    super.initState();
    _load();
    _status();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      prayers = p.getBool('n_prayers') ?? false;
      adhanSound = p.getBool('n_adhan_sound') ?? true;
      morning = p.getBool('n_morning') ?? false;
      evening = p.getBool('n_evening') ?? false;
      mMin = p.getInt('n_morning_min') ?? 6 * 60 + 30;
      eMin = p.getInt('n_evening_min') ?? 17 * 60 + 30;
      before = p.getInt('n_before') ?? 0;
      each = List.generate(5, (i) => p.getBool('n_p$i') ?? true);
      loaded = true;
    });
  }

  Future<void> _status() async {
    try {
      final s = await notifStatus();
      if (mounted) setState(() => st = s);
    } catch (e) {
      if (mounted) setState(() => note = '$e');
    }
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('n_prayers', prayers);
    await p.setBool('n_adhan_sound', adhanSound);
    await p.setBool('n_morning', morning);
    await p.setBool('n_evening', evening);
    await p.setInt('n_morning_min', mMin);
    await p.setInt('n_evening_min', eMin);
    await p.setInt('n_before', before);
    for (var i = 0; i < 5; i++) {
      await p.setBool('n_p$i', each[i]);
    }
    var msg = '';
    if (prayers || morning || evening) {
      try {
        final ok = await requestNotificationPermissions();
        if (!ok) msg = 'إذن الإشعارات غير ممنوح';
      } catch (e) {
        msg = '$e';
      }
    }
    var n = 0;
    try {
      n = await rescheduleAll(force: true);
    } catch (e) {
      msg = 'تعذّرت الجدولة: $e';
    }
    await _status();
    if (!mounted) return;
    setState(() => note = msg);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg.isEmpty ? 'تمت جدولة $n تنبيه' : msg)),
    );
  }

  Future<void> _test(int kind) async {
    await requestNotificationPermissions();
    final e = await sendTest(kind);
    if (mounted) {
      setState(() => note =
          e == null ? 'أُرسل الإشعار، شوف شريط الإشعارات' : 'فشل: $e');
    }
    _status();
  }

  Future<void> _testLater() async {
    await requestNotificationPermissions();
    final e = await scheduleTestIn(60, kAdhan);
    if (mounted) {
      setState(() => note = e == null
          ? 'جُدول أذان بعد دقيقة. اقفل الشاشة وانتظر'
          : 'فشلت الجدولة: $e');
    }
    _status();
  }

  Future<void> _pick(bool isMorning) async {
    final cur = isMorning ? mMin : eMin;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: cur ~/ 60, minute: cur % 60),
    );
    if (t == null) return;
    setState(() {
      if (isMorning) {
        mMin = t.hour * 60 + t.minute;
      } else {
        eMin = t.hour * 60 + t.minute;
      }
    });
    _save();
  }

  Widget _row(bool? ok, String title, String value, {Widget? action}) {
    final color =
        ok == null ? Colors.grey : (ok ? kGreen : Colors.redAccent);
    final icon = ok == null
        ? Icons.help_outline
        : (ok ? Icons.check_circle : Icons.cancel);
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text(value),
      trailing: action,
    );
  }

  Widget _statusCard() {
    final s = st;
    return Card(
      color: kCardBackground,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Text(
                'حالة الإشعارات',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (s == null)
              const Padding(
                padding: EdgeInsets.all(16),
                child: LinearProgressIndicator(),
              )
            else ...[
              _row(
                s.enabled,
                'إذن الإشعارات',
                s.enabled == true ? 'مفعّل' : 'غير مفعّل',
                action: s.enabled == true
                    ? null
                    : TextButton(
                        onPressed: () async {
                          await requestNotificationPermissions();
                          _status();
                        },
                        child: const Text('طلب'),
                      ),
              ),
              _row(
                s.exact,
                'التنبيه بالدقيقة',
                s.exact == null
                    ? 'غير مطلوب بهذا الجهاز'
                    : (s.exact! ? 'مسموح' : 'غير مسموح (قد تتأخر)'),
                action: s.exact == false
                    ? TextButton(
                        onPressed: () async {
                          await requestExactAlarms();
                          _status();
                        },
                        child: const Text('منح'),
                      )
                    : null,
              ),
              _row(
                s.pending > 0 ? true : null,
                'تنبيهات مجدولة',
                '${s.pending}',
              ),
              if (s.items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                  child: Text(
                    'القادمة:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              for (final it in s.items.take(8))
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(it.title, style: const TextStyle(fontSize: 13)),
                  trailing: Text(
                    it.when,
                    style: const TextStyle(fontSize: 12, color: kGreen),
                  ),
                ),
              if (s.error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    'آخر خطأ: ${s.error}',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
            ],
            if (note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(note),
              ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _test(kPrayer),
                    icon: const Icon(Icons.notifications_active),
                    label: const Text('تجربة عادية'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _test(kAdhan),
                    icon: const Icon(Icons.mosque),
                    label: const Text('تجربة الأذان'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _test(kFajr),
                    icon: const Icon(Icons.wb_twilight),
                    label: const Text('تجربة أذان الفجر'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _testLater,
                    icon: const Icon(Icons.timer),
                    label: const Text('تجربة بعد دقيقة'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Geolocator.openAppSettings(),
                    icon: const Icon(Icons.settings),
                    label: const Text('إعدادات التطبيق'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sw(String t, bool v, ValueChanged<bool> f, {String? sub}) {
    return SwitchListTile(
      title: Text(t),
      subtitle: sub == null ? null : Text(sub),
      value: v,
      activeColor: kGreen,
      onChanged: f,
    );
  }

  Widget _timeRow(String t, int mins, VoidCallback f) {
    return ListTile(
      dense: true,
      title: Text(t),
      trailing: Text(
        TimeOfDay(hour: mins ~/ 60, minute: mins % 60).format(context),
        style: const TextStyle(fontWeight: FontWeight.bold, color: kGreen),
      ),
      onTap: f,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('الإشعارات')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات')),
      body: ListView(
        padding: const EdgeInsets.all(kPaddingMedium),
        children: [
          _statusCard(),
          const SizedBox(height: kPaddingMedium),
          Card(
            color: kCardBackground,
            child: Column(
              children: [
                _sw('تنبيه عند دخول وقت الصلاة', prayers, (v) {
                  setState(() => prayers = v);
                  _save();
                }),
                if (prayers) ...[
                  _sw(
                    'صوت أذان المدينة المنورة',
                    adhanSound,
                    (v) {
                      setState(() => adhanSound = v);
                      _save();
                    },
                    sub: 'يعمل بصوت المنبّه، ارفع صوته بالجوال',
                  ),
                  for (var i = 0; i < 5; i++)
                    _sw(_pn[i], each[i], (v) {
                      setState(() => each[i] = v);
                      _save();
                    }),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('تنبيه مسبق:'),
                        for (final m in [0, 5, 10, 15])
                          ChoiceChip(
                            label: Text(m == 0 ? 'بدون' : 'قبل $m د'),
                            selected: before == m,
                            onSelected: (_) {
                              setState(() => before = m);
                              _save();
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: kPaddingMedium),
          Card(
            color: kCardBackground,
            child: Column(
              children: [
                _sw('تذكير أذكار الصباح (يومياً)', morning, (v) {
                  setState(() => morning = v);
                  _save();
                }),
                if (morning)
                  _timeRow('وقت أذكار الصباح', mMin, () => _pick(true)),
                _sw('تذكير أذكار المساء (يومياً)', evening, (v) {
                  setState(() => evening = v);
                  _save();
                }),
                if (evening)
                  _timeRow('وقت أذكار المساء', eMin, () => _pick(false)),
              ],
            ),
          ),
          const SizedBox(height: kPaddingMedium),
          const Text(
            'إذا تأخرت الإشعارات، اسمح للتطبيق بالعمل بالخلفية من '
            'إعدادات البطارية (بدون قيود)، وفعّل التشغيل التلقائي إن وُجد.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
