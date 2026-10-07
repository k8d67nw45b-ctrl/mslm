import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

double _num(String s) {
  var t = s.trim();
  const ar = '٠١٢٣٤٥٦٧٨٩';
  for (var i = 0; i < 10; i++) {
    t = t.replaceAll(ar[i], '$i');
  }
  t = t
      .replaceAll('٫', '.')
      .replaceAll(',', '')
      .replaceAll('٬', '')
      .replaceAll(' ', '');
  return double.tryParse(t) ?? 0;
}

String _fmt(double v) {
  final neg = v < 0;
  var s = v.abs().toStringAsFixed(2);
  if (s.endsWith('.00')) s = s.substring(0, s.length - 3);
  final parts = s.split('.');
  final ip = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < ip.length; i++) {
    if (i > 0 && (ip.length - i) % 3 == 0) buf.write(',');
    buf.write(ip[i]);
  }
  final r = parts.length > 1 ? '${buf.toString()}.${parts[1]}' : buf.toString();
  return neg ? '-$r' : r;
}

const _keys = [
  'cash',
  'gold',
  'silver',
  'trade',
  'invest',
  'recv',
  'debt',
  'gprice',
  'sprice',
];

class ZakatScreen extends StatefulWidget {
  const ZakatScreen({Key? key}) : super(key: key);

  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends State<ZakatScreen> {
  final Map<String, TextEditingController> c = {
    for (final k in _keys) k: TextEditingController(),
  };
  int karat = 24;
  String basis = 'gold';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final x in c.values) {
      x.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    for (final k in _keys) {
      c[k]!.text = p.getString('zk_$k') ?? '';
    }
    if (!mounted) return;
    setState(() {
      karat = p.getInt('zk_karat') ?? 24;
      basis = p.getString('zk_basis') ?? 'gold';
    });
  }

  Future<void> _save(String k, String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('zk_$k', v);
  }

  Future<void> _savePref() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('zk_karat', karat);
    await p.setString('zk_basis', basis);
  }

  Future<void> _reset() async {
    final p = await SharedPreferences.getInstance();
    for (final k in _keys) {
      await p.remove('zk_$k');
      c[k]!.clear();
    }
    setState(() {});
  }

  Widget _field(String k, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c[k],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: (v) {
          _save(k, v);
          setState(() {});
        },
      ),
    );
  }

  Widget _title(String t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(
        t,
        style: const TextStyle(
          color: kGreen,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _line(String a, String b, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(a),
          const Spacer(),
          Text(
            b,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cash = _num(c['cash']!.text);
    final goldG = _num(c['gold']!.text);
    final silverG = _num(c['silver']!.text);
    final trade = _num(c['trade']!.text);
    final invest = _num(c['invest']!.text);
    final recv = _num(c['recv']!.text);
    final debt = _num(c['debt']!.text);
    final gp = _num(c['gprice']!.text);
    final sp = _num(c['sprice']!.text);

    final goldVal = goldG * karat / 24 * gp;
    final silverVal = silverG * sp;
    final assets = cash + goldVal + silverVal + trade + invest + recv;
    final net = assets - debt;
    final nisabGrams = basis == 'gold' ? 85.0 : 595.0;
    final price = basis == 'gold' ? gp : sp;
    final ready = price > 0;
    final nisab = ready ? nisabGrams * price : 0.0;
    final due = ready && net > 0 && net >= nisab;
    final zakat = due ? net * 0.025 : 0.0;
    final needGoldPrice = goldG > 0 && gp <= 0;
    final needSilverPrice = silverG > 0 && sp <= 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('حاسبة زكاة المال'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reset,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(kPaddingMedium),
        children: [
          _title('الأسعار (بنفس عملة أموالك)'),
          _field('gprice', 'سعر غرام الذهب عيار 24'),
          _field('sprice', 'سعر غرام الفضة'),
          _title('أموالك'),
          _field('cash', 'النقد والأرصدة البنكية'),
          _field('gold', 'الذهب (بالغرام)'),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('العيار:'),
                for (final k in const [24, 22, 21, 18])
                  ChoiceChip(
                    label: Text('$k'),
                    selected: karat == k,
                    onSelected: (_) {
                      setState(() => karat = k);
                      _savePref();
                    },
                  ),
              ],
            ),
          ),
          _field('silver', 'الفضة (بالغرام)'),
          _field('trade', 'عروض التجارة (قيمتها الآن)'),
          _field('invest', 'الأسهم والاستثمارات (قيمتها الآن)'),
          _field('recv', 'ديون لك مرجوّة السداد'),
          _field('debt', 'ديون عليك حالّة (تُخصم)'),
          _title('معيار النصاب'),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('الذهب (85 غرام)'),
                selected: basis == 'gold',
                onSelected: (_) {
                  setState(() => basis = 'gold');
                  _savePref();
                },
              ),
              ChoiceChip(
                label: const Text('الفضة (595 غرام)'),
                selected: basis == 'silver',
                onSelected: (_) {
                  setState(() => basis = 'silver');
                  _savePref();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'العلماء مختلفون في معيار النصاب للنقود الورقية، فاعتمد ما تفتي '
            'به جهتك.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Card(
            color: kCardBackground,
            child: Padding(
              padding: const EdgeInsets.all(kPaddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'النتيجة',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  _line('إجمالي الأموال', _fmt(assets)),
                  _line('الديون الحالّة', _fmt(debt)),
                  _line('الصافي', _fmt(net), bold: true),
                  _line(
                    'النصاب',
                    ready ? _fmt(nisab) : 'أدخل سعر الغرام',
                  ),
                  const Divider(),
                  if (needGoldPrice || needSilverPrice)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'أدخلت ذهباً أو فضة بدون سعر، فلم تُحسب قيمتها.',
                        style: TextStyle(color: Colors.orangeAccent),
                      ),
                    ),
                  if (!ready)
                    Text(
                      'أدخل سعر غرام ${basis == 'gold' ? 'الذهب' : 'الفضة'} '
                      'لتحديد النصاب.',
                    )
                  else if (due) ...[
                    const Text('بلغ مالُك النصاب، والزكاة (2.5%):'),
                    const SizedBox(height: 4),
                    Text(
                      _fmt(zakat),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: kGreen,
                      ),
                    ),
                  ] else
                    const Text('لم يبلغ مالُك النصاب، فلا زكاة عليك الآن.'),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'النصاب: 85 غراماً من الذهب الخالص أو 595 غراماً من الفضة، '
              'والمقدار ربع العشر (2.5%) إذا مرّ على المال حول هجري كامل. '
              'حلي الاستعمال والديون ومسائل أخرى فيها خلاف بين العلماء. '
              'هذه الحاسبة للمساعدة فقط ولا تغني عن سؤال عالم أو جهة '
              'إفتاء موثوقة.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
