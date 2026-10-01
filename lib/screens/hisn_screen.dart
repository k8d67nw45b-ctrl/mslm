import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'hisn_detail.dart';
import 'hisn_service.dart';

class HisnScreen extends StatefulWidget {
  const HisnScreen({Key? key}) : super(key: key);

  @override
  State<HisnScreen> createState() => _HisnScreenState();
}

class _HisnScreenState extends State<HisnScreen> {
  List<HisnSection>? all;
  String? error;
  String q = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => error = null);
    try {
      final d = await loadHisn();
      setState(() => all = d);
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حصن المسلم')),
      body: _body(),
    );
  }

  Widget _body() {
    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(error!),
            const SizedBox(height: kPaddingMedium),
            ElevatedButton(
              onPressed: _load,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }
    if (all == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final list = all!.where((s) => s.title.contains(q)).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(kPaddingMedium),
          child: TextField(
            onChanged: (v) => setState(() => q = v),
            decoration: const InputDecoration(
              hintText: 'ابحث في الأبواب',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: kPaddingMedium),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final s = list[i];
              return Card(
                color: kCardBackground,
                margin: const EdgeInsets.only(bottom: kPaddingSmall),
                child: ListTile(
                  title: Text(s.title),
                  trailing: const Icon(Icons.chevron_left, color: kGreen),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HisnDetail(sec: s),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
