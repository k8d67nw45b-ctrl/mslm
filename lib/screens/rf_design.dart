import 'dart:math' as math;
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'moon.dart';

const Color rfDeep = Color(0xFF0B3B36);
const Color rfLime = Color(0xFFB6F36B);
const Color rfGold = Color(0xFFD4AF37);

const List<String> rfWeekdays = [
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];

const List<String> rfGregMonths = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

const List<String> rfHijriMonths = [
  'محرم',
  'صفر',
  'ربيع الأول',
  'ربيع الآخر',
  'جمادى الأولى',
  'جمادى الآخرة',
  'رجب',
  'شعبان',
  'رمضان',
  'شوال',
  'ذو القعدة',
  'ذو الحجة',
];

String rfGregLine(DateTime d) =>
    '${rfWeekdays[d.weekday - 1]} ${d.day} ${rfGregMonths[d.month - 1]} ${d.year}';

String rfHijriLine(int d, int m, int y) {
  var i = m - 1;
  if (i < 0) i = 0;
  if (i > 11) i = 11;
  return '$d ${rfHijriMonths[i]} $y هـ';
}

class RfSky {
  final Color top;
  final Color bottom;
  final double night;
  final double glow;
  const RfSky(this.top, this.bottom, this.night, this.glow);
}

const RfSky rfNightSky = RfSky(Color(0xFF06161C), Color(0xFF0F3338), 1.0, 0.0);

class _Key {
  final DateTime t;
  final RfSky s;
  _Key(this.t, this.s);
}

RfSky rfSkyAt(PrayerTimes? t, DateTime now) {
  if (t == null) return rfNightSky;
  final k = <_Key>[
    _Key(t.fajr.subtract(const Duration(minutes: 45)), rfNightSky),
    _Key(
      t.fajr,
      const RfSky(Color(0xFF0E2A3A), Color(0xFF45606B), 0.7, 0.5),
    ),
    _Key(
      t.sunrise,
      const RfSky(Color(0xFF2B6577), Color(0xFFF0B27A), 0.25, 0.9),
    ),
    _Key(
      t.dhuhr,
      const RfSky(Color(0xFF2A7F8F), Color(0xFF9AD6D2), 0.0, 0.0),
    ),
    _Key(
      t.asr,
      const RfSky(Color(0xFF2F8596), Color(0xFFF2D68C), 0.0, 0.2),
    ),
    _Key(
      t.maghrib,
      const RfSky(Color(0xFF1B3B4B), Color(0xFFE8803F), 0.3, 1.0),
    ),
    _Key(
      t.isha,
      const RfSky(Color(0xFF0A1E2A), Color(0xFF1E4B4F), 0.8, 0.3),
    ),
    _Key(t.isha.add(const Duration(minutes: 60)), rfNightSky),
  ];
  if (now.isBefore(k.first.t) || now.isAfter(k.last.t)) return rfNightSky;
  for (var i = 0; i < k.length - 1; i++) {
    if (!now.isAfter(k[i + 1].t)) {
      final a = k[i].s;
      final b = k[i + 1].s;
      final span = k[i + 1].t.difference(k[i].t).inSeconds;
      final raw = span <= 0 ? 0.0 : now.difference(k[i].t).inSeconds / span;
      final f = raw < 0 ? 0.0 : (raw > 1 ? 1.0 : raw);
      return RfSky(
        Color.lerp(a.top, b.top, f)!,
        Color.lerp(a.bottom, b.bottom, f)!,
        a.night + (b.night - a.night) * f,
        a.glow + (b.glow - a.glow) * f,
      );
    }
  }
  return rfNightSky;
}

final List<Offset> _rfStars = _genStars();

List<Offset> _genStars() {
  final r = math.Random(5);
  return List.generate(
    48,
    (_) => Offset(r.nextDouble(), r.nextDouble() * 0.6),
  );
}

class RfScenePainter extends CustomPainter {
  final RfSky sky;
  final double age;
  final bool showMoon;
  RfScenePainter(this.sky, this.age, {this.showMoon = true});

  static double _c(double v) => v < 0 ? 0.0 : (v > 1 ? 1.0 : v);

  void _minaret(Canvas c, Paint p, double x, double base, double h, double s) {
    c.drawRect(Rect.fromLTWH(x - 5 * s, base - h, 10 * s, h), p);
    c.drawRect(Rect.fromLTWH(x - 8 * s, base - h * 0.78, 16 * s, 4 * s), p);
    final cone = Path()
      ..moveTo(x - 6.5 * s, base - h)
      ..lineTo(x, base - h - 24 * s)
      ..lineTo(x + 6.5 * s, base - h)
      ..close();
    c.drawPath(cone, p);
    c.drawCircle(Offset(x, base - h - 27 * s), 2.2 * s, p);
  }

  void _dome(Canvas c, Paint p, double x, double base, double r) {
    c.drawArc(
      Rect.fromCenter(center: Offset(x, base), width: r * 2, height: r * 2.1),
      math.pi,
      math.pi,
      true,
      p,
    );
  }

  void _mosque(Canvas c, Paint p, double cx, double base, double s) {
    c.drawRect(Rect.fromLTWH(cx - 62 * s, base - 38 * s, 124 * s, 38 * s), p);
    _dome(c, p, cx, base - 38 * s, 50 * s);
    c.drawRect(Rect.fromLTWH(cx - s, base - 105 * s, 2 * s, 14 * s), p);
    c.drawCircle(Offset(cx, base - 108 * s), 3.2 * s, p);
    c.drawRect(Rect.fromLTWH(cx - 92 * s, base - 22 * s, 36 * s, 22 * s), p);
    _dome(c, p, cx - 74 * s, base - 22 * s, 16 * s);
    c.drawRect(Rect.fromLTWH(cx + 56 * s, base - 22 * s, 36 * s, 22 * s), p);
    _dome(c, p, cx + 74 * s, base - 22 * s, 16 * s);
    _minaret(c, p, cx - 100 * s, base, 128 * s, s);
    _minaret(c, p, cx - 130 * s, base, 108 * s, s);
    _minaret(c, p, cx + 104 * s, base, 98 * s, s);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [sky.top, sky.bottom],
        ).createShader(rect),
    );

    if (sky.night > 0.05) {
      final sp = Paint();
      for (var i = 0; i < _rfStars.length; i++) {
        final s = _rfStars[i];
        sp.color = Colors.white.withOpacity(
          _c(sky.night * (0.3 + 0.7 * ((i * 37) % 10) / 10)),
        );
        canvas.drawCircle(
          Offset(s.dx * w, s.dy * h),
          0.6 + (i % 3) * 0.4,
          sp,
        );
      }
    }

    if (showMoon && sky.night > 0.45) {
      final mc = Offset(w * 0.42, h * 0.2);
      canvas.drawCircle(
        mc,
        30,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withOpacity(_c(0.18 * sky.night)),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: mc, radius: 30)),
      );
      paintMoon(canvas, mc, 12, age);
    }

    final gc = Offset(w * 0.62, h * 0.7);
    final gr = w * 0.6;
    canvas.drawCircle(
      gc,
      gr,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFA24A).withOpacity(_c(0.7 * sky.glow)),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: gc, radius: gr)),
    );

    final tone = Color.lerp(
      const Color(0xFF031311),
      const Color(0xFF0F3A3A),
      1 - sky.night,
    )!;
    final far = Color.lerp(tone, sky.bottom, 0.4)!;
    final base = h * 0.68;
    final mp = Path()
      ..moveTo(0, base + 4)
      ..lineTo(0, base - h * 0.14)
      ..quadraticBezierTo(w * 0.14, base - h * 0.28, w * 0.3, base - h * 0.1)
      ..quadraticBezierTo(w * 0.42, base - h * 0.02, w * 0.56, base)
      ..lineTo(w * 0.56, base + 4)
      ..close();
    canvas.drawPath(mp, Paint()..color = far);

    final p = Paint()..color = tone;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.94, base),
        width: w * 0.5,
        height: h * 0.2,
      ),
      math.pi,
      math.pi,
      true,
      p,
    );
    _mosque(canvas, p, w * 0.6, base, w / 470);
    canvas.drawRect(Rect.fromLTWH(0, base, w, h - base), p);
  }

  @override
  bool shouldRepaint(RfScenePainter old) =>
      old.sky.top != sky.top ||
      old.sky.bottom != sky.bottom ||
      old.sky.night != sky.night ||
      old.sky.glow != sky.glow ||
      old.age != age ||
      old.showMoon != showMoon;
}

class RfScene extends StatelessWidget {
  final RfSky sky;
  final double age;
  final bool showMoon;
  const RfScene({
    Key? key,
    required this.sky,
    required this.age,
    this.showMoon = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: RfScenePainter(sky, age, showMoon: showMoon),
        size: Size.infinite,
      ),
    );
  }
}

class RfHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final RfSky sky;
  final double height;
  final Widget? trailing;
  const RfHeader({
    Key? key,
    required this.title,
    required this.subtitle,
    this.sky = rfNightSky,
    this.height = 150,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: height + top,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
              child: RfScene(sky: sky, age: moonAge(DateTime.now())),
            ),
          ),
          Positioned(
            top: top + 14,
            left: 16,
            right: 16,
            child: Row(
              children: [
                const Icon(Icons.mosque, color: rfGold, size: 34),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RfCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final double radius;
  const RfCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    this.onTap,
    this.color,
    this.gradient,
    this.radius = 22,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: margin,
      child: Container(
        decoration: BoxDecoration(
          color: gradient == null ? (color ?? kCardBackground) : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: dark
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 14,
                    offset: Offset(0, 5),
                  ),
                ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(radius),
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class RfSection extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;
  const RfSection(this.title, {Key? key, this.icon, this.trailing})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: kGreen, size: 22),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
