import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({Key? key}) : super(key: key);

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  int count = 0;
  int target = 33;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      count = p.getInt('tasbih_count') ?? 0;
      target = p.getInt('tasbih_target') ?? 33;
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('tasbih_count', count);
    await p.setInt('tasbih_target', target);
  }

  void _tap() {
    setState(() => count++);
    if (count % target == 0) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    _save();
  }

  void _reset() {
    setState(() => count = 0);
    _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المسبحة'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reset),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _tap,
              child: Container(
                width: 230,
                height: 230,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: kGreen,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('الدورات: ${count ~/ target}'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final t in [33, 99, 100])
                  ChoiceChip(
                    label: Text('$t'),
                    selected: target == t,
                    onSelected: (_) {
                      setState(() => target = t);
                      _save();
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
