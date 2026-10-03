import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../core/theme_controller.dart';

const Map<int, String> readThemeNames = {
  0: 'تلقائي',
  1: 'ورقي أبيض',
  2: 'بيج (Sepia)',
  3: 'ليلي هادئ',
  4: 'أسود حقيقي',
};

class AppSettings {
  static final ValueNotifier<double> fontScale = ValueNotifier<double>(1.0);
  static final ValueNotifier<int> hijriOffset = ValueNotifier<int>(0);
  static final ValueNotifier<int> readTheme = ValueNotifier<int>(0);

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    fontScale.value = p.getDouble('font_scale') ?? 1.0;
    hijriOffset.value = p.getInt('hijri_offset') ?? 0;
    readTheme.value = p.getInt('read_theme') ?? 0;
    kAmoled = p.getBool('amoled') ?? false;
  }

  static Future<void> setFontScale(double v) async {
    fontScale.value = v;
    final p = await SharedPreferences.getInstance();
    await p.setDouble('font_scale', v);
  }

  static Future<void> setHijriOffset(int v) async {
    hijriOffset.value = v;
    final p = await SharedPreferences.getInstance();
    await p.setInt('hijri_offset', v);
  }

  static Future<void> setReadTheme(int v) async {
    readTheme.value = v;
    final p = await SharedPreferences.getInstance();
    await p.setInt('read_theme', v);
  }

  static Future<void> setAmoled(bool v) async {
    kAmoled = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool('amoled', v);
    ThemeController.refresh();
  }
}

const Map<String, String> calcMethodNames = {
  'umm_al_qura': 'أم القرى (مكة المكرمة)',
  'muslim_world_league': 'رابطة العالم الإسلامي',
  'egyptian': 'الهيئة المصرية العامة للمساحة',
  'karachi': 'جامعة العلوم الإسلامية بكراتشي',
  'dubai': 'دبي',
  'qatar': 'قطر',
  'kuwait': 'الكويت',
  'singapore': 'سنغافورة',
  'north_america': 'أمريكا الشمالية',
};

CalculationParameters calcParamsFor(String method, String madhab) {
  CalculationParameters p;
  switch (method) {
    case 'muslim_world_league':
      p = CalculationMethod.muslim_world_league.getParameters();
      break;
    case 'egyptian':
      p = CalculationMethod.egyptian.getParameters();
      break;
    case 'karachi':
      p = CalculationMethod.karachi.getParameters();
      break;
    case 'dubai':
      p = CalculationMethod.dubai.getParameters();
      break;
    case 'qatar':
      p = CalculationMethod.qatar.getParameters();
      break;
    case 'kuwait':
      p = CalculationMethod.kuwait.getParameters();
      break;
    case 'singapore':
      p = CalculationMethod.singapore.getParameters();
      break;
    case 'north_america':
      p = CalculationMethod.north_america.getParameters();
      break;
    default:
      p = CalculationMethod.umm_al_qura.getParameters();
  }
  p.madhab = madhab == 'hanafi' ? Madhab.hanafi : Madhab.shafi;
  return p;
}

Future<CalculationParameters> loadCalcParams() async {
  final p = await SharedPreferences.getInstance();
  final params = calcParamsFor(
    p.getString('calc_method') ?? 'umm_al_qura',
    p.getString('madhab') ?? 'shafi',
  );
  final fa = p.getDouble('angle_fajr');
  final ia = p.getDouble('angle_isha');
  if (fa != null) params.fajrAngle = fa;
  if (ia != null) {
    params.ishaAngle = ia;
    params.ishaInterval = 0;
  }
  return params;
}
