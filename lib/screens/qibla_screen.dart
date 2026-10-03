import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../core/constants.dart';
import 'compass_painter.dart';
import 'location_service.dart';

const _kaabaLat = 21.4225;
const _kaabaLon = 39.8262;

double _rad(double d) => d * math.pi / 180;

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

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(kPaddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: kPaddingMedium),
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
    }
    if (qiblaBearing == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return _buildCompass();
  }

  Widget _buildCompass() {
    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snap) {
        final raw = snap.data?.heading;
        if (raw == null) {
          return const Center(
            child: Text('البوصلة غير متوفرة بهذا الجهاز'),
          );
        }
        final heading = _filter((raw + 360) % 360);
        final diff = ((qiblaBearing! - heading + 540) % 360) - 180;
        final aligned = diff.abs() < 4;
        if (aligned && !_aligned) HapticFeedback.mediumImpact();
        _aligned = aligned;
        final dialAngle = -heading * math.pi / 180;
        final arrowAngle = (qiblaBearing! - heading) * math.pi / 180;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'اتجاه القبلة',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton.icon(
                onPressed: _pick,
                icon: const Icon(Icons.location_on, color: kGreen),
                label: Text('الموقع: $place (تغيير)'),
              ),
              const SizedBox(height: kPaddingMedium),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: aligned ? kGreen : Colors.grey,
                    width: aligned ? 6 : 3,
                  ),
                  color: kCardBackground,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.rotate(
                      angle: dialAngle,
                      child: CustomPaint(
                        size: const Size(260, 260),
                        painter: CompassPainter(),
                      ),
                    ),
                    Transform.rotate(
                      angle: arrowAngle,
                      child: const Icon(
                        Icons.navigation,
                        color: kGreen,
                        size: 90,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: kPaddingLarge),
              Text(
                aligned
                    ? 'أنت باتجاه القبلة ✓'
                    : 'استدر حتى يتوجه السهم للأعلى',
                style: TextStyle(
                  color: aligned ? kGreen : null,
                  fontWeight: aligned ? FontWeight.bold : FontWeight.normal,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: kPaddingSmall),
              Text(
                'زاوية القبلة: ${qiblaBearing!.toStringAsFixed(1)}°',
                style: const TextStyle(color: kGreen, fontSize: 16),
              ),
              Text('المسافة إلى الكعبة: ${distance.round()} كم'),
              const SizedBox(height: kPaddingSmall),
              const Text(
                'ابعد الجوال عن المعادن والمغناطيس، وحرّكه بشكل 8 للمعايرة',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}
