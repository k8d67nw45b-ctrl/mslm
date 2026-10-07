import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'occasions.dart';
import 'prayer_helpers.dart';
import 'prayer_logic.dart';
import 'prayer_tracker_service.dart';

class PrayerDotsCard extends StatefulWidget {
  final bool active;
  final int tick;
  final VoidCallback onTap;
  const PrayerDotsCard({
    Key? key,
    required this.active,
    required this.tick,
    required this.onTap,
  }) : super(key: key);

  @override
  State<PrayerDotsCard> createState() => _PrayerDotsCardState();
}

class _PrayerDotsCardState extends State<PrayerDotsCard> {
  List<int> day = List.filled(5, 0);
  int streak = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PrayerDotsCard old) {
    super.didUpdateWidget(old);
    if ((widget.active && !old.active) || widget.tick != old.tick) _load();
  }

  Future<void> _load() async {
    final d = await loadDay(DateTime.now());
    final s = await perfectStreak();
    if (!mounted) return;
    setState(() {
      day = d;
      streak = s;
    });
  }

  Widget _dot(int i) {
    final s = day[i];
    Color col;
    IconData ic;
    if (s == 1 || s == 2) {
      col = kGreen;
      ic = s == 2 ? Icons.groups : Icons.check_circle;
    } else if (s == 3) {
      col = Colors.redAccent;
      ic = Icons.cancel;
    } else {
      col = Colors.grey;
      ic = Icons.radio_button_unchecked;
    }
    return Expanded(
      child: Column(
        children: [
          Icon(ic, color: col, size: 28),
          const SizedBox(height: 4),
          Text(kPrayerNames[i], style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kCardBackground,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'صلواتي اليوم',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (streak > 0)
                    Text('🔥 $streak', style: const TextStyle(fontSize: 14)),
                  const Icon(Icons.chevron_left, color: kGreen),
                ],
              ),
              const SizedBox(height: 12),
              Row(children: [for (var i = 0; i < 5; i++) _dot(i)]),
            ],
          ),
        ),
      ),
    );
  }
}

class RamadanHomeCard extends StatefulWidget {
  final bool active;
  final int tick;
  final VoidCallback onTap;
  const RamadanHomeCard({
    Key? key,
    required this.active,
    required this.tick,
    required this.onTap,
  }) : super(key: key);

  @override
  State<RamadanHomeCard> createState() => _RamadanHomeCardState();
}

class _RamadanHomeCardState extends State<RamadanHomeCard> {
  String? title;
  String? sub;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RamadanHomeCard old) {
    super.didUpdateWidget(old);
    if ((widget.active && !old.active) || widget.tick != old.tick) _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final h = hijriOf(today);
    String? t;
    String? s;
    if (h.hMonth == 9) {
      t = 'رمضان: اليوم ${h.hDay}';
      try {
        final pd = await loadPrayerData();
        final x = pd.times;
        s = 'الإمساك ${fmtTime(x.fajr)} ${ampm(x.fajr)}'
            '   •   الإفطار ${fmtTime(x.maghrib)} ${ampm(x.maghrib)}';
      } catch (_) {
        s = 'افتح إمساكية رمضان';
      }
    } else {
      for (var i = 1; i <= 45; i++) {
        final d = DateTime(today.year, today.month, today.day + i);
        final x = hijriOf(d);
        if (x.hMonth == 9 && x.hDay == 1) {
          t = 'باقي $i يوم على رمضان';
          s = 'جهّز ختمتك وإمساكية الشهر';
          break;
        }
      }
    }
    if (!mounted) return;
    setState(() {
      title = t;
      sub = s;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = title;
    if (t == null) return const SizedBox.shrink();
    return Card(
      color: const Color(0xFF1B2447),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: const Icon(
          Icons.nightlight_round,
          color: Color(0xFFFFD54A),
          size: 32,
        ),
        title: Text(
          t,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: sub == null
            ? null
            : Text(sub!, style: const TextStyle(color: Colors.white70)),
        trailing: const Icon(Icons.chevron_left, color: Color(0xFFB6F36B)),
        onTap: widget.onTap,
      ),
    );
  }
}
