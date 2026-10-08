import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Ilovaning asosiy ranglari. Logo tayyor bo'lgach shu yerda almashtiriladi.
class AppColors {
  static const primary = Color(0xFF6A35FF);
  static const primaryDark = Color(0xFF4E1FE0);
  static const success = Color(0xFF1DB954);
  static const lightBg = Color(0xFFF6F6F9);
  static const lightSurface = Colors.white;
  static const lightMuted = Color(0xFF8A8A99);
  static const darkBg = Color(0xFF111117);
  static const darkSurface = Color(0xFF1C1C24);
}

ThemeData buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: brightness,
    primary: AppColors.primary,
    surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
  );
  final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
  final typography = Typography.material2021(platform: defaultTargetPlatform);
  final text = typography.englishLike
      .merge(isDark ? typography.white : typography.black);
  final fieldFill = isDark ? const Color(0xFF262630) : const Color(0xFFF1F1F5);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge!.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.35),
        disabledForegroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: text.labelLarge!.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  );
}
