import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// 🎨 نظام تصميم "سكينة" - Serenity Design System v24.0
/// تصميم مُحسَّن بحدود أغمق لزيادة الوضوح والتباين
class EnhancedAppTheme {
  // --- 🍃 لوحة ألوان الوضع الفاتح - "نسيم الصباح" ---
  static const _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF0D9488), // أخضر-أزرق هادئ (Teal)
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFCCFBF1),
    onPrimaryContainer: Color(0xFF042F2E),
    secondary: Color(0xFFF59E0B), // كهرماني دافئ (Amber)
    onSecondary: Colors.black,
    secondaryContainer: Color(0xFFFEF3C7),
    onSecondaryContainer: Color(0xFF78350F),
    tertiary: Color(0xFF0EA5E9), // أزرق سماوي
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFE0F2FE),
    onTertiaryContainer: Color(0xFF0C4A6E),
    error: Color(0xFFDC2626), // أحمر عصري
    onError: Colors.white,
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF991B1B),
    surface: Color(0xFFF8FAFC), // أبيض-رمادي فاتح جدًا للخلفية
    onSurface: Color(0xFF1E293B), // أزرق داكن للنصوص (Slate)
    surfaceContainerHighest: Colors.white, // أبيض نقي للبطاقات
    onSurfaceVariant: Color(0xFF64748B), // رمادي معتدل
    // **تعديل: تم جعل الحدود أغمق لزيادة الوضوح**
    outline: Color(0xFF94A3B8), // حدود أغمق
    outlineVariant: Color(0xFFCBD5E1), // حدود أغمق قليلاً
    shadow: Color(0xFF64748B),
    scrim: Colors.black,
    inverseSurface: Color(0xFF1E293B),
    onInverseSurface: Color(0xFFF8FAFC),
    inversePrimary: Color(0xFF2DD4BF),
  );

  // --- 🌙 لوحة ألوان الوضع الداكن - "سكون الليل" ---
  static const _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF2DD4BF), // أخضر-أزرق ساطع
    onPrimary: Color(0xFF042F2E),
    primaryContainer: Color(0xFF0F766E),
    onPrimaryContainer: Color(0xFF99F6E4),
    secondary: Color(0xFFFBBF24), // كهرماني فاتح
    onSecondary: Color(0xFF422006),
    secondaryContainer: Color(0xFF78350F),
    onSecondaryContainer: Color(0xFFFEF3C7),
    tertiary: Color(0xFF38BDF8), // أزرق سماوي ناعم
    onTertiary: Color(0xFF0C4A6E),
    tertiaryContainer: Color(0xFF075985),
    onTertiaryContainer: Color(0xFFE0F2FE),
    error: Color(0xFFF87171), // أحمر ناعم
    onError: Color(0xFF7F1D1D),
    errorContainer: Color(0xFF991B1B),
    onErrorContainer: Color(0xFFFEE2E2),
    surface: Color(0xFF020617), // أزرق ليلي داكن جدًا للخلفية
    onSurface: Color(0xFFE2E8F0), // أبيض مائل للزرقة للنصوص
    surfaceContainerHighest: Color(0xFF1E293B), // أزرق داكن للبطاقات
    onSurfaceVariant: Color(0xFF94A3B8), // رمادي فاتح
    // **تعديل: تم جعل الحدود أغمق لزيادة الوضوح**
    outline: Color(0xFF475569),
    outlineVariant: Color(0xFF334155),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFFE2E8F0),
    onInverseSurface: Color(0xFF1E293B),
    inversePrimary: Color(0xFF0D9488),
  );

  static TextTheme _buildTextTheme(TextTheme base, Color textColor, Color secondaryTextColor) {
    return base.copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 32, 
        fontWeight: FontWeight.w800, 
        color: textColor, 
        letterSpacing: -1.2,
        height: 1.2,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 28, 
        fontWeight: FontWeight.w700, 
        color: textColor, 
        letterSpacing: -0.8,
        height: 1.3,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 24, 
        fontWeight: FontWeight.w700, 
        color: textColor, 
        letterSpacing: -0.5,
        height: 1.3,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20, 
        fontWeight: FontWeight.w600, 
        color: textColor, 
        letterSpacing: -0.3,
        height: 1.4,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 18, 
        fontWeight: FontWeight.w600, 
        color: textColor,
        height: 1.4,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18, 
        fontWeight: FontWeight.w600, 
        color: textColor,
        height: 1.4,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16, 
        fontWeight: FontWeight.w600, 
        color: textColor,
        height: 1.4,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14, 
        fontWeight: FontWeight.w600, 
        color: textColor,
        height: 1.4,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16, 
        fontWeight: FontWeight.w400, 
        color: textColor, 
        height: 1.6,
        letterSpacing: 0.1,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14, 
        fontWeight: FontWeight.w400, 
        color: secondaryTextColor, 
        height: 1.5,
        letterSpacing: 0.1,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12, 
        fontWeight: FontWeight.w400, 
        color: secondaryTextColor,
        height: 1.4,
        letterSpacing: 0.2,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 15, 
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.3,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 13, 
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.3,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11, 
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        height: 1.2,
      ),
    ).apply(displayColor: textColor, bodyColor: secondaryTextColor);
  }

  static ThemeData _buildThemeData(ColorScheme colorScheme, TextTheme textTheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: 24,
        ),
        systemOverlayStyle: colorScheme.brightness == Brightness.light
            ? SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                statusBarBrightness: Brightness.light,
              )
            : SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                statusBarBrightness: Brightness.dark,
              ),
      ),
      
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerHighest,
        elevation: 8,
        shadowColor: colorScheme.shadow.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          // **تعديل: استخدام الحدود الأغمق للبطاقات**
          side: BorderSide(
            color: colorScheme.outline,
            width: 1.5,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shadowColor: colorScheme.primary.withOpacity(0.3),
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          minimumSize: const Size(140, 56),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            fontSize: 16,
          ),
        ).copyWith(
          // تعديل لون الزر عند تعطيله ليكون أوضح
          backgroundColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.disabled)) {
                return colorScheme.onSurface.withOpacity(0.12);
              }
              return colorScheme.primary;
            },
          ),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.disabled)) {
                return colorScheme.onSurface.withOpacity(0.38);
              }
              return colorScheme.onPrimary;
            },
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(
            color: colorScheme.outline,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          minimumSize: const Size(120, 48),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ).copyWith(
          foregroundColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.disabled)) {
                return colorScheme.onSurface.withOpacity(0.38);
              }
              return colorScheme.primary;
            },
          ),
          side: WidgetStateProperty.resolveWith<BorderSide?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.disabled)) {
                return BorderSide(
                  color: colorScheme.onSurface.withOpacity(0.12),
                  width: 1.5,
                );
              }
              return BorderSide(
                color: colorScheme.outline,
                width: 1.5,
              );
            },
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        hintStyle: textTheme.bodyMedium,
      ),
      
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: colorScheme.primary.withOpacity(0.1),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: textTheme.labelLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: textTheme.labelMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodyMedium,
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
      ),
      
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.onPrimary;
            }
            return colorScheme.outline;
          },
        ),
        trackColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.primary;
            }
            return colorScheme.surfaceContainerHighest;
          },
        ),
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.surfaceContainerHighest,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withOpacity(0.12),
      ),
      
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),
    );
  }

  static ThemeData get lightTheme {
    final textTheme = _buildTextTheme(
      ThemeData.light().textTheme, 
      _lightColorScheme.onSurface, 
      _lightColorScheme.onSurfaceVariant,
    );
    return _buildThemeData(_lightColorScheme, textTheme);
  }

  static ThemeData get darkTheme {
    final textTheme = _buildTextTheme(
      ThemeData.dark().textTheme, 
      _darkColorScheme.onSurface, 
      _darkColorScheme.onSurfaceVariant,
    );
    return _buildThemeData(_darkColorScheme, textTheme);
  }
}

