import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class ThemeController {
  static final ValueNotifier<ThemeMode> mode =
      ValueNotifier<ThemeMode>(ThemeMode.dark);

  static void _apply(ThemeMode m) {
    kCardBackground = m == ThemeMode.dark ? kCardDark : kCardLight;
    mode.value = m;
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final dark = prefs.getBool('dark_mode') ?? true;
    _apply(dark ? ThemeMode.dark : ThemeMode.light);
  }

  static Future<void> toggle() async {
    final dark = mode.value != ThemeMode.dark;
    _apply(dark ? ThemeMode.dark : ThemeMode.light);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', dark);
  }
}
