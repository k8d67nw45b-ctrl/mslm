import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../core/constants.dart';
import 'compass_painter.dart';
import 'location_service.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({Key? key}) : super(key: key);

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  double? qiblaBearing;
  String? error;
  String place = '';

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
      setState(() {
        place = loc.name;
        qiblaBearing = _bearingToKaaba(loc.lat, loc.lon);
      });
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  Future<void> _pick() async {
    final ok = await showCityPicker(context);
    if (ok) _loadQibla();
  }

  double _bearingToKaaba(double lat, double lon) {
    const kaabaLat = 21.4225;
    const kaabaLon = 39.8262;
    double rad(double d) => d * math.pi / 180;
    final dLon = rad(kaabaLon - lon);
    final y = math.sin(dLon) * math.cos(rad(kaabaLat));
    final x = math.cos(rad(lat)) * math.sin(rad(kaabaLat)) -
        math.sin(rad(lat)) * math.cos(rad(kaabaLat)) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
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
        final heading = snap.data?.heading;
        if (heading == null) {
          return const Center(
            child: Text('البوصلة غير متوفرة بهذا الجهاز'),
          );
        }
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
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: kGreen, width: 3),
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
                '${qiblaBearing!.toStringAsFixed(1)}°',
                style: const TextStyle(
                  color: kGreen,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: kPaddingSmall),
              const Text('السهم الأخضر يشير إلى القبلة'),
            ],
          ),
        );
      },
    );
  }
}
