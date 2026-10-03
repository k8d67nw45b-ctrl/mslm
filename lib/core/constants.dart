import 'package:flutter/material.dart';

const String appName = 'رفيق المسلم';

// الألوان
const Color kGreen = Color(0xFF10B981);
const Color kLightBackground = Color(0xFFF3F4F6);
const Color kCardLight = Color(0xFFFFFFFF);

// الأسود الحقيقي (AMOLED)
bool kAmoled = false;
Color get kDarkBackground =>
    kAmoled ? const Color(0xFF000000) : const Color(0xFF0F1419);
Color get kCardDark =>
    kAmoled ? const Color(0xFF0E0E0E) : const Color(0xFF1A2325);

// لون البطاقات يتغير حسب الوضع
Color kCardBackground = kCardDark;

// المسافات
const double kPaddingSmall = 8.0;
const double kPaddingMedium = 16.0;
const double kPaddingLarge = 24.0;

// استدارة الحواف
const double kBorderRadiusSmall = 8.0;
const double kBorderRadiusMedium = 12.0;
const double kBorderRadiusLarge = 16.0;
