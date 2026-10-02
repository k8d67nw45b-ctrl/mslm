import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
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

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('n_prayers', prayers);
    await p.setBool('n_morning', morning);
    await p.setBool('n_evening', evening);
    await p.setInt('n_before', before);
    for (var i = 0; i < 5; i++) {
      await p.setBool('n_p$i', each[i]);
    }
    if (prayers || morning || evening) {
      try {
        final ok = await requestNotificationPermissions();
        if (!ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('اسمح بالإشعارات من إعدادات الجوال'),
            ),
          );
        }
      } catch (_) {}
    }
    try {
      await rescheduleAll(force: true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذّر جدولة التنبيهات، حدّد موقعك أول'),
          ),
        );
      }
    }
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
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await requestNotificationPermissions();
                await sendTestNotification();
              } catch (_) {}
            },
            icon: const Icon(Icons.notifications_active),
            label: const Text('تجربة إشعار'),
          ),
          const SizedBox(height: kPaddingMedium),
          const Text(
            'إذا تأخرت الإشعارات، اسمح للتطبيق بالعمل بالخلفية من '
            'إعدادات البطارية بالجوال (بدون قيود).',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
