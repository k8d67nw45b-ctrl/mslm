import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'prayer_tracker_service.dart';

int _toInt(String s) {
  var t = s.trim();
  const ar = '٠١٢٣٤٥٦٧٨٩';
  for (var i = 0; i < 10; i++) {
    t = t.replaceAll(ar[i], '$i');
  }
  return int.tryParse(t) ?? 0;
}

class QadaScreen extends StatefulWidget {
  const QadaScreen({Key? key}) : super(key: key);

  @override
  State<QadaScreen> createState() => _QadaScreenState();
}

class _QadaScreenState extends State<QadaScreen> {
  List<int> q = List.filled(5, 0);
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final x = await loadQada();
    if (!mounted) return;
    setState(() {
      q = x;
      loaded = true;
    });
  }

  Future<void> _add(int i, int d) async {
    await addQada(i, d);
    await _load();
  }

  Future<void> _bulk() async {
    final c = TextEditingController();
    final n = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة أيام فائتة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('عدد الأيام التي فاتتك فيها الصلوات الخمس كلها:'),
            TextField(
              controller: c,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'مثال: 10'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _toInt(c.text)),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
    if (n == null || n <= 0) return;
    for (var i = 0; i < 5; i++) {
      await addQada(i, n);
    }
    await _load();
  }

  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تصفير القضاء'),
        content: const Text('سيُصفَّر عدّاد كل الصلوات. متأكد؟'),
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
    if (ok != true) return;
    for (var i = 0; i < 5; i++) {
      await addQada(i, -q[i]);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final total = q.fold<int>(0, (a, b) => a + b);
    return Scaffold(
      appBar: AppBar(
        title: const Text('قضاء الفوائت'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _reset,
          ),
        ],
      ),
      body: !loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(kPaddingMedium),
              children: [
                Card(
                  color: kCardBackground,
                  child: Padding(
                    padding: const EdgeInsets.all(kPaddingMedium),
                    child: Column(
                      children: [
                        Text(
                          '$total',
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                            color: kGreen,
                          ),
                        ),
                        const Text('صلاة متبقية للقضاء'),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _bulk,
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة أيام فائتة'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: kPaddingSmall),
                for (var i = 0; i < 5; i++)
                  Card(
                    color: kCardBackground,
                    child: ListTile(
                      title: Text(kPrayerNames[i]),
                      subtitle: const Text('(−) قضيت واحدة   (+) فائتة'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: q[i] > 0 ? () => _add(i, -1) : null,
                          ),
                          SizedBox(
                            width: 36,
                            child: Text(
                              '${q[i]}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => _add(i, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'الصلاة اللي تعلّمها «فاتتني» بشاشة المتابعة تنضاف هنا '
                    'تلقائياً. الأرقام للمتابعة الشخصية، وأحكام القضاء '
                    'وترتيبه ترجع فيها لعالم أو جهة إفتاء.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ],
            ),
    );
  }
}
