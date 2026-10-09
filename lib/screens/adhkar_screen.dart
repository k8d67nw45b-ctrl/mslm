import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../core/theme_controller.dart';
import 'daily_adhkar_screen.dart';
import 'hajj_screen.dart';
import 'hisn_detail.dart';
import 'hisn_screen.dart';
import 'hisn_service.dart';
import 'nawawi_screen.dart';
import 'notifications_screen.dart';
import 'rf_design.dart';
import 'ruqyah_screen.dart';
import 'tasbih_screen.dart';

class _Dhikr {
  final String text;
  final int count;
  final String source;
  const _Dhikr(this.text, this.count, this.source);
}

const List<_Dhikr> _dhikrs = [
  _Dhikr('سُبْحَانَ اللَّهِ وَبِحَمْدِهِ', 100, 'متفق عليه'),
  _Dhikr(
    'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ '
        'وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
    100,
    'متفق عليه',
  ),
  _Dhikr(
    'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ',
    100,
    'صحيح مسلم: التوبة مئة مرة في اليوم',
  ),
];

class _Mini {
  final String label;
  final IconData icon;
  final List<String>? keys;
  const _Mini(this.label, this.icon, this.keys);
}

class _Beads extends CustomPainter {
  final double progress;
  _Beads(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2 - 8;
    final filled = (progress * 24).round();
    for (var i = 0; i < 24; i++) {
      final a = 2 * math.pi * i / 24 - math.pi / 2;
      canvas.drawCircle(
        Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a)),
        5.5,
        Paint()..color = i < filled ? kGreen : kGreen.withOpacity(0.25),
      );
    }
  }

  @override
  bool shouldRepaint(_Beads old) => old.progress != progress;
}

class AdhkarScreen extends StatefulWidget {
  const AdhkarScreen({Key? key}) : super(key: key);

  @override
  State<AdhkarScreen> createState() => _AdhkarScreenState();
}

class _AdhkarScreenState extends State<AdhkarScreen> {
  int dz = 0;
  int tasbih = 0;

  String get _dayKey {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  _Dhikr get _today {
    final n = DateTime.now();
    final doy =
        DateTime(n.year, n.month, n.day).difference(DateTime(n.year, 1, 1)).inDays;
    return _dhikrs[doy % _dhikrs.length];
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      dz = p.getInt('dz_$_dayKey') ?? 0;
      tasbih = p.getInt('st_tasbih_$_dayKey') ?? 0;
    });
  }

  Future<void> _go(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
    if (mounted) _load();
  }

  Future<void> _tap() async {
    final t = _today;
    if (dz >= t.count) {
      HapticFeedback.heavyImpact();
      return;
    }
    HapticFeedback.selectionClick();
    final v = dz + 1;
    setState(() => dz = v);
    final p = await SharedPreferences.getInstance();
    await p.setInt('dz_$_dayKey', v);
    if (v == t.count) HapticFeedback.heavyImpact();
  }

  Future<void> _openHisnBy(List<String>? keys) async {
    if (keys != null) {
      try {
        final all = await loadHisn();
        for (final s in all) {
          if (keys.any((k) => s.title.contains(k))) {
            if (!mounted) return;
            await _go(HisnDetail(sec: s));
            return;
          }
        }
      } catch (_) {}
    }
    if (!mounted) return;
    await _go(const HisnScreen());
  }

  Widget _ring(_Dhikr t) {
    final raw = t.count == 0 ? 0.0 : dz / t.count;
    final v = raw < 0 ? 0.0 : (raw > 1 ? 1.0 : raw);
    return GestureDetector(
      onTap: _tap,
      child: SizedBox(
        width: 104,
        height: 104,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 104,
              height: 104,
              child: CircularProgressIndicator(
                value: v,
                strokeWidth: 9,
                color: kGreen,
                backgroundColor: kGreen.withOpacity(0.15),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$dz',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'من ${t.count}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dhikrCard(_Dhikr t) {
    return RfCard(
      child: Stack(
        children: [
          Positioned(
            left: -14,
            bottom: -18,
            child: Icon(
              Icons.mosque,
              size: 96,
              color: kGreen.withOpacity(0.07),
            ),
          ),
          Row(
            children: [
              Column(
                children: [
                  _ring(t),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _go(const TasbihScreen()),
                    icon: const Icon(Icons.touch_app, size: 16),
                    label: const Text('متابعة العد'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: kGreen,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'ذكر اليوم',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      t.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 20,
                        height: 1.8,
                      ),
                    ),
                    Text(
                      '(عدد ${t.count} مرة)',
                      style: const TextStyle(color: kGreen, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.source,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeCard(String title, bool morning, bool now) {
    final sky = morning
        ? const RfSky(Color(0xFF2E86A0), Color(0xFFF4D58A), 0.0, 0.7)
        : const RfSky(Color(0xFF0C2A3A), Color(0xFFE0793A), 0.45, 0.9);
    return Expanded(
      child: RfCard(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        onTap: () => _go(DailyAdhkarScreen(morning: morning)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 124,
            child: Stack(
              children: [
                Positioned.fill(
                  child: RfScene(sky: sky, age: 0, showMoon: false),
                ),
                Positioned(
                  top: 12,
                  left: 14,
                  right: 14,
                  child: Row(
                    children: [
                      Icon(
                        morning ? Icons.wb_sunny : Icons.nights_stay,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      now ? 'الآن وقتها' : 'بطاقات بعدّاد',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tasbihCard() {
    return RfCard(
      child: Row(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(96, 96),
                  painter: _Beads((tasbih % 100) / 100),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$tasbih',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'اليوم',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'السبحة الإلكترونية',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                const Text(
                  'اختر التسبيح الذي تريده',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () => _go(const TasbihScreen()),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('ابدأ التسبيح'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniRow() {
    const tiles = [
      _Mini('أذكار عامة', Icons.favorite, null),
      _Mini(
        'الدخول والخروج',
        Icons.meeting_room,
        ['دخول', 'خروج', 'المسجد', 'المنزل', 'البيت'],
      ),
      _Mini('الطعام', Icons.restaurant, ['الطعام', 'الأكل', 'طعام']),
      _Mini('النوم', Icons.bed, ['النوم']),
      _Mini('السفر', Icons.directions_car, ['السفر', 'سفر']),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          for (final t in tiles)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Material(
                color: kCardBackground,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _openHisnBy(t.keys),
                  child: SizedBox(
                    width: 96,
                    height: 96,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: kGreen.withOpacity(0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(t.icon, color: kGreen),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _banner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: InkWell(
        onTap: () => _go(const NotificationsScreen()),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 88,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [Color(0xFF0B3B36), Color(0xFF17604F)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Stack(
            children: [
              Positioned(
                left: -6,
                top: -8,
                bottom: -8,
                child: Icon(
                  Icons.auto_stories,
                  size: 100,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'القرآن والسنة .. نور في حياتك',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'اجعل الأذكار عادة يومية بتنبيهات تناسبك',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_left, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _moreTile(String title, IconData icon, Widget page) {
    return RfCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      radius: 18,
      onTap: () => _go(page),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: kGreen.withOpacity(0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: kGreen, size: 22),
        ),
        title: Text(title),
        trailing: const Icon(Icons.chevron_left, color: kGreen),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _today;
    final h = DateTime.now().hour;
    final morningNow = h >= 3 && h < 12;
    final eveningNow = h >= 12 && h < 22;
    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        RfHeader(
          title: 'الأذكار',
          subtitle: 'قربك من الله .. راحة لقلبك',
          trailing: IconButton(
            icon: const Icon(Icons.brightness_6, color: Colors.white),
            onPressed: ThemeController.toggle,
          ),
        ),
        _dhikrCard(t),
        const RfSection('أذكار الصباح والمساء', icon: Icons.wb_twilight),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _timeCard('أذكار الصباح', true, morningNow),
              const SizedBox(width: 12),
              _timeCard('أذكار المساء', false, eveningNow),
            ],
          ),
        ),
        _tasbihCard(),
        const RfSection('أذكار متنوعة', icon: Icons.menu_book),
        _miniRow(),
        _banner(),
        const RfSection('المزيد من المحتوى', icon: Icons.apps),
        _moreTile('حصن المسلم', Icons.shield_outlined, const HisnScreen()),
        _moreTile('الرقية الشرعية', Icons.healing, const RuqyahScreen()),
        _moreTile('الأربعون النووية', Icons.menu_book, const NawawiScreen()),
        _moreTile('الحج والعمرة', Icons.mosque, const HajjScreen()),
      ],
    );
  }
}
