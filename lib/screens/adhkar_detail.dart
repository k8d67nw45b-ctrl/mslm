import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import 'adhkar_data.dart';

class AdhkarDetail extends StatefulWidget {
  final AdhkarCategory cat;
  const AdhkarDetail({Key? key, required this.cat}) : super(key: key);

  @override
  State<AdhkarDetail> createState() => _AdhkarDetailState();
}

class _AdhkarDetailState extends State<AdhkarDetail> {
  late List<int> counts;
  bool loaded = false;

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  String _key(int i) => 'adhkar_${_today()}_${widget.cat.id}_$i';

  @override
  void initState() {
    super.initState();
    counts = List.filled(widget.cat.items.length, 0);
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      counts = List.generate(
          widget.cat.items.length, (i) => prefs.getInt(_key(i)) ?? 0);
      loaded = true;
    });
  }

  Future<void> _tap(int i) async {
    if (counts[i] >= widget.cat.items[i].count) return;
    setState(() => counts[i]++);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key(i), counts[i]);
  }

  Future<void> _reset() async {
    final prefs = await SharedPreferences.getInstance();
    for (var i = 0; i < counts.length; i++) {
      await prefs.remove(_key(i));
    }
    setState(() => counts = List.filled(counts.length, 0));
  }

  double get _progress {
    var total = 0;
    var done = 0;
    for (var i = 0; i < counts.length; i++) {
      total += widget.cat.items[i].count;
      done += counts[i];
    }
    return total == 0 ? 0 : done / total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cat.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'إعادة التعيين',
            onPressed: _reset,
          ),
        ],
      ),
      body: !loaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                LinearProgressIndicator(
                  value: _progress,
                  minHeight: 6,
                  color: kGreen,
                  backgroundColor: kCardBackground,
                ),
                Padding(
                  padding: const EdgeInsets.all(kPaddingSmall),
                  child: Text('الإنجاز: ${(_progress * 100).round()}%'),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(kPaddingMedium),
                    itemCount: widget.cat.items.length,
                    itemBuilder: (context, i) => _card(i),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _card(int i) {
    final d = widget.cat.items[i];
    final done = counts[i] >= d.count;
    return Card(
      color: done ? kGreen : kCardBackground,
      margin: const EdgeInsets.only(bottom: kPaddingMedium),
      child: InkWell(
        onTap: () => _tap(i),
        child: Padding(
          padding: const EdgeInsets.all(kPaddingMedium),
          child: Column(
            children: [
              Text(
                d.text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, height: 1.8),
              ),
              const SizedBox(height: kPaddingSmall),
              Text(
                done ? 'تم ✓' : '${counts[i]} / ${d.count}',
                style: const TextStyle(
                  fontSize: 18,
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
