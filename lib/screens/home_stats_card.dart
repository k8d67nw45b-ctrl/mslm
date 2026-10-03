import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'stats_service.dart';

class StatsCard extends StatelessWidget {
  final DayStats? today;
  final Goals goals;
  final int streak;
  final VoidCallback onTap;
  const StatsCard({
    Key? key,
    required this.today,
    required this.goals,
    required this.streak,
    required this.onTap,
  }) : super(key: key);

  Widget _mini(String label, String sub, double v) {
    final x = v.clamp(0.0, 1.0).toDouble();
    return Expanded(
      child: Column(
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CircularProgressIndicator(
                    value: x,
                    strokeWidth: 6,
                    color: kGreen,
                    backgroundColor: kGreen.withOpacity(0.2),
                  ),
                ),
                Text(
                  '${(x * 100).round()}%',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = today;
    return Card(
      color: kCardBackground,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'إنجازك اليوم',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (streak > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: kGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('🔥 $streak'),
                    ),
                  const Icon(Icons.chevron_left, color: kGreen),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _mini(
                    'القرآن',
                    '${t?.pages ?? 0} / ${goals.pages} صفحات',
                    (t?.pages ?? 0) / goals.pages,
                  ),
                  _mini(
                    'التسبيح',
                    '${t?.tasbih ?? 0} / ${goals.tasbih}',
                    (t?.tasbih ?? 0) / goals.tasbih,
                  ),
                  _mini('الأذكار', 'صباح ومساء', t?.adhkar ?? 0),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
