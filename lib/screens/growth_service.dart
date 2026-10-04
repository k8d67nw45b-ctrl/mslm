import 'package:shared_preferences/shared_preferences.dart';

const List<int> kStageDays = [0, 1, 3, 7, 15, 30, 60, 120];
const List<String> kStageNames = [
  'بذرة',
  'نبتة',
  'شتلة',
  'شجيرة',
  'شجرة فتية',
  'شجرة وارفة',
  'شجرة مزهرة',
  'شجرة مثمرة',
];

int stageOf(int days) {
  var s = 0;
  for (var i = 1; i < kStageDays.length; i++) {
    if (days >= kStageDays[i]) s = i;
  }
  return s;
}

Future<int> loadActiveDays() async {
  final p = await SharedPreferences.getInstance();
  final days = <String>{};
  for (final k in p.getKeys()) {
    if (k.startsWith('st_pages_')) {
      final l = p.getStringList(k);
      if (l != null && l.isNotEmpty) days.add(k.substring(9));
    } else if (k.startsWith('st_tasbih_')) {
      if ((p.getInt(k) ?? 0) > 0) days.add(k.substring(10));
    } else if (k.startsWith('dadhkar_m_') || k.startsWith('dadhkar_e_')) {
      if ((p.getInt(k) ?? 0) > 0) {
        final rest = k.substring(10);
        final i = rest.lastIndexOf('_');
        if (i > 0) days.add(rest.substring(0, i));
      }
    }
  }
  return days.length;
}
