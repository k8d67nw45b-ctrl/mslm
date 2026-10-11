import 'dart:math' as math;
import 'package:flutter/material.dart';

class _GardenPainter extends CustomPainter {
  final int q;
  final int a;
  final int p;
  final bool qt;
  final bool at;
  final bool pt;
  final double sway;
  final bool dark;
  _GardenPainter(this.q, this.a, this.p, this.qt, this.at, this.pt, this.sway,
      this.dark);

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
          colors: dark
              ? const [Color(0xFF0B1B2B), Color(0xFF16323F)]
              : const [Color(0xFFBFE3F5), Color(0xFFEAF6E4)],
        ).createShader(rect),
    );
    canvas.drawCircle(
      Offset(w * 0.86, h * 0.16),
      14,
      Paint()
        ..color = dark ? const Color(0xFFF3EBD0) : const Color(0xFFFFE08A),
    );
    final gy = h * 0.84;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, gy + 14),
        width: w * 1.1,
        height: h * 0.34,
      ),
      Paint()
        ..color = dark ? const Color(0xFF1F3B2A) : const Color(0xFF8FCB7A),
    );
    final maxH = h * 0.66;
    _plant(canvas, Offset(w * 0.2, gy), q, const Color(0xFFFFB74D), sway, maxH,
        qt);
    _plant(canvas, Offset(w * 0.5, gy), a, const Color(0xFFF48FB1), sway, maxH,
        at);
    _plant(canvas, Offset(w * 0.8, gy), p, const Color(0xFFBA68C8), sway, maxH,
        pt);
  }

  void _flower(Canvas c, Offset o, double r, Color col) {
    final pp = Paint()..color = col;
    for (var i = 0; i < 6; i++) {
      final ang = i * math.pi / 3;
      c.drawCircle(o + Offset(math.cos(ang), math.sin(ang)) * r * 0.9, r * 0.6,
          pp);
    }
    c.drawCircle(o, r * 0.55, Paint()..color = const Color(0xFFFFEB3B));
  }

  void _plant(Canvas c, Offset base, int lvl, Color flower, double sway,
      double maxH, bool glow) {
    if (glow) {
      c.drawCircle(
        base + Offset(0, -maxH * 0.3),
        maxH * 0.4,
        Paint()..color = const Color(0x33FFD54A),
      );
    }
    c.drawOval(
      Rect.fromCenter(center: base, width: 48, height: 12),
      Paint()..color = const Color(0xFF6B4423),
    );
    if (lvl <= 0) {
      c.drawOval(
        Rect.fromCenter(center: base.translate(0, -4), width: 10, height: 7),
        Paint()..color = const Color(0xFF8D6E63),
      );
      return;
    }
    final hgt = maxH * (0.22 + 0.156 * lvl);
    final top = Offset(base.dx + sway * (3 + lvl * 1.5), base.dy - hgt);
    final ctrl = Offset(base.dx + sway * (1 + lvl) - 6, base.dy - hgt * 0.5);
    Offset pt(double t) {
      final u = 1 - t;
      return Offset(
        u * u * base.dx + 2 * u * t * ctrl.dx + t * t * top.dx,
        u * u * base.dy + 2 * u * t * ctrl.dy + t * t * top.dy,
      );
    }

    c.drawPath(
      Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, top.dx, top.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 + lvl * 0.6
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF3E7D32),
    );
    const greens = [Color(0xFF43A047), Color(0xFF66BB6A), Color(0xFF2E7D32)];
    final n = lvl * 2;
    for (var i = 0; i < n; i++) {
      final t = 0.2 + 0.7 * (i / n);
      final side = i.isEven ? -1.0 : 1.0;
      final pos = pt(t);
      final ls = (8 + lvl * 1.5) * (1 - t * 0.5);
      c.save();
      c.translate(pos.dx, pos.dy);
      c.rotate(side * 0.6);
      c.drawOval(
        Rect.fromLTWH(side > 0 ? 0 : -ls * 1.6, -ls * 0.35, ls * 1.6, ls * 0.7),
        Paint()..color = greens[i % greens.length],
      );
      c.restore();
    }
    if (lvl == 1) {
      c.drawCircle(top, 4, Paint()..color = const Color(0xFF9CCC65));
    }
    if (lvl >= 3) {
      _flower(c, top, 5 + lvl.toDouble(), flower);
    }
    if (lvl >= 4) {
      _flower(c, pt(0.62) + const Offset(11, 0), 4.5, flower);
    }
    if (lvl >= 5) {
      _flower(c, pt(0.42) + const Offset(-12, 0), 4.5, flower);
      c.drawCircle(top + const Offset(0, -16), 2.2,
          Paint()..color = const Color(0xFFFFD54A));
    }
  }

  @override
  bool shouldRepaint(_GardenPainter o) =>
      o.sway != sway ||
      o.q != q ||
      o.a != a ||
      o.p != p ||
      o.qt != qt ||
      o.at != at ||
      o.pt != pt ||
      o.dark != dark;
}

class GardenView extends StatefulWidget {
  final int quran;
  final int adhkar;
  final int prayer;
  final bool quranToday;
  final bool adhkarToday;
  final bool prayerToday;
  final double height;
  const GardenView({
    Key? key,
    required this.quran,
    required this.adhkar,
    required this.prayer,
    this.quranToday = false,
    this.adhkarToday = false,
    this.prayerToday = false,
    this.height = 260,
  }) : super(key: key);

  @override
  State<GardenView> createState() => _GardenViewState();
}

class _GardenViewState extends State<GardenView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            size: Size(double.infinity, widget.height),
            painter: _GardenPainter(
              widget.quran,
              widget.adhkar,
              widget.prayer,
              widget.quranToday,
              widget.adhkarToday,
              widget.prayerToday,
              _c.value * 2 - 1,
              dark,
            ),
          ),
        ),
      ),
    );
  }
}
