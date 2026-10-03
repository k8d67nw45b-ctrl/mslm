import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import 'app_settings.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'notifications_screen.dart';

const _credits = 'صفحات المصحف: مصحف المدينة (خط مجمع الملك فهد V4) '
    'عبر SakinaDevGroup/mushaf-madani-cdn.\n'
    'نص القرآن وتفسير الجلالين: alquran.cloud.\n'
    'تفسير الطبري: spa5k/tafsir_api.\n'
    'صوت الشيخ محمد أيوب: everyayah.com.\n'
    'حصن المسلم: rn0x/hisn_almuslim_json.\n'
    'أذكار الصباح والمساء: Seen-Arabic/Morning-And-Evening-Adhkar-DB (MIT).\n'
    'الأربعون النووية: fawazahmed0/hadith-api.\n'
    'الخطوط: تجوال وأميري (OFL).\n\n'
    'المحتوى الديني منقول من مصادره، وننصح بمراجعته.';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String method = 'umm_al_qura';
  String madhab = 'shafi';
  String place = '';
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final m = p.getString('calc_method') ?? 'umm_al_qura';
    if (!mounted) return;
    setState(() {
      method = calcMethodNames.containsKey(m) ? m : 'umm_al_qura';
      madhab = p.getString('madhab') ?? 'shafi';
      place = p.getString('loc_name') ?? '';
      loaded = true;
    });
  }

  Future<void> _saveCalc() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('calc_method', method);
    await p.setString('madhab', madhab);
    try {
      await rescheduleAll(force: true);
    } catch (_) {}
  }

  Future<void> _pickCity() async {
    final ok = await showCityPicker(context);
    if (!ok) return;
    await _load();
    try {
      await rescheduleAll(force: true);
    } catch (_) {}
  }

  Widget _title(String t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Text(
        t,
        style: const TextStyle(
          color: kGreen,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('الإعدادات')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(kPaddingMedium),
        children: [
          _title('المواقيت'),
          Card(
            color: kCardBackground,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.location_on, color: kGreen),
                  title: const Text('الموقع'),
                  subtitle: Text(place.isEmpty ? 'تلقائي (GPS)' : place),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: _pickCity,
                ),
                ListTile(
                  title: const Text('طريقة حساب المواقيت'),
                  subtitle: DropdownButton<String>(
                    isExpanded: true,
                    value: method,
                    items: [
                      for (final e in calcMethodNames.entries)
                        DropdownMenuItem(value: e.key, child: Text(e.value)),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => method = v);
                      _saveCalc();
                    },
                  ),
                ),
                ListTile(
                  title: const Text('المذهب (وقت العصر)'),
                  subtitle: Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('الجمهور'),
                        selected: madhab == 'shafi',
                        onSelected: (_) {
                          setState(() => madhab = 'shafi');
                          _saveCalc();
                        },
                      ),
                      ChoiceChip(
                        label: const Text('حنفي'),
                        selected: madhab == 'hanafi',
                        onSelected: (_) {
                          setState(() => madhab = 'hanafi');
                          _saveCalc();
                        },
                      ),
                    ],
                  ),
                ),
                ListTile(
                  title: const Text('تعديل التاريخ الهجري'),
                  trailing: ValueListenableBuilder<int>(
                    valueListenable: AppSettings.hijriOffset,
                    builder: (context, v, _) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: v <= -2
                              ? null
                              : () => AppSettings.setHijriOffset(v - 1),
                        ),
                        Text(v == 0 ? 'بدون' : (v > 0 ? '+$v' : '$v')),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: v >= 2
                              ? null
                              : () => AppSettings.setHijriOffset(v + 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _title('التنبيهات'),
          Card(
            color: kCardBackground,
            child: ListTile(
              leading: const Icon(Icons.notifications, color: kGreen),
              title: const Text('إشعارات الصلاة والأذكار'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
            ),
          ),
          _title('حجم الخط'),
          Card(
            color: kCardBackground,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ValueListenableBuilder<double>(
                valueListenable: AppSettings.fontScale,
                builder: (context, s, _) => Wrap(
                  spacing: 8,
                  children: [
                    for (final e in const {
                      'صغير': 0.9,
                      'عادي': 1.0,
                      'كبير': 1.15,
                      'كبير جداً': 1.3,
                    }.entries)
                      ChoiceChip(
                        label: Text(e.key),
                        selected: (s - e.value).abs() < 0.01,
                        onSelected: (_) => AppSettings.setFontScale(e.value),
                      ),
                  ],
                ),
              ),
            ),
          ),
          _title('عن التطبيق'),
          Card(
            color: kCardBackground,
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: kGreen),
              title: const Text(appName),
              subtitle: const Text('الإصدار 1.0.0 • المصادر والشكر'),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: appName,
                applicationVersion: '1.0.0',
                children: const [Text(_credits)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}