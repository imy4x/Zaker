import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// 🎨 نظام التصميم المطور والعصري - Theme System v7.0
/// يقدم نظام ثيمات مزدوج متكامل (فاتح وغامق) بتصميم عصري ومتناسق.
class EnhancedAppTheme {
  // --- ☀️ لوحة الألوان للثيم الفاتح ---
  static const _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF007AFF),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF34C759),
    onSecondary: Color(0xFFFFFFFF),
    error: Color(0xFFFF3B30),
    onError: Color(0xFFFFFFFF),
    background: Color(0xFFF2F2F7),
    onBackground: Color(0xFF1D1D1F),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1D1D1F),
    outline: Color(0xFFD1D1D6),
  );

  // --- 🌙 لوحة الألوان للثيم الغامق ---
  static const _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF0A84FF),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF30D158),
    onSecondary: Color(0xFF000000),
    error: Color(0xFFFF453A),
    onError: Color(0xFFFFFFFF),
    background: Color(0xFF000000),
    onBackground: Color(0xFFFFFFFF),
    surface: Color(0xFF1C1C1E),
    onSurface: Color(0xFFFFFFFF),
    outline: Color(0xFF38383A),
  );

  /// 📝 نظام الخطوط (Typography)
  static TextTheme _buildTextTheme(TextTheme base, Color textColor, Color secondaryTextColor) {
    return base.copyWith(
      displayLarge: GoogleFonts.cairo(fontSize: 32, fontWeight: FontWeight.w800, color: textColor),
      displayMedium: GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.w700, color: textColor),
      headlineMedium: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
      bodyLarge: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.w400, color: textColor),
      bodyMedium: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w400, color: secondaryTextColor),
      labelLarge: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600),
    ).apply(displayColor: textColor, bodyColor: secondaryTextColor);
  }

  /// ☀️ الثيم الفاتح - "Serene Focus"
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = _buildTextTheme(base.textTheme, _lightColorScheme.onBackground, _lightColorScheme.onSurface.withOpacity(0.7));
    
    return base.copyWith(
      colorScheme: _lightColorScheme,
      scaffoldBackgroundColor: _lightColorScheme.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: _lightColorScheme.surface,
        foregroundColor: _lightColorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.headlineMedium,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: _lightColorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _lightColorScheme.outline),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightColorScheme.primary,
          foregroundColor: _lightColorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightColorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _lightColorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _lightColorScheme.primary, width: 2),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: _lightColorScheme.onSurface.withOpacity(0.5)),
      ),
    );
  }

  /// 🌙 الثيم الغامق - "Deep Focus"
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = _buildTextTheme(base.textTheme, _darkColorScheme.onBackground, _darkColorScheme.onSurface.withOpacity(0.7));

    return base.copyWith(
      colorScheme: _darkColorScheme,
      scaffoldBackgroundColor: _darkColorScheme.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: _darkColorScheme.background,
        foregroundColor: _darkColorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.headlineMedium,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: _darkColorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _darkColorScheme.outline),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkColorScheme.primary,
          foregroundColor: _darkColorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkColorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _darkColorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _darkColorScheme.primary, width: 2),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: _darkColorScheme.onSurface.withOpacity(0.5)),
      ),
    );
  }
}

