import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import 'quran_reader.dart';
import 'quran_service.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({Key? key}) : super(key: key);

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  List<SurahInfo>? surahs;
  String? error;
  int? lastN;
  String? lastName;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => error = null);
    try {
      final s = await loadSurahList();
      setState(() => surahs = s);
    } catch (e) {
      setState(() => error = e.toString());
    }
    await _loadLast();
  }

  Future<void> _loadLast() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      lastN = prefs.getInt('quran_last_n');
      lastName = prefs.getString('quran_last_name');
    });
  }

  Future<void> _open(SurahInfo s) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QuranReader(surah: s)),
    );
    _loadLast();
  }

  @override
  Widget build(BuildContext context) {
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
    if (surahs == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final list = surahs!;
    return ListView(
      padding: const EdgeInsets.all(kPaddingMedium),
      children: [
        if (lastN != null) _continueCard(list),
        for (final s in list) _tile(s),
      ],
    );
  }

  Widget _continueCard(List<SurahInfo> list) {
    return Card(
      color: kGreen,
      margin: const EdgeInsets.only(bottom: kPaddingMedium),
      child: ListTile(
        title: Text('متابعة القراءة: $lastName'),
        trailing: const Icon(Icons.chevron_left),
        onTap: () => _open(list.firstWhere((s) => s.number == lastN)),
      ),
    );
  }

  Widget _tile(SurahInfo s) {
    return Card(
      color: kCardBackground,
      margin: const EdgeInsets.only(bottom: kPaddingSmall),
      child: ListTile(
        leading: Text(
          '${s.number}',
          style: const TextStyle(color: kGreen, fontSize: 18),
        ),
        title: Text(s.name, style: const TextStyle(fontSize: 20)),
        subtitle: Text('${s.ayahs} آية'),
        onTap: () => _open(s),
      ),
    );
  }
}
