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
  static const lightBg = Color(0xFFF3F4F7);
  static const lightSurface = Colors.white;
  static const lightMuted = Color(0xFF6B6D7A);
  static const darkBg = Color(0xFF111117);
  static const darkSurface = Color(0xFF1C1C24);

  /// Asosiy matn rangi (to'q, tiniq).
  static const ink = Color(0xFF14161C);

  /// Karta va maydonlarning ingichka chegarasi.
  static const lightLine = Color(0xFFE3E5EB);
  static const darkLine = Color(0xFF2E2E3A);
}

/// Ilova shrifti (assets/fonts ichida, internetsiz ishlaydi).
const appFont = 'Inter';

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
  final ink = isDark ? const Color(0xFFF2F2F5) : AppColors.ink;
  final text = typography.englishLike
      .merge(isDark ? typography.white : typography.black)
      .apply(fontFamily: appFont, bodyColor: ink, displayColor: ink);
  final fieldFill = isDark ? const Color(0xFF262630) : const Color(0xFFF3F4F7);
  final line = isDark ? AppColors.darkLine : AppColors.lightLine;
  final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

  return ThemeData(
    useMaterial3: true,
    fontFamily: appFont,
    textTheme: text,
    colorScheme: scheme.copyWith(
      onSurface: ink,
      onSurfaceVariant: isDark ? const Color(0xFFA9A9B6) : AppColors.lightMuted,
      outlineVariant: line,
      surfaceTint: Colors.transparent,
    ),
    dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
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
        borderSide: BorderSide(color: line),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: line.withValues(alpha: 0.5)),
      ),
      hintStyle: TextStyle(
          color: isDark ? const Color(0xFF8C8C99) : const Color(0xFF8A8C98)),
      labelStyle: const TextStyle(fontWeight: FontWeight.w500),
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
        disabledBackgroundColor:
            isDark ? const Color(0xFF2A2A34) : const Color(0xFFE6E7EC),
        disabledForegroundColor:
            isDark ? const Color(0xFF8C8C99) : AppColors.lightMuted,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: text.labelLarge!.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: line),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        side: BorderSide(color: isDark ? const Color(0xFF3A3A46) : const Color(0xFFD5D7DF)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
            fontFamily: appFont, fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.brand,
      elevation: 0,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontFamily: appFont,
            fontSize: 12,
            fontWeight:
                s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? ink : AppColors.lightMuted,
          )),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected)
                ? AppColors.onBrand
                : AppColors.lightMuted,
          )),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: line,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
    ),
    chipTheme: ChipThemeData(
      side: BorderSide(color: line),
      labelStyle: TextStyle(fontFamily: appFont, color: ink),
    ),
  );
}
