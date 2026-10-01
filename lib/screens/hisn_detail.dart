import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import 'hisn_service.dart';

class HisnDetail extends StatefulWidget {
  final HisnSection sec;
  const HisnDetail({Key? key, required this.sec}) : super(key: key);

  @override
  State<HisnDetail> createState() => _HisnDetailState();
}

class _HisnDetailState extends State<HisnDetail> {
  late List<int> counts;

  String _key(int i) {
    final n = DateTime.now();
    return 'hisn_${n.year}-${n.month}-${n.day}_${widget.sec.title}_$i';
  }

  @override
  void initState() {
    super.initState();
    counts = List.filled(widget.sec.texts.length, 0);
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      counts = List.generate(
        widget.sec.texts.length,
        (i) => p.getInt(_key(i)) ?? 0,
      );
    });
  }

  Future<void> _tap(int i) async {
    final max = countOf(widget.sec.texts[i]);
    if (counts[i] >= max) return;
    setState(() => counts[i]++);
    final p = await SharedPreferences.getInstance();
    await p.setInt(_key(i), counts[i]);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sec;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.title, style: const TextStyle(fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(kPaddingMedium),
        children: [
          for (var i = 0; i < s.texts.length; i++) _card(i),
          if (s.notes.isNotEmpty)
            ExpansionTile(
              title: const Text('المصادر'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(kPaddingMedium),
                  child: Text(s.notes.join('\n\n')),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _card(int i) {
    final t = widget.sec.texts[i];
    final max = countOf(t);
    final done = counts[i] >= max;
    return Card(
      color: done ? kGreen : kCardBackground,
      margin: const EdgeInsets.only(bottom: kPaddingMedium),
      child: InkWell(
        onTap: () => _tap(i),
        child: Padding(
          padding: const EdgeInsets.all(kPaddingMedium),
          child: Column(
            children: [
              Text(t, style: const TextStyle(fontSize: 19, height: 1.9)),
              const SizedBox(height: kPaddingSmall),
              Text(
                done ? 'تم ✓' : '${counts[i]} / $max',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
