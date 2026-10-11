import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants.dart';
import 'garden_service.dart';
import 'garden_view.dart';
import 'growth_service.dart';

class GrowthScreen extends StatefulWidget {
  const GrowthScreen({Key? key}) : super(key: key);

  @override
  State<GrowthScreen> createState() => _GrowthScreenState();
}

class _GrowthScreenState extends State<GrowthScreen> {
  GardenData? g;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await loadGarden();
    if (!mounted) return;
    setState(() => g = d);
  }

  Future<void> _share(GardenData d) async {
    await Clipboard.setData(ClipboardData(text: gardenShareText(d)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ إنجازك، الصقه بواتساب أو أي تطبيق')),
    );
  }

  Widget _plantInfo(String title, IconData icon, int days, bool today) {
    final lv = plantLevel(days);
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: kGreen),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(kPlantStages[lv], style: const TextStyle(fontSize: 12)),
          Text('$days يوم',
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Icon(
            today ? Icons.water_drop : Icons.water_drop_outlined,
            size: 16,
            color: today ? Colors.lightBlue : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _todayRow(String text, bool ok, {String? extra}) {
    return ListTile(
      dense: true,
      leading: Icon(
        ok ? Icons.check_circle : Icons.radio_button_unchecked,
        color: ok ? kGreen : Colors.grey,
      ),
      title: Text(text),
      trailing: extra == null ? null : Text(extra),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = g;
    if (d == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('حديقتك الإيمانية')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final days = d.totalDays;
    final lvl = stageOf(days);
    final last = lvl >= kStageDays.length - 1;
    final from = kStageDays[lvl];
    final to = last ? from : kStageDays[lvl + 1];
    final prog = last || to == from ? 1.0 : (days - from) / (to - from);
    final badges = badgesOf(d);
    final gotN = badges.where((b) => b.got).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('حديقتك الإيمانية'),
        actions: [
          IconButton(
            tooltip: 'شارك إنجازك',
            icon: const Icon(Icons.share),
            onPressed: () => _share(d),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(kPaddingMedium),
        children: [
          GardenView(
            quran: plantLevel(d.quranDays),
            adhkar: plantLevel(d.adhkarDays),
            prayer: plantLevel(d.prayerDays),
            quranToday: d.quranToday,
            adhkarToday: d.adhkarToday,
            prayerToday: d.prayersToday > 0,
          ),
          const SizedBox(height: kPaddingSmall),
          Card(
            color: kCardBackground,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _plantInfo('القرآن', Icons.menu_book, d.quranDays,
                      d.quranToday),
                  _plantInfo('الأذكار', Icons.auto_awesome, d.adhkarDays,
                      d.adhkarToday),
                  _plantInfo('الصلاة', Icons.mosque, d.prayerDays,
                      d.prayersToday > 0),
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
                    'مستوى حديقتك: ${kStageNames[lvl]}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kGreen,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('أيام النشاط: $days'),
                  Text('الأيام المتتالية الآن: ${d.streak} 🔥'),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: prog.clamp(0.0, 1.0).toDouble(),
                      minHeight: 8,
                      color: kGreen,
                      backgroundColor: kGreen.withOpacity(0.2),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    last
                        ? 'وصلت لأعلى مرحلة، بارك الله فيك'
                        : 'تبقّى ${to - days} يوم نشاط للمرحلة القادمة: '
                            '${kStageNames[lvl + 1]}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          Card(
            color: kCardBackground,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text('سقي حديقتك اليوم',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                _todayRow('قراءة من القرآن', d.quranToday),
                _todayRow('الأذكار أو التسبيح', d.adhkarToday),
                _todayRow('الصلوات', d.prayersToday >= 5,
                    extra: '${d.prayersToday} / 5'),
              ],
            ),
          ),
          Card(
            color: kCardBackground,
            child: Padding(
              padding: const EdgeInsets.all(kPaddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الإنجازات ($gotN / ${badges.length})',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final b in badges)
                        Tooltip(
                          message: b.hint,
                          child: Chip(
                            avatar: Icon(b.icon,
                                size: 18,
                                color: b.got ? kGreen : Colors.grey),
                            label: Text(b.title,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: b.got ? null : Colors.grey)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final b in badges.where((x) => !x.got).take(3))
                    Text('• ${b.title}: ${b.hint}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'كل نبتة تكبر بأيام التزامك بها: القرآن، الأذكار والتسبيح، '
              'والصلوات المسجّلة. الحديقة لا تذبل أبداً، حتى لو انقطعت يوماً.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
