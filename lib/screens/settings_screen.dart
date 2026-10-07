import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../core/theme_controller.dart';
import 'app_settings.dart';
import 'backup_service.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'notifications_screen.dart';
import 'privacy_screen.dart';

const _credits = 'صفحات المصحف: مصحف المدينة (خط مجمع الملك فهد V4) '
    'عبر SakinaDevGroup/mushaf-madani-cdn.\n'
    'نص القرآن وتفسير الجلالين: alquran.cloud.\n'
    'تفسير الطبري: spa5k/tafsir_api.\n'
    'صوت الشيخ محمد أيوب: everyayah.com.\n'
    'حصن المسلم: rn0x/hisn_almuslim_json.\n'
    'أذكار الصباح والمساء: Seen-Arabic/Morning-And-Evening-Adhkar-DB (MIT).\n'
    'الأربعون النووية: fawazahmed0/hadith-api.\n'
    'المواقيت: مكتبة Adhan، والتاريخ الهجري: حزمة hijri (أم القرى).\n'
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
  double? fa;
  double? ia;
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
      fa = p.getDouble('angle_fajr');
      ia = p.getDouble('angle_isha');
      loaded = true;
    });
  }

  Future<void> _resched() async {
    try {
      await rescheduleAll(force: true);
    } catch (_) {}
  }

  Future<void> _saveCalc() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('calc_method', method);
    await p.setString('madhab', madhab);
    await _resched();
  }

  Future<void> _saveAngle(String key, double? v) async {
    final p = await SharedPreferences.getInstance();
    if (v == null) {
      await p.remove(key);
    } else {
      await p.setDouble(key, v);
    }
    await _resched();
  }

  Future<void> _pickCity() async {
    final ok = await showCityPicker(context);
    if (!ok) return;
    await _load();
    await _resched();
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

  Widget _angleRow(
    String label,
    double? v,
    double def,
    ValueChanged<double?> onChange,
  ) {
    return Column(
      children: [
        SwitchListTile(
          title: Text('تخصيص $label'),
          subtitle: Text('الافتراضي لهذه الطريقة: ${def.toStringAsFixed(1)}°'),
          value: v != null,
          activeColor: kGreen,
          onChanged: (on) => onChange(on ? def : null),
        ),
        if (v != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('الزاوية:'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: v <= 10 ? null : () => onChange(v - 0.5),
                ),
                Text(
                  '${v.toStringAsFixed(1)}°',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: v >= 22 ? null : () => onChange(v + 0.5),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _export() async {
    try {
      final json = await exportBackup();
      final f = await writeBackupFile(json);
      await Share.shareXFiles(
        [XFile(f.path)],
        text: 'نسخة رفيق المسلم الاحتياطية',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر التصدير: $e')),
      );
    }
  }

  Future<void> _copyBackup() async {
    final json = await exportBackup();
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ النسخة الاحتياطية')),
    );
  }

  Future<void> _import() async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('استيراد نسخة احتياطية'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: c,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'الصق محتوى النسخة هنا',
                border: OutlineInputBorder(),
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                final d = await Clipboard.getData(Clipboard.kTextPlain);
                if (d?.text != null) c.text = d!.text!;
              },
              icon: const Icon(Icons.paste),
              label: const Text('لصق من الحافظة'),
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
            child: const Text('استيراد'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final n = await importBackup(c.text);
      await AppSettings.load();
      await ThemeController.load();
      ThemeController.refresh();
      await _resched();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم استيراد $n عنصر')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('النسخة غير صالحة')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('الإعدادات')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final d = calcParamsFor(method, madhab);
    final fDef = d.fajrAngle;
    final raw = d.ishaAngle;
    final iDef = (raw == null || raw <= 0) ? 17.0 : raw;
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
                _angleRow('زاوية الفجر', fa, fDef, (v) {
                  setState(() => fa = v);
                  _saveAngle('angle_fajr', v);
                }),
                _angleRow('زاوية العشاء', ia, iDef, (v) {
                  setState(() => ia = v);
                  _saveAngle('angle_isha', v);
                }),
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
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'إذا اختلفت المواقيت عن مسجد منطقتك، جرّب طريقة ثانية أو عدّل '
              'الزوايا، وقارن بمواقيت الجهة الرسمية عندك.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
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
          _title('المظهر'),
          Card(
            color: kCardBackground,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('الأسود الحقيقي (AMOLED)'),
                  subtitle: const Text(
                    'يوفر البطارية بشاشات OLED (يعيدك للرئيسية)',
                  ),
                  value: kAmoled,
                  activeColor: kGreen,
                  onChanged: (v) => AppSettings.setAmoled(v),
                ),
                ListTile(
                  title: const Text('ألوان المصحف'),
                  subtitle: ValueListenableBuilder<int>(
                    valueListenable: AppSettings.readTheme,
                    builder: (context, v, _) => Wrap(
                      spacing: 8,
                      children: [
                        for (final e in readThemeNames.entries)
                          ChoiceChip(
                            label: Text(e.value),
                            selected: v == e.key,
                            onSelected: (_) =>
                                AppSettings.setReadTheme(e.key),
                          ),
                      ],
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('حجم الخط'),
                  subtitle: ValueListenableBuilder<double>(
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
                            onSelected: (_) =>
                                AppSettings.setFontScale(e.value),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _title('النسخ الاحتياطي'),
          Card(
            color: kCardBackground,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_file, color: kGreen),
                  title: const Text('تصدير نسخة احتياطية'),
                  subtitle: const Text(
                    'إحصائياتك وختمتك ونقاط الحفظ وإعداداتك',
                  ),
                  onTap: _export,
                ),
                ListTile(
                  leading: const Icon(Icons.copy, color: kGreen),
                  title: const Text('نسخ النسخة الاحتياطية للحافظة'),
                  onTap: _copyBackup,
                ),
                ListTile(
                  leading: const Icon(Icons.download, color: kGreen),
                  title: const Text('استيراد نسخة احتياطية'),
                  subtitle: const Text('الصق محتوى النسخة'),
                  onTap: _import,
                ),
              ],
            ),
          ),
          _title('عن التطبيق'),
          Card(
            color: kCardBackground,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: kGreen),
                  title: const Text('سياسة الخصوصية'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: kGreen),
                  title: const Text(appName),
                  subtitle: const Text('الإصدار 1.1.0 • المصادر والشكر'),
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: appName,
                    applicationVersion: '1.1.0',
                    children: const [Text(_credits)],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
