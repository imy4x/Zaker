import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- الألوان الرئيسية الجديدة والمحسنة ---
  static const Color primaryColor = Color(0xFF007AFF); // أزرق عصري وواضح
  static const Color secondaryColor = Color(0xFF5AC8FA); // سماوي فاتح
  static const Color backgroundColor = Color(0xFFF9F9F9); // خلفية أنظف
  static const Color textColor = Color(0xFF2C2C2E); // أسود ناعم
  static const Color subtitleColor = Color(0xFF8E8E93); // رمادي معتدل

  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    fontFamily: GoogleFonts.cairo().fontFamily, // استخدام خط Cairo
    
    appBarTheme: AppBarTheme(
      backgroundColor: backgroundColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.cairo(
        color: textColor,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: const IconThemeData(color: textColor),
    ),

    textTheme: TextTheme(
      displayLarge: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 28, color: textColor),
      bodyLarge: GoogleFonts.cairo(fontSize: 16, color: textColor, height: 1.7),
      bodyMedium: GoogleFonts.cairo(fontSize: 14, color: subtitleColor, height: 1.6),
      labelLarge: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
    ),

    cardTheme: CardThemeData(
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      color: Colors.white,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        textStyle: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade300,
      ),
    ),
    
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),

    tabBarTheme: TabBarThemeData(
      labelColor: primaryColor,
      unselectedLabelColor: subtitleColor,
      indicatorSize: TabBarIndicatorSize.label,
      indicator: UnderlineTabIndicator(
        borderSide: const BorderSide(color: primaryColor, width: 3),
        borderRadius: BorderRadius.circular(4),
      ),
      labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
      unselectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 16),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: GoogleFonts.cairo(color: subtitleColor),
    ),
  );
}
