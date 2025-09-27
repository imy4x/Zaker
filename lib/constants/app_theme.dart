import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Vibrant Modern Color Palette - حيوي وجذاب مع تحسين التباين
  static const Color primaryColor = Color(0xFF5A4FCF); // Darker vibrant purple for better contrast
  static const Color primaryLight = Color(0xFF7B6EE6); // Slightly darker light purple
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color secondaryColor = Color(0xFF059669); // Darker turquoise for better contrast
  static const Color accentColor = Color(0xFFDC2626); // Darker coral red
  static const Color accentSecondary = Color(0xFFD97706); // Darker golden yellow
  static const Color backgroundColor = Color(0xFFF8F9FF); // Light lavender background
  static const Color surfaceColor = Color(0xFFFFFFFF); // Pure white
  static const Color surfaceVariant = Color(0xFFE5E7EB); // Better contrast surface variant
  static const Color textColor = Color(0xFF1F2937); // Darker text for better contrast
  static const Color subtitleColor = Color(0xFF4B5563); // Darker subtitle for better contrast
  static const Color borderColor = Color(0xFFD1D5DB); // Better contrast border
  static const Color errorColor = Color(0xFFDC2626);
  static const Color warningColor = Color(0xFFD97706);
  static const Color successColor = Color(0xFF059669);
  
  // Gradient colors for modern effects
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryColor, Color(0xFF74B9FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentColor, accentSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      background: backgroundColor,
      error: errorColor,
    ),
    scaffoldBackgroundColor: backgroundColor,
    fontFamily: GoogleFonts.cairo().fontFamily, // Cairo font for better Arabic support
    
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceColor,
      elevation: 0,
      centerTitle: true,
      shadowColor: Colors.black.withOpacity(0.05),
      surfaceTintColor: surfaceColor,
      titleTextStyle: GoogleFonts.cairo(
        color: textColor,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: textColor, size: 22),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    ),

    textTheme: TextTheme(
      displayLarge: GoogleFonts.cairo(
        fontWeight: FontWeight.bold,
        fontSize: 32,
        color: textColor,
        height: 1.3,
      ),
      displayMedium: GoogleFonts.cairo(
        fontWeight: FontWeight.bold,
        fontSize: 24,
        color: textColor,
        height: 1.4,
      ),
      headlineLarge: GoogleFonts.cairo(
        fontWeight: FontWeight.bold,
        fontSize: 20,
        color: textColor,
        height: 1.4,
      ),
      bodyLarge: GoogleFonts.cairo(
        fontSize: 17,
        color: textColor,
        height: 1.7,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: GoogleFonts.cairo(
        fontSize: 15,
        color: subtitleColor,
        height: 1.6,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 1),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      color: surfaceColor,
      surfaceTintColor: surfaceColor,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        shadowColor: Colors.transparent,
        textStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: subtitleColor.withOpacity(0.3),
        minimumSize: const Size(88, 48),
      ),
    ),
    
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        minimumSize: const Size(88, 48),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: primaryColor, width: 1.5),
        textStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        foregroundColor: primaryColor,
        minimumSize: const Size(88, 48),
      ),
    ),
    
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      extendedPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      extendedTextStyle: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    ),

    tabBarTheme: TabBarThemeData(
      labelColor: primaryColor,
      unselectedLabelColor: subtitleColor,
      indicatorSize: TabBarIndicatorSize.label,
      indicator: UnderlineTabIndicator(
        borderSide: const BorderSide(color: primaryColor, width: 2.5),
        borderRadius: BorderRadius.circular(2),
      ),
      labelStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 15,
        letterSpacing: 0.1,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        fontSize: 15,
        letterSpacing: 0.1,
      ),
      overlayColor: MaterialStateProperty.all(
        primaryColor.withOpacity(0.1),
      ),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: backgroundColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: errorColor, width: 2),
      ),
      labelStyle: GoogleFonts.inter(
        color: subtitleColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: GoogleFonts.inter(
        color: subtitleColor.withOpacity(0.7),
        fontSize: 14,
      ),
    ),
    
    chipTheme: ChipThemeData(
      backgroundColor: backgroundColor,
      selectedColor: primaryColor.withOpacity(0.1),
      disabledColor: subtitleColor.withOpacity(0.1),
      side: BorderSide(color: borderColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      labelStyle: GoogleFonts.cairo(
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    
    // Remove horizontal line from ExpansionTile
    expansionTileTheme: const ExpansionTileThemeData(
      tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      childrenPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      collapsedShape: RoundedRectangleBorder(),
      shape: RoundedRectangleBorder(),
    ),
    
    dividerTheme: const DividerThemeData(
      color: Colors.transparent,
      thickness: 0,
      space: 0,
    ),
  );
}
