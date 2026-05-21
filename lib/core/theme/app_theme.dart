import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Core backgrounds
  static const Color bgDeep = Color(0xFF060B18);
  static const Color bgPrimary = Color(0xFF0A0E1A);
  static const Color bgCard = Color(0xFF0F1628);
  static const Color bgCardAlt = Color(0xFF111827);
  static const Color bgSurface = Color(0xFF1A2035);

  // Cyan / Teal — primary action
  static const Color cyanPrimary = Color(0xFF00D4FF);
  static const Color cyanLight = Color(0xFF4DE8FF);
  static const Color cyanDark = Color(0xFF0099CC);
  static const Color cyanGlow = Color(0x4400D4FF);

  // Red — danger / alert
  static const Color dangerRed = Color(0xFFFF3B30);
  static const Color dangerRedLight = Color(0xFFFF6B63);
  static const Color dangerRedGlow = Color(0x55FF3B30);

  // Orange — warning
  static const Color warningOrange = Color(0xFFFF9F0A);
  static const Color warningOrangeGlow = Color(0x55FF9F0A);

  // Green — safe / secure
  static const Color safeGreen = Color(0xFF30D158);
  static const Color safeGreenGlow = Color(0x4430D158);

  // Purple — AI accent
  static const Color aiPurple = Color(0xFF7C3AED);
  static const Color aiPurpleLight = Color(0xFFAB73FA);
  static const Color aiPurpleGlow = Color(0x447C3AED);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BAD3);
  static const Color textMuted = Color(0xFF6B7A99);
  static const Color textDim = Color(0xFF3D4A63);

  // Borders
  static const Color borderPrimary = Color(0xFF1E2D4A);
  static const Color borderCyan = Color(0x3300D4FF);
  static const Color borderRed = Color(0x55FF3B30);

  // Gradients
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF060B18), Color(0xFF0A1128), Color(0xFF060B18)],
  );

  static const LinearGradient cyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00D4FF), Color(0xFF0099CC)],
  );

  static const LinearGradient redGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF3B30), Color(0xFFCC1500)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF141C30), Color(0xFF0F1628)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF060B18), Color(0xFF0A1128), Color(0xFF060B18)],
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgPrimary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.cyanPrimary,
        secondary: AppColors.aiPurple,
        error: AppColors.dangerRed,
        surface: AppColors.bgCard,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: _buildTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderPrimary, width: 1),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgCard,
        selectedItemColor: AppColors.cyanPrimary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderPrimary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderPrimary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.cyanPrimary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cyanPrimary,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.sora(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.sora(
        fontSize: 57, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -1.5,
      ),
      displayMedium: GoogleFonts.sora(
        fontSize: 45, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -1,
      ),
      displaySmall: GoogleFonts.sora(
        fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.5,
      ),
      headlineLarge: GoogleFonts.sora(
        fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
      ),
      headlineMedium: GoogleFonts.sora(
        fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
      ),
      headlineSmall: GoogleFonts.sora(
        fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
      ),
      titleLarge: GoogleFonts.sora(
        fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.sora(
        fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: 0.1,
      ),
      titleSmall: GoogleFonts.sora(
        fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary,
      ),
      bodyLarge: GoogleFonts.sora(
        fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
      ),
      bodyMedium: GoogleFonts.sora(
        fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
      ),
      bodySmall: GoogleFonts.sora(
        fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textMuted,
      ),
      labelLarge: GoogleFonts.sora(
        fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: 0.5,
      ),
      labelMedium: GoogleFonts.sora(
        fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary, letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.sora(
        fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMuted, letterSpacing: 0.8,
      ),
    );
  }
}
