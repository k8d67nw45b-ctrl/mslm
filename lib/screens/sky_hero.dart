import 'dart:async';
import 'dart:math' as math;
import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import '../core/constants.dart';
import 'app_settings.dart';
import 'moon.dart';
import 'prayer_helpers.dart';
import 'prayer_logic.dart';

const _days = [
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];
const _months = [
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
const _hijriMonths = [
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
const _pnames = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];

class _Key {
  final DateTime t;
  final Color top;
  final Color bottom;
  final double night;
  _Key(this.t, this.top, this.bottom, this.night);
}

class _Sky {
  final Color top;
  final Color bottom;
  final double night;
  const _Sky(this.top, this.bottom, this.night);
}

const _nightSky = _Sky(Color(0xFF070B1F), Color(0xFF1B2447), 1.0);

_Sky _skyAt(PrayerTimes? t, DateTime now) {
  if (t == null) return _nightSky;
  final k = <_Key>[
    _Key(t.fajr.subtract(const Duration(minutes: 45)),
        const Color(0xFF070B1F), const Color(0xFF1B2447), 1.0),
    _Key(t.fajr, const Color(0xFF1A2456), const Color(0xFF6B5B95), 0.7),
    _Key(t.sunrise, const Color(0xFF3A6EA5), const Color(0xFFF6B26B), 0.25),
    _Key(t.dhuhr, const Color(0xFF2E86DE), const Color(0xFF8EC9FF), 0.0),
    _Key(t.asr, const Color(0xFF3B8EDB), const Color(0xFFF7D88A), 0.0),
    _Key(t.maghrib, const Color(0xFF3A2C6B), const Color(0xFFFF7A45), 0.3),
    _Key(t.isha, const Color(0xFF121A3A), const Color(0xFF3A2C6B), 0.8),
    _Key(t.isha.add(const Duration(minutes: 60)), const Color(0xFF070B1F),
        const Color(0xFF1B2447), 1.0),
  ];
  if (now.isBefore(k.first.t) || now.isAfter(k.last.t)) return _nightSky;
  for (var i = 0; i < k.length - 1; i++) {
    if (!now.isAfter(k[i + 1].t)) {
      final a = k[i];
      final b = k[i + 1];
      final span = b.t.difference(a.t).inSeconds;
      final f = span <= 0 ? 0.0 : now.difference(a.t).inSeconds / span;
      return _Sky(
        Color.lerp(a.top, b.top, f)!,
        Color.lerp(a.bottom, b.bottom, f)!,
        a.night + (b.night - a.night) * f,
      );
    }
  }
  return _nightSky;
}

final List<Offset> _stars = _genStars();

List<Offset> _genStars() {
  final r = math.Random(7);
  return List.generate(
    46,
    (_) => Offset(r.nextDouble(), r.nextDouble() * 0.62),
  );
}

double _c01(double v) => v < 0 ? 0.0 : (v > 1 ? 1.0 : v);

class _SkyPainter extends CustomPainter {
  final PrayerTimes? t;
  final DateTime now;
  final String nextName;
  final double age;
  _SkyPainter(this.t, this.now, this.nextName, this.age);

  void _mosque(Canvas c, double w, double h, Color col) {
    final p = Paint()..color = col;
    final g = h - 22.0;
    c.drawRect(Rect.fromLTWH(0, g, w, 22), p);
    c.drawRect(Rect.fromLTWH(w * 0.34, g - 34, w * 0.32, 34), p);
    c.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.5, g - 34),
        width: w * 0.24,
        height: w * 0.24,
      ),
      math.pi,
      math.pi,
      true,
      p,
    );
    c.drawRect(Rect.fromLTWH(w * 0.5 - 1, g - 34 - w * 0.12 - 14, 2, 14), p);
    for (final x in [0.39, 0.61]) {
      c.drawArc(
        Rect.fromCenter(
          center: Offset(w * x, g - 34),
          width: w * 0.09,
          height: w * 0.09,
        ),
        math.pi,
        math.pi,
        true,
        p,
      );
    }
    for (final x in [0.26, 0.74]) {
      final cm = w * x;
      c.drawRect(Rect.fromLTWH(cm - 5, g - 110, 10, 110), p);
      c.drawRect(Rect.fromLTWH(cm - 8, g - 90, 16, 5), p);
      final cone = Path()
        ..moveTo(cm - 6, g - 110)
        ..lineTo(cm, g - 135)
        ..lineTo(cm + 6, g - 110)
        ..close();
      c.drawPath(cone, p);
    }
    final hillL = Path()
      ..moveTo(0, g)
      ..quadraticBezierTo(w * 0.1, g - 30, w * 0.2, g)
      ..close();
    final hillR = Path()
      ..moveTo(w, g)
      ..quadraticBezierTo(w * 0.9, g - 30, w * 0.8, g)
      ..close();
    c.drawPath(hillL, p);
    c.drawPath(hillR, p);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sky = _skyAt(t, now);
    final rect = Rect.fromLTWH(0, 0, w, h);
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
      for (var i = 0; i < _stars.length; i++) {
        final s = _stars[i];
        final a = sky.night * (0.35 + 0.65 * ((i * 37) % 10) / 10);
        sp.color = Colors.white.withOpacity(_c01(a));
        canvas.drawCircle(
          Offset(s.dx * w, s.dy * h),
          0.6 + (i % 3) * 0.45,
          sp,
        );
      }
    }

    if (sky.night > 0.55) {
      final mc = Offset(w * 0.2, 128);
      canvas.drawCircle(
        mc,
        46,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withOpacity(_c01(0.22 * sky.night)),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: mc, radius: 46)),
      );
      paintMoon(canvas, mc, 22, age);
    }

    final cx = w / 2;
    final baseY = h - 88;
    final rx = w * 0.43;
    const ry = 118.0;
    Offset pt(double f) {
      final th = math.pi * f;
      return Offset(cx - rx * math.cos(th), baseY - ry * math.sin(th));
    }

    final arc = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i <= 60; i++) {
      final p = pt(i / 60);
      arc.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      arc,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withOpacity(0.28),
    );

    final tt = t;
    if (tt != null) {
      final span = tt.isha.difference(tt.fajr).inSeconds;
      double frac(DateTime x) =>
          span <= 0 ? 0.0 : x.difference(tt.fajr).inSeconds / span;
      final inDay = !now.isBefore(tt.fajr) && !now.isAfter(tt.isha);
      final fn = _c01(frac(now));

      if (inDay) {
        final prog = Path()..moveTo(pt(0).dx, pt(0).dy);
        final steps = (60 * fn).round();
        for (var i = 1; i <= steps; i++) {
          final p = pt(i / 60);
          prog.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(
          prog,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round
            ..color = Colors.white.withOpacity(0.9),
        );
      }

      final times = [tt.fajr, tt.dhuhr, tt.asr, tt.maghrib, tt.isha];
      for (var i = 0; i < 5; i++) {
        final pos = pt(_c01(frac(times[i])));
        final isNext = _pnames[i] == nextName;
        final passed = !times[i].isAfter(now);
        canvas.drawCircle(
          pos,
          isNext ? 7 : 5,
          Paint()
            ..color = isNext
                ? const Color(0xFFB6F36B)
                : (passed
                    ? Colors.white
                    : Colors.white.withOpacity(0.25)),
        );
        if (!passed && !isNext) {
          canvas.drawCircle(
            pos,
            5,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = Colors.white.withOpacity(0.85),
          );
        }
        final tp = TextPainter(
          text: TextSpan(
            text: _pnames[i],
            style: TextStyle(
              color: isNext
                  ? const Color(0xFFB6F36B)
                  : Colors.white.withOpacity(0.9),
              fontSize: 11,
              fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          textDirection: TextDirection.rtl,
        )..layout();
        var lx = pos.dx - tp.width / 2;
        if (lx < 4) lx = 4;
        if (lx > w - 4 - tp.width) lx = w - 4 - tp.width;
        tp.paint(canvas, Offset(lx, pos.dy - 24));
      }

      if (inDay) {
        final isSun = now.isAfter(tt.sunrise) && now.isBefore(tt.maghrib);
        final pos = pt(fn);
        final glow = isSun ? const Color(0xFFFFE08A) : const Color(0xFFFFB27A);
        canvas.drawCircle(
          pos,
          34,
          Paint()
            ..shader = RadialGradient(
              colors: [glow.withOpacity(0.55), Colors.transparent],
            ).createShader(Rect.fromCircle(center: pos, radius: 34)),
        );
        canvas.drawCircle(
          pos,
          isSun ? 13 : 9,
          Paint()
            ..color = isSun
                ? const Color(0xFFFFD54A)
                : const Color(0xFFFF9D6C),
        );
      }
    }

    _mosque(
      canvas,
      w,
      h,
      Color.lerp(
        const Color(0xFF04060D),
        const Color(0xFF123238),
        1 - sky.night,
      )!,
    );
  }

  @override
  bool shouldRepaint(_SkyPainter old) =>
      old.now != now || old.nextName != nextName || old.t != t;
}

class SkyHero extends StatefulWidget {
  final PrayerData? data;
  final NextInfo? next;
  final ValueListenable<Duration> left;
  final bool active;
  final VoidCallback onSearch;
  final VoidCallback onBell;
  final VoidCallback onTheme;
  final VoidCallback onAdhkar;
  const SkyHero({
    Key? key,
    required this.data,
    required this.next,
    required this.left,
    required this.active,
    required this.onSearch,
    required this.onBell,
    required this.onTheme,
    required this.onAdhkar,
  }) : super(key: key);

  @override
  State<SkyHero> createState() => _SkyHeroState();
}

class _SkyHeroState extends State<SkyHero> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 30), (_) {
      if (widget.active && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  Widget _btn(IconData i, VoidCallback f) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: f,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.18),
        ),
        child: Icon(i, color: Colors.white, size: 21),
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
    final prog =
        span <= 0 ? 0.0 : _c01(now.difference(prev).inSeconds / span);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.32),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
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
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${fmtTime(n.time)} ${ampm(n.time)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              const Spacer(),
              ValueListenableBuilder<Duration>(
                valueListenable: widget.left,
                builder: (context, l, _) => Text(
                  hms(l),
                  style: const TextStyle(
                    color: Color(0xFFB6F36B),
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: prog,
              minHeight: 5,
              color: const Color(0xFFB6F36B),
              backgroundColor: Colors.white24,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const hh = 370.0;
    final d = widget.data;
    final n = widget.next;
    final now = DateTime.now();
    final hij = HijriCalendar.fromDate(
      now.add(Duration(days: AppSettings.hijriOffset.value)),
    );
    final hour = now.hour;
    final greet = hour < 12
        ? 'صباح الخير'
        : hour < 17
            ? 'نهارك سعيد'
            : hour < 21
                ? 'مساء الخير'
                : 'ليلة سعيدة';
    final cta = hour < 12
        ? 'أذكار الصباح'
        : hour < 22
            ? 'أذكار المساء'
            : 'أذكار النوم';
    const shadow = [Shadow(blurRadius: 6, color: Colors.black38)];
    return SizedBox(
      height: hh + 56,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: hh,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _SkyPainter(
                    d?.times,
                    now,
                    (d != null && n != null) ? n.name : '',
                    moonAge(now),
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: hh,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          appName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            shadows: shadow,
                          ),
                        ),
                        const Spacer(),
                        _btn(Icons.search, widget.onSearch),
                        const SizedBox(width: 8),
                        _btn(Icons.notifications_none, widget.onBell),
                        const SizedBox(width: 8),
                        _btn(Icons.brightness_6, widget.onTheme),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greet,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                shadows: shadow,
                              ),
                            ),
                            Text(
                              '${hij.hDay} ${_hijriMonths[hij.hMonth - 1]} '
                              '${hij.hYear} هـ',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                shadows: shadow,
                              ),
                            ),
                            Text(
                              '${_days[now.weekday - 1]} ${now.day} '
                              '${_months[now.month - 1]} ${now.year}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                shadows: shadow,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                          onPressed: widget.onAdhkar,
                          child: Text(cta),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (d != null && n != null)
            Positioned(left: 16, right: 16, bottom: 0, child: _card(d, n))
          else
            const Positioned(
              left: 16,
              right: 16,
              bottom: 8,
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
