import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../core/constants.dart';
import '../core/theme_controller.dart';
import 'location_service.dart';
import 'rf_design.dart';
import 'rf_page.dart';

const _kaabaLat = 21.4225;
const _kaabaLon = 39.8262;

double _rad(double d) => d * math.pi / 180;

String _dirName(double b) {
  const names = [
    'شمال',
    'شمال شرقي',
    'شرق',
    'جنوب شرقي',
    'جنوب',
    'جنوب غربي',
    'غرب',
    'شمال غربي',
  ];
  final i = ((b + 22.5) / 45).floor() % 8;
  return names[i];
}

class _QiblaPainter extends CustomPainter {
  final double heading;
  final double bearing;
  final bool aligned;
  final bool dark;
  _QiblaPainter(this.heading, this.bearing, this.aligned, this.dark);

  void _text(Canvas c, String t, Color col, double size) {
    final tp = TextPainter(
      text: TextSpan(
        text: t,
        style: TextStyle(
          color: col,
          fontSize: size,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(-tp.width / 2, -tp.height / 2));
  }

  void _kaaba(Canvas canvas, Offset p, double s) {
    final body = Rect.fromCenter(center: p, width: s, height: s);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(s * 0.1)),
      Paint()..color = const Color(0xFF15110F),
    );
    final gold = Paint()..color = const Color(0xFFD4AF37);
    canvas.drawRect(
      Rect.fromLTWH(body.left, body.top + s * 0.22, s, s * 0.13),
      gold,
    );
    canvas.drawRect(
      Rect.fromLTWH(p.dx - s * 0.1, p.dy + s * 0.05, s * 0.2, s * 0.3),
      gold,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(s * 0.1)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFFD4AF37),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2 - 6;
    final ring = aligned ? kGreen : const Color(0xFF9AA5A0);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: dark
              ? const [Color(0xFF1A242B), Color(0xFF0F161B)]
              : const [Color(0xFFFFFFFF), Color(0xFFE9EFEC)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = aligned ? 7 : 4
        ..color = ring,
    );

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-_rad(heading));
    final tick = Paint()
      ..strokeWidth = 2
      ..color = dark ? Colors.white54 : Colors.black45;
    for (var i = 0; i < 72; i++) {
      canvas.save();
      canvas.rotate(_rad(i * 5.0));
      final len = i % 18 == 0 ? 22.0 : (i % 6 == 0 ? 16.0 : 10.0);
      canvas.drawLine(Offset(0, -r + 6), Offset(0, -r + 6 + len), tick);
      canvas.restore();
    }
    const labels = ['N', 'E', 'S', 'W'];
    for (var i = 0; i < 4; i++) {
      final a = _rad(i * 90.0);
      canvas.save();
      canvas.rotate(a);
      canvas.translate(0, -r + 42);
      canvas.rotate(_rad(heading) - a);
      _text(
        canvas,
        labels[i],
        i == 0 ? Colors.redAccent : (dark ? Colors.white70 : Colors.black54),
        16,
      );
      canvas.restore();
    }
    canvas.restore();

    final th = _rad(bearing - heading);
    final dir = Offset(math.sin(th), -math.cos(th));
    final kp = c + dir * (r - 38);
    canvas.drawLine(
      c,
      c + dir * (r - 62),
      Paint()
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = aligned ? kGreen : const Color(0xFFD4AF37),
    );
    canvas.drawCircle(c, 6, Paint()..color = aligned ? kGreen : Colors.grey);
    if (aligned) {
      canvas.drawCircle(
        kp,
        34,
        Paint()
          ..shader = RadialGradient(
            colors: [kGreen.withOpacity(0.6), Colors.transparent],
          ).createShader(Rect.fromCircle(center: kp, radius: 34)),
      );
    }
    _kaaba(canvas, kp, 30);

    final tri = Path()
      ..moveTo(c.dx - 9, c.dy - r - 1)
      ..lineTo(c.dx + 9, c.dy - r - 1)
      ..lineTo(c.dx, c.dy - r + 16)
      ..close();
    canvas.drawPath(
      tri,
      Paint()..color = aligned ? kGreen : const Color(0xFFD4AF37),
    );
  }

  @override
  bool shouldRepaint(_QiblaPainter old) =>
      old.heading != heading ||
      old.bearing != bearing ||
      old.aligned != aligned ||
      old.dark != dark;
}

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({Key? key}) : super(key: key);

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  double? qiblaBearing;
  double distance = 0;
  String? error;
  String place = '';
  double? _sm;
  bool _aligned = false;

  @override
  void initState() {
    super.initState();
    _loadQibla();
  }

  Future<void> _loadQibla() async {
    setState(() {
      error = null;
      qiblaBearing = null;
    });
    try {
      final loc = await getLocation();
      if (!mounted) return;
      setState(() {
        place = loc.name;
        qiblaBearing = _bearingToKaaba(loc.lat, loc.lon);
        distance = _distanceKm(loc.lat, loc.lon);
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  Future<void> _pick() async {
    final ok = await showCityPicker(context);
    if (ok) _loadQibla();
  }

  double _bearingToKaaba(double lat, double lon) {
    final dLon = _rad(_kaabaLon - lon);
    final y = math.sin(dLon) * math.cos(_rad(_kaabaLat));
    final x = math.cos(_rad(lat)) * math.sin(_rad(_kaabaLat)) -
        math.sin(_rad(lat)) * math.cos(_rad(_kaabaLat)) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  double _distanceKm(double lat, double lon) {
    const r = 6371.0;
    final dLat = _rad(_kaabaLat - lat);
    final dLon = _rad(_kaabaLon - lon);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat)) *
            math.cos(_rad(_kaabaLat)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _filter(double h) {
    if (_sm == null) {
      _sm = h;
      return h;
    }
    final d = ((h - _sm! + 540) % 360) - 180;
    _sm = (_sm! + d * 0.2 + 360) % 360;
    return _sm!;
  }

  Future<void> _buzz() async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 140));
    HapticFeedback.heavyImpact();
  }

  void _calibrate() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('معايرة البوصلة'),
        content: const Text(
          'أمسك الجوال وحرّكه ببطء في الهواء على شكل رقم 8 عدة مرات، '
          'وابعده عن المعادن والمغناطيس والأجهزة الكهربائية، ثم راقب '
          'الاتجاه من جديد.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  Widget _compass() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snap) {
        final raw = snap.data?.heading;
        if (raw == null) {
          return const RfCard(
            child: Text(
              'البوصلة غير متوفرة بهذا الجهاز',
              textAlign: TextAlign.center,
            ),
          );
        }
        final heading = _filter((raw + 360) % 360);
        final bearing = qiblaBearing!;
        final diff = ((bearing - heading + 540) % 360) - 180;
        final aligned = diff.abs() < 4;
        if (aligned && !_aligned) _buzz();
        _aligned = aligned;
        return Column(
          children: [
            RfCard(
              child: Column(
                children: [
                  TextButton.icon(
                    onPressed: _pick,
                    icon: const Icon(Icons.location_on, color: kGreen),
                    label: Text(
                      '${place.isEmpty ? 'تحديد الموقع' : place} (تغيير)',
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 300,
                    height: 300,
                    child: CustomPaint(
                      painter: _QiblaPainter(heading, bearing, aligned, dark),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    aligned
                        ? 'أنت باتجاه القبلة ✓'
                        : 'استدر حتى تصير الكعبة عند المؤشر',
                    style: TextStyle(
                      color: aligned ? kGreen : null,
                      fontWeight:
                          aligned ? FontWeight.bold : FontWeight.normal,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${bearing.round()}°',
                    style: const TextStyle(
                      fontSize: 46,
                      fontWeight: FontWeight.bold,
                      color: kGreen,
                    ),
                  ),
                  Text(
                    '(${_dirName(bearing)})',
                    style: const TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                ],
              ),
            ),
            RfCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.straighten, color: kGreen),
                      const SizedBox(width: 10),
                      const Text('المسافة إلى الكعبة'),
                      const Spacer(),
                      Text(
                        '${distance.round()} كم',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _calibrate,
                      icon: const Icon(Icons.explore),
                      label: const Text('معايرة البوصلة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: rfDeep,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'يرجى معايرة البوصلة للحصول على أدق النتائج، وإبعاد '
                    'الجوال عن المعادن والمغناطيس.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      RfPageHeader(
        title: 'اتجاه القبلة',
        subtitle: 'نحو الكعبة المشرفة',
        trailing: IconButton(
          icon: const Icon(Icons.brightness_6, color: Colors.white),
          onPressed: ThemeController.toggle,
        ),
      ),
    ];
    if (error != null) {
      children.add(
        RfCard(
          child: Column(
            children: [
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _pick,
                child: const Text('اختيار المدينة'),
              ),
              TextButton(
                onPressed: _loadQibla,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    } else if (qiblaBearing == null) {
      children.add(
        const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    } else {
      children.add(_compass());
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: children,
    );
  }
}
