import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../core/constants.dart';
import 'moon.dart';
import 'prayer_helpers.dart';
import 'prayer_logic.dart';
import 'rf_design.dart';

class _Verse {
  final String text;
  final String ref;
  const _Verse(this.text, this.ref);
}

List<dynamic>? _surahsCache;
_Verse? _verseCache;
int _verseDay = -1;

Future<_Verse?> _loadVerse() async {
  final now = DateTime.now();
  final day = DateTime(now.year, now.month, now.day)
      .difference(DateTime(2024, 1, 1))
      .inDays;
  if (_verseCache != null && _verseDay == day) return _verseCache;
  try {
    if (_surahsCache == null) {
      final raw = await rootBundle.loadString('assets/data/quran_uthmani.json');
      final m = jsonDecode(raw) as Map<String, dynamic>;
      _surahsCache =
          (m['data'] as Map<String, dynamic>)['surahs'] as List<dynamic>;
    }
    const refs = [
      [94, 6],
      [13, 28],
      [2, 152],
      [20, 25],
      [11, 88],
      [65, 3],
      [2, 186],
      [3, 139],
    ];
    final r = refs[day % refs.length];
    final s = _surahsCache![r[0] - 1] as Map<String, dynamic>;
    for (final a in (s['ayahs'] as List<dynamic>)) {
      final am = a as Map<String, dynamic>;
      if (am['numberInSurah'] == r[1]) {
        var name = (s['name'] ?? '').toString();
        name = name.replaceFirst('سُورَةُ ', '').replaceFirst('سورة ', '');
        _verseCache = _Verse(am['text'].toString(), '$name - ${r[1]}');
        _verseDay = day;
        return _verseCache;
      }
    }
  } catch (_) {}
  return null;
}

class RfHomeHero extends StatefulWidget {
  final PrayerData? data;
  final NextInfo? next;
  final ValueListenable<Duration> left;
  final bool active;
  final bool bellDot;
  final VoidCallback onSearch;
  final VoidCallback onBell;
  final VoidCallback onTheme;
  final VoidCallback onSettings;
  const RfHomeHero({
    Key? key,
    required this.data,
    required this.next,
    required this.left,
    required this.active,
    required this.bellDot,
    required this.onSearch,
    required this.onBell,
    required this.onTheme,
    required this.onSettings,
  }) : super(key: key);

  @override
  State<RfHomeHero> createState() => _RfHomeHeroState();
}

class _RfHomeHeroState extends State<RfHomeHero> {
  Timer? _t;
  _Verse? verse;

  @override
  void initState() {
    super.initState();
    _loadVerse().then((v) {
      if (mounted) setState(() => verse = v);
    });
    _t = Timer.periodic(const Duration(seconds: 30), (_) {
      if (widget.active && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  Widget _ib(IconData icon, VoidCallback f, {bool dot = false}) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: f,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.14),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            if (dot)
              Positioned(
                top: 7,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip() {
    final v = verse;
    if (v == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: SingleChildScrollView(
            child: Text(
              '${v.text}\n\n(${v.ref})',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 22,
                height: 1.9,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
      child: Container(
        width: 230,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_stories, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    v.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Amiri',
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    v.ref,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(PrayerData d, NextInfo n) {
    final t = d.times;
    final list = [t.fajr, t.dhuhr, t.asr, t.maghrib, t.isha];
    final now = DateTime.now();
    var prev = n.time.subtract(const Duration(hours: 6));
    for (final x in list) {
      if (!x.isAfter(now)) prev = x;
    }
    final span = n.time.difference(prev).inSeconds;
    final raw = span <= 0 ? 0.0 : now.difference(prev).inSeconds / span;
    final prog = raw < 0 ? 0.0 : (raw > 1 ? 1.0 : raw);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A2B2C).withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.mosque, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الصلاة القادمة',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    n.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ValueListenableBuilder<Duration>(
                    valueListenable: widget.left,
                    builder: (context, l, _) => Text(
                      hms(l),
                      style: const TextStyle(
                        color: rfLime,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const Text(
                    'متبقي على الأذان',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text(
                fmtTime(n.time),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: prog,
                    minHeight: 6,
                    color: const Color(0xFF7BD34F),
                    backgroundColor: Colors.white24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final heroH = 290.0 + top;
    final d = widget.data;
    final n = widget.next;
    final now = DateTime.now();
    final sky = rfSkyAt(d?.times, now);
    return SizedBox(
      height: heroH + 20,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroH,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
              child: RfScene(sky: sky, age: moonAge(now)),
            ),
          ),
          Positioned(
            top: top + 10,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.mosque, color: rfGold, size: 30),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            appName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'معك في كل لحظة',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    _ib(Icons.search, widget.onSearch),
                    const SizedBox(width: 6),
                    _ib(
                      Icons.notifications_none,
                      widget.onBell,
                      dot: widget.bellDot,
                    ),
                    const SizedBox(width: 6),
                    _ib(Icons.brightness_6, widget.onTheme),
                    const SizedBox(width: 6),
                    _ib(Icons.settings_outlined, widget.onSettings),
                  ],
                ),
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerLeft, child: _chip()),
              ],
            ),
          ),
          if (d != null && n != null)
            Positioned(
              left: 16,
              right: 16,
              top: heroH - 118,
              child: _card(d, n),
            )
          else
            const Positioned(
              left: 16,
              right: 16,
              top: 200,
              child: Center(
                child: Text(
                  'جاري تحديد المواقيت...',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
