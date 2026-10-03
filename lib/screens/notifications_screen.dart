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
  bool morning = false;
  bool evening = false;
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
      morning = p.getBool('n_morning') ?? false;
      evening = p.getBool('n_evening') ?? false;
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
    await p.setBool('n_morning', morning);
    await p.setBool('n_evening', evening);
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

  Future<void> _test() async {
    await requestNotificationPermissions();
    final e = await sendTestNotification();
    if (mounted) {
      setState(() => note =
          e == null ? 'أُرسل الإشعار، شوف شريط الإشعارات' : 'فشل الإشعار: $e');
    }
    _status();
  }

  Future<void> _testLater() async {
    await requestNotificationPermissions();
    final e = await scheduleTestIn(60);
    if (mounted) {
      setState(() => note = e == null
          ? 'جُدول إشعار بعد دقيقة. اقفل الشاشة وانتظر'
          : 'فشلت الجدولة: $e');
    }
    _status();
  }

  Widget _row(bool? ok, String title, String value, {Widget? action}) {
    final color = ok == null
        ? Colors.grey
        : (ok ? kGreen : Colors.redAccent);
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
                    onPressed: _test,
                    icon: const Icon(Icons.notifications_active),
                    label: const Text('تجربة الآن'),
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

  Widget _sw(String t, bool v, ValueChanged<bool> f) {
    return SwitchListTile(
      title: Text(t),
      value: v,
      activeColor: kGreen,
      onChanged: f,
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
                        const Text('وقت التنبيه:'),
                        for (final m in [0, 5, 10, 15])
                          ChoiceChip(
                            label: Text(m == 0 ? 'عند الأذان' : 'قبل $m د'),
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
                _sw('تذكير أذكار الصباح (بعد الفجر بنصف ساعة)', morning, (v) {
                  setState(() => morning = v);
                  _save();
                }),
                _sw('تذكير أذكار المساء (بعد العصر بنصف ساعة)', evening, (v) {
                  setState(() => evening = v);
                  _save();
                }),
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
