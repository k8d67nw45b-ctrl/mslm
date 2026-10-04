import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'growth_service.dart';
import 'growth_tree.dart';
import 'stats_service.dart';

class GrowthScreen extends StatefulWidget {
  const GrowthScreen({Key? key}) : super(key: key);

  @override
  State<GrowthScreen> createState() => _GrowthScreenState();
}

class _GrowthScreenState extends State<GrowthScreen> {
  int days = 0;
  int streak = 0;
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await loadActiveDays();
    final s = await loadStreak();
    if (!mounted) return;
    setState(() {
      days = d;
      streak = s;
      loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('شجرة التزامك')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final lvl = stageOf(days);
    final last = lvl >= kStageDays.length - 1;
    final from = kStageDays[lvl];
    final to = last ? from : kStageDays[lvl + 1];
    final prog = last || to == from ? 1.0 : (days - from) / (to - from);
    return Scaffold(
      appBar: AppBar(title: const Text('شجرة التزامك')),
      body: ListView(
        padding: const EdgeInsets.all(kPaddingMedium),
        children: [
          GrowthTree(level: lvl, streak: streak, height: 280),
          const SizedBox(height: kPaddingMedium),
          Card(
            color: kCardBackground,
            child: Padding(
              padding: const EdgeInsets.all(kPaddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kStageNames[lvl],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: kGreen,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('أيام النشاط: $days'),
                  Text('الأيام المتتالية الآن: $streak 🔥'),
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
              children: [
                for (var i = 0; i < kStageNames.length; i++)
                  ListTile(
                    dense: true,
                    leading: Icon(
                      days >= kStageDays[i] && (i > 0 || days > 0)
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: days >= kStageDays[i] && (i > 0 || days > 0)
                          ? kGreen
                          : Colors.grey,
                    ),
                    title: Text(kStageNames[i]),
                    trailing: Text(
                      i == 0 ? 'البداية' : '${kStageDays[i]} يوم',
                    ),
                  ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'يحسب اليوم نشاطاً إذا قرأت صفحة من القرآن أو سبّحت أو قرأت '
              'شيئاً من الأذكار. الشجرة لا تنقص أبداً، حتى لو انقطعت يوماً.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
