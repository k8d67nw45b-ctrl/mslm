import 'package:flutter/material.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData get darkTheme => _build(
        Brightness.dark,
        kDarkBackground,
        Colors.white,
        Colors.white70,
      );

  static ThemeData get lightTheme => _build(
        Brightness.light,
        kLightBackground,
        Colors.black87,
        Colors.black54,
      );

  static ThemeData _build(
    Brightness b,
    Color bg,
    Color main,
    Color soft,
  ) {
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      scaffoldBackgroundColor: bg,
      primaryColor: kGreen,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kGreen,
        brightness: b,
      ).copyWith(primary: kGreen, surface: kCardBackground),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: main,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: main,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: main),
        bodyMedium: TextStyle(color: soft),
        titleLarge: TextStyle(
          color: main,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kBorderRadiusSmall),
          ),
        ),
      ),
    );
  }
}
