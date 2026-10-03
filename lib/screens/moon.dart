import 'dart:math' as math;
import 'package:flutter/material.dart';

const double kSynodic = 29.530588853;

double moonAge(DateTime t) {
  final ref = DateTime.utc(2000, 1, 6, 18, 14);
  final days = t.toUtc().difference(ref).inMinutes / 1440.0;
  var a = days % kSynodic;
  if (a < 0) a += kSynodic;
  return a;
}

double moonLit(double age) {
  return (1 - math.cos(2 * math.pi * age / kSynodic)) / 2;
}

String moonName(double age) {
  if (age < 1.5) return 'المحاق';
  if (age < 6.4) return 'هلال متزايد';
  if (age < 8.4) return 'التربيع الأول';
  if (age < 13.4) return 'أحدب متزايد';
  if (age < 16.4) return 'بدر';
  if (age < 21.4) return 'أحدب متناقص';
  if (age < 23.4) return 'التربيع الأخير';
  if (age < 28) return 'هلال متناقص';
  return 'المحاق';
}

void paintMoon(
  Canvas canvas,
  Offset c,
  double r,
  double age, {
  Color lit = const Color(0xFFF3EBD0),
  Color dark = const Color(0x33FFFFFF),
}) {
  canvas.drawCircle(c, r, Paint()..color = dark);
  final waxing = age < kSynodic / 2;
  final k = math.cos(2 * math.pi * age / kSynodic);
  canvas.save();
  canvas.translate(c.dx, c.dy);
  if (!waxing) canvas.scale(-1, 1);
  final path = Path();
  final rect = Rect.fromCircle(center: Offset.zero, radius: r);
  path.arcTo(rect, -math.pi / 2, math.pi, false);
  final erect = Rect.fromCenter(
    center: Offset.zero,
    width: 2 * r * k.abs() + 0.01,
    height: 2 * r,
  );
  if (k > 0) {
    path.arcTo(erect, math.pi / 2, -math.pi, false);
  } else {
    path.arcTo(erect, math.pi / 2, math.pi, false);
  }
  path.close();
  canvas.drawPath(path, Paint()..color = lit);
  canvas.restore();
}
