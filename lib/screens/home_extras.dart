import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'growth_service.dart';
import 'growth_tree.dart';
import 'hijri_calendar_screen.dart';
import 'occasions.dart';
import 'stats_service.dart';

class OccasionCard extends StatefulWidget {
  final bool active;
  const OccasionCard({Key? key, required this.active}) : super(key: key);

  @override
  State<OccasionCard> createState() => _OccasionCardState();
}

class _OccasionCardState extends State<OccasionCard> {
  List<Occasion> today = [];
  Upcoming? next;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant OccasionCard old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _load();
  }

  void _load() {
    if (!mounted) return;
    final t = occasionsOn(DateTime.now());
    final up = upcomingOccasions();
    Upcoming? n;
    for (final u in up) {
      if (u.inDays > 0) {
        n = u;
        break;
      }
    }
    setState(() {
      today = t;
      next = n;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final mt = isMonThu(now);
    String title;
    String sub;
    var hot = false;
    if (today.isNotEmpty) {
      hot = true;
      title = 'اليوم: ${today.map((o) => o.name).join('، ')}';
      sub = today.first.note;
    } else if (mt) {
      hot = true;
      title = 'اليوم يوم ${now.weekday == DateTime.monday ? 'الاثنين' : 'الخميس'}';
      sub = 'يستحب صيامه';
    } else if (next != null) {
      title = 'بعد ${next!.inDays} يوم: ${next!.o.name}';
      sub = next!.o.note;
    } else {
      title = 'التقويم الهجري';
      sub = 'المناسبات وأطوار القمر';
    }
    return Card(
      color: hot ? kGreen.withOpacity(0.18) : kCardBackground,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: Icon(Icons.calendar_month, color: kGreen, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_left, color: kGreen),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HijriCalendarScreen()),
        ),
      ),
    );
  }
}

class TreeCard extends StatefulWidget {
  final bool active;
  final VoidCallback onTap;
  const TreeCard({Key? key, required this.active, required this.onTap})
      : super(key: key);

  @override
  State<TreeCard> createState() => _TreeCardState();
}

class _TreeCardState extends State<TreeCard> {
  int days = 0;
  int streak = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant TreeCard old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _load();
  }

  Future<void> _load() async {
    final d = await loadActiveDays();
    final s = await loadStreak();
    if (!mounted) return;
    setState(() {
      days = d;
      streak = s;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lvl = stageOf(days);
    final last = lvl >= kStageDays.length - 1;
    final from = kStageDays[lvl];
    final to = last ? from : kStageDays[lvl + 1];
    final prog = last || to == from ? 1.0 : (days - from) / (to - from);
    return Card(
      color: kCardBackground,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: GrowthTree(
                  level: lvl,
                  streak: streak,
                  animate: widget.active,
                  height: 110,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'شجرة التزامك',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      kStageNames[lvl],
                      style: const TextStyle(
                        color: kGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$days يوم نشاط${streak > 0 ? '  •  🔥 $streak' : ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: prog.clamp(0.0, 1.0).toDouble(),
                        minHeight: 6,
                        color: kGreen,
                        backgroundColor: kGreen.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: kGreen),
            ],
          ),
        ),
      ),
    );
  }
}
