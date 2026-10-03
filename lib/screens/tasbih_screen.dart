import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import 'stats_service.dart';

const _dhikrs = [
  'سبحان الله',
  'الحمد لله',
  'الله أكبر',
  'لا إله إلا الله',
  'أستغفر الله',
  'اللهم صل وسلم على نبينا محمد',
  'سبحان الله وبحمده',
  'لا حول ولا قوة إلا بالله',
];
const _targets = [33, 100, 1000, 0];

class _Ring extends CustomPainter {
  final double value;
  final Color fill;
  const _Ring(this.value, this.fill);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 8;
    canvas.drawCircle(c, r, Paint()..color = fill);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = kGreen.withOpacity(0.2),
    );
    if (value > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        2 * math.pi * value,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round
          ..color = kGreen,
      );
    }
  }

  @override
  bool shouldRepaint(_Ring old) => old.value != value || old.fill != fill;
}

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({Key? key}) : super(key: key);

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  int sel = 0;
  List<int> counts = List.filled(_dhikrs.length, 0);
  int target = 33;
  bool vib = true;
  int pending = 0;
  int today = 0;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _t?.cancel();
    _flush();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    final s = p.getInt('tasbih_sel') ?? 0;
    setState(() {
      sel = (s >= 0 && s < _dhikrs.length) ? s : 0;
      counts = List.generate(
        _dhikrs.length,
        (i) => p.getInt('tasbih_c_$i') ?? 0,
      );
      target = p.getInt('tasbih_target') ?? 33;
      vib = p.getBool('tasbih_vib') ?? true;
      today = p.getInt('st_tasbih_${dayKey(DateTime.now())}') ?? 0;
    });
  }

  Future<void> _flush() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('tasbih_sel', sel);
    for (var i = 0; i < counts.length; i++) {
      await p.setInt('tasbih_c_$i', counts[i]);
    }
    if (pending > 0) {
      final n = pending;
      pending = 0;
      await addTasbih(n);
    }
  }

  void _later() {
    _t?.cancel();
    _t = Timer(const Duration(milliseconds: 800), _flush);
  }

  void _tap() {
    setState(() {
      counts[sel]++;
      today++;
    });
    pending++;
    if (vib) {
      if (target > 0 && counts[sel] % target == 0) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.selectionClick();
      }
    }
    _later();
  }

  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تصفير العدّاد'),
        content: Text('تصفير عدّاد «${_dhikrs[sel]}»؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تصفير'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() => counts[sel] = 0);
      _later();
    }
  }

  Future<void> _setPref(String k, Object v) async {
    final p = await SharedPreferences.getInstance();
    if (v is int) await p.setInt(k, v);
    if (v is bool) await p.setBool(k, v);
  }

  @override
  Widget build(BuildContext context) {
    final c = counts[sel];
    final value = (target == 0 || c == 0)
        ? 0.0
        : (((c - 1) % target) + 1) / target;
    return Scaffold(
      appBar: AppBar(
        title: const Text('المسبحة'),
        actions: [
          IconButton(
            icon: Icon(vib ? Icons.vibration : Icons.mobile_off),
            onPressed: () {
              setState(() => vib = !vib);
              _setPref('tasbih_vib', vib);
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reset),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _dhikrs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => ChoiceChip(
                  label: Text(_dhikrs[i]),
                  selected: sel == i,
                  onSelected: (_) {
                    setState(() => sel = i);
                    _later();
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _dhikrs[sel],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 30,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => _tap(),
              child: RepaintBoundary(
                child: SizedBox(
                  width: 260,
                  height: 260,
                  child: CustomPaint(
                    painter: _Ring(value, kCardBackground),
                    child: Center(
                      child: Text(
                        '$c',
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              target == 0
                  ? 'اليوم: $today'
                  : 'الدورات: ${c ~/ target}   •   اليوم: $today',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final t in _targets)
                  ChoiceChip(
                    label: Text(t == 0 ? 'مفتوح' : '$t'),
                    selected: target == t,
                    onSelected: (_) {
                      setState(() => target = t);
                      _setPref('tasbih_target', t);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
