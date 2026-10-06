import 'dart:math' as math;
import 'package:flutter/material.dart';

class _TreePainter extends CustomPainter {
  final int level;
  final int streak;
  final double sway;
  final bool dark;
  _TreePainter(this.level, this.streak, this.sway, this.dark);

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
      Offset(w * 0.84, h * 0.2),
      15,
      Paint()
        ..color =
            dark ? const Color(0xFFF3EBD0) : const Color(0xFFFFE08A),
    );
    final gy = h * 0.86;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, gy + 12),
        width: w * 0.95,
        height: h * 0.3,
      ),
      Paint()
        ..color = dark ? const Color(0xFF1F3B2A) : const Color(0xFF8FCB7A),
    );
    final base = Offset(w / 2, gy);

    if (level == 0) {
      canvas.drawOval(
        Rect.fromCenter(center: base, width: 16, height: 10),
        Paint()..color = const Color(0xFF6B4423),
      );
      return;
    }

    const depthByLevel = [0, 2, 3, 4, 5, 6, 6, 7];
    final maxD = depthByLevel[level];
    final trunkLen = h * (0.10 + 0.035 * level);
    final rng = math.Random(11);
    final leafR = 5.0 + level * 0.7;
    const greens = [
      Color(0xFF2E7D32),
      Color(0xFF43A047),
      Color(0xFF66BB6A),
      Color(0xFF81C784),
    ];

    void leaves(Offset p) {
      for (var i = 0; i < 3; i++) {
        final o = Offset(
          p.dx + (rng.nextDouble() - 0.5) * leafR * 1.8,
          p.dy + (rng.nextDouble() - 0.5) * leafR * 1.8,
        );
        canvas.drawCircle(
          o,
          leafR * (0.7 + rng.nextDouble() * 0.5),
          Paint()..color = greens[rng.nextInt(greens.length)],
        );
      }
      final r = rng.nextDouble();
      if (level >= 6 && r < 0.28) {
        canvas.drawCircle(p, 4, Paint()..color = const Color(0xFFF48FB1));
      } else if (level >= 7 && r > 0.82) {
        canvas.drawCircle(p, 4.5, Paint()..color = const Color(0xFFFFC107));
      }
    }

    void branch(Offset p, double ang, double len, int d) {
      final a = ang + sway * 0.025 * (maxD - d + 1);
      final end = p + Offset(math.sin(a), -math.cos(a)) * len;
      canvas.drawLine(
        p,
        end,
        Paint()
          ..color = Color.lerp(
            const Color(0xFF5D3A1A),
            const Color(0xFF8B5E34),
            1 - d / maxD,
          )!
          ..strokeWidth = d * 1.7 + 0.8
          ..strokeCap = StrokeCap.round,
      );
      if (d <= 1) {
        leaves(end);
        return;
      }
      final spread = 0.42 + rng.nextDouble() * 0.25;
      final shrink = 0.70 + rng.nextDouble() * 0.08;
      branch(end, a - spread, len * shrink, d - 1);
      branch(
        end,
        a + spread * (0.8 + rng.nextDouble() * 0.4),
        len * shrink,
        d - 1,
      );
      if (d >= 3 && rng.nextDouble() < 0.35) {
        branch(end, a, len * shrink * 0.8, d - 1);
      }
    }

    branch(base, 0, trunkLen, maxD);

    if (streak >= 7) {
      final sp = Paint()..color = const Color(0xFFFFD54A);
      for (var i = 0; i < 7; i++) {
        canvas.drawCircle(
          Offset(
            w * (0.14 + 0.12 * i),
            h * (0.14 + 0.06 * math.sin(i * 1.7 + sway)),
          ),
          1.8,
          sp,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_TreePainter old) =>
      old.sway != sway ||
      old.level != level ||
      old.streak != streak ||
      old.dark != dark;
}

class GrowthTree extends StatefulWidget {
  final int level;
  final int streak;
  final bool animate;
  final double height;
  const GrowthTree({
    Key? key,
    required this.level,
    required this.streak,
    this.animate = true,
    this.height = 200,
  }) : super(key: key);

  @override
  State<GrowthTree> createState() => _GrowthTreeState();
}

class _GrowthTreeState extends State<GrowthTree>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant GrowthTree old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.animate && _c.isAnimating) {
      _c.stop();
    }
  }

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
            painter: _TreePainter(
              widget.level,
              widget.streak,
              _c.value * 2 - 1,
              dark,
            ),
          ),
        ),
      ),
    );
  }
}
