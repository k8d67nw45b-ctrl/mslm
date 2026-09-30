import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import 'hajj_data.dart';

class HajjDetail extends StatefulWidget {
  final HajjKind kind;
  const HajjDetail({Key? key, required this.kind}) : super(key: key);

  @override
  State<HajjDetail> createState() => _HajjDetailState();
}

class _HajjDetailState extends State<HajjDetail> {
  Set<String> done = {};

  String get _key => 'hajj_done_${widget.kind.id}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => done = (prefs.getStringList(_key) ?? []).toSet());
  }

  Future<void> _toggle(String id) async {
    setState(() {
      if (done.contains(id)) {
        done.remove(id);
      } else {
        done.add(id);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, done.toList());
  }

  Future<void> _reset() async {
    setState(() => done = {});
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.kind.steps;
    final p = done.length / steps.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kind.title),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reset),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: p, minHeight: 6, color: kGreen),
          Padding(
            padding: const EdgeInsets.all(kPaddingSmall),
            child: Text('أنجزت ${done.length} من ${steps.length}'),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(kPaddingMedium),
              itemCount: steps.length,
              itemBuilder: (context, i) => _step(steps[i], i + 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(HajjStep s, int n) {
    final ok = done.contains(s.id);
    return Card(
      color: kCardBackground,
      margin: const EdgeInsets.only(bottom: kPaddingMedium),
      child: ExpansionTile(
        leading: Checkbox(
          value: ok,
          activeColor: kGreen,
          onChanged: (_) => _toggle(s.id),
        ),
        title: Text('$n. ${s.title}'),
        childrenPadding: const EdgeInsets.all(kPaddingMedium),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Text(s.details, style: const TextStyle(height: 1.8)),
          ),
          const SizedBox(height: kPaddingSmall),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              s.dua,
              style: const TextStyle(
                color: kGreen,
                fontSize: 18,
                height: 1.8,
              ),
            ),
          ),
          const SizedBox(height: kPaddingSmall),
          Align(
            alignment: Alignment.centerRight,
            child: Text('تنبيه: ${s.warning}'),
          ),
        ],
      ),
    );
  }
}
