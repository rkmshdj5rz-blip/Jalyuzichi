import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Ilovaning asosiy ranglari. Logo tayyor bo'lgach shu yerda almashtiriladi.
class AppColors {
  /// Brend rangi: tugmalar, logo va katta yuzalar uchun.
  static const brand = Color(0xFFC8F31D);
  static const brandLight = Color(0xFFE2FF6B);
  static const brandDark = Color(0xFF8DC000);

  /// Brend rangi ustidagi matn va belgilar rangi.
  static const onBrand = Color(0xFF15171E);

  /// Oq fonda o'qiladigan brend rangi (matn va belgilar uchun).
  static const accent = Color(0xFF4D7300);
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
    seedColor: AppColors.brand,
    brightness: brightness,
    primary: isDark ? AppColors.brand : AppColors.accent,
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
        borderSide: BorderSide(
            color: isDark ? AppColors.brand : AppColors.accent, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brand,
        foregroundColor: AppColors.onBrand,
        disabledBackgroundColor: AppColors.brand.withValues(alpha: 0.35),
        disabledForegroundColor: AppColors.onBrand.withValues(alpha: 0.7),
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
