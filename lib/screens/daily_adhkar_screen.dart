import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import 'daily_adhkar.dart';

class DailyAdhkarScreen extends StatefulWidget {
  final bool morning;
  const DailyAdhkarScreen({Key? key, required this.morning})
      : super(key: key);

  @override
  State<DailyAdhkarScreen> createState() => _DailyAdhkarScreenState();
}

class _DailyAdhkarScreenState extends State<DailyAdhkarScreen> {
  List<AdhkarItem>? items;
  List<int> counts = [];
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await loadAdhkar(widget.morning);
      final p = await SharedPreferences.getInstance();
      setState(() {
        items = list;
        counts = List.generate(
          list.length,
          (i) => p.getInt(adhkarKey(widget.morning, i)) ?? 0,
        );
      });
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  Future<void> _tap(int i) async {
    if (counts[i] >= items![i].count) return;
    setState(() => counts[i]++);
    final p = await SharedPreferences.getInstance();
    await p.setInt(adhkarKey(widget.morning, i), counts[i]);
  }

  Future<void> _reset() async {
    final p = await SharedPreferences.getInstance();
    for (var i = 0; i < counts.length; i++) {
      await p.remove(adhkarKey(widget.morning, i));
    }
    setState(() => counts = List.filled(counts.length, 0));
  }

  double get _progress {
    var total = 0;
    var done = 0;
    for (var i = 0; i < counts.length; i++) {
      total += items![i].count;
      done += counts[i];
    }
    return total == 0 ? 0.0 : done / total;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.morning ? 'أذكار الصباح' : 'أذكار المساء';
    Widget body;
    if (error != null) {
      body = Center(child: Text(error!));
    } else if (items == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = Column(
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
              itemCount: items!.length,
              itemBuilder: (context, i) => _card(i),
            ),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reset),
        ],
      ),
      body: body,
    );
  }

  Widget _card(int i) {
    final d = items![i];
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
                style: const TextStyle(fontSize: 20, height: 1.9),
              ),
              if (d.fadl.isNotEmpty) ...[
                const SizedBox(height: kPaddingSmall),
                Text(
                  d.fadl,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
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
