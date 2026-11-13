import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppRadius {
  AppRadius._();
  static const double card = 24.0;
  static const double button = 16.0;
  static const double pill = 999.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 8.0;
  static const double sm = 16.0;
  static const double md = 24.0;
  static const double lg = 32.0;
  static const double xl = 40.0;
}

class AppColors {
  AppColors._();

  // Primary brand token (Monochrome Luxury: Crisp White in Dark, Pitch Jet Black in Light)
  static const Color primary = Color(0xFF0F172A);
  static const Color primaryLight = Color(0xFF0F172A);
  static const Color primaryDark = Color(0xFFFFFFFF);

  // Income / Uang Masuk (#34D399 - Emerald lembut)
  static const Color incomeLight = Color(0xFF059669);
  static const Color incomeDark = Color(0xFF34D399);

  // Expense / Uang Keluar (#F87171 - Rose lembut)
  static const Color expenseLight = Color(0xFFDC2626);
  static const Color expenseDark = Color(0xFFF87171);

  // Saving & Investment (Monochrome)
  static const Color savingLight = Color(0xFF0F172A);
  static const Color savingDark = Color(0xFFFFFFFF);
  static const Color investmentLight = Color(0xFF334155);
  static const Color investmentDark = Color(0xFFE2E8F0);

  // Background (#0A0D14 obsidian navy & #F8FAFC)
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0A0D14);

  // Surface & Kartu (#131826 & #1B2236)
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF131826);
  static const Color surfaceHigh = Color(0xFF1B2236);

  // Text on accent
  static const Color onAccent = Color(0xFF0A0D14);

  // Notes styling (monochrome glass)
  static const Color noteYellow = Color(0xFFE2E8F0);
  static const Color noteInk = Color(0xFF0F172A);

  // Glass & Subtle Card Fills (Balanced luxury glass opacity ~75%)
  static const Color glassFillLight = Color(0xD0FFFFFF);
  static const Color glassFillDark = Color(0xB8131826);

  static const Color glassCardLight = Color(0xDCFFFFFF);
  static const Color glassCardDark = Color(0xC4131826);

  // Borders
  static const Color glassBorderLight = Color(0x40E2E8F0);
  static const Color glassBorderDark = Color(0x24FFFFFF);
  static const Color cardBorder = Color(0x1FFFFFFF);

  // Ambient Blobs (Monochrome Glow - NO PURPLE)
  static const Color blobPrimaryLight = Color(0x0E0F172A);
  static const Color blobSecondaryLight = Color(0x0C34D399);
  static const Color blobAccentLight = Color(0x0CF87171);

  static const Color blobPrimaryDark = Color(0x14FFFFFF);
  static const Color blobSecondaryDark = Color(0x1034D399);
  static const Color blobAccentDark = Color(0x10F87171);

  // Typography tokens
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF94A3B8);

  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // UI Accents
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFFBBF24);

  static const Color secondaryLight = savingLight;
  static const Color secondaryDark = savingDark;

  // Context-aware helpers
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color income(BuildContext context) =>
      isDark(context) ? incomeDark : incomeLight;

  static Color expense(BuildContext context) =>
      isDark(context) ? expenseDark : expenseLight;

  static Color saving(BuildContext context) =>
      isDark(context) ? savingDark : savingLight;

  static Color investment(BuildContext context) =>
      isDark(context) ? investmentDark : investmentLight;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? textPrimaryDark : textPrimaryLight;

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? textSecondaryDark : textSecondaryLight;

  static Color glassFill(BuildContext context) =>
      isDark(context) ? glassFillDark : glassFillLight;

  static Color glassCard(BuildContext context) =>
      isDark(context) ? glassCardDark : glassCardLight;

  static Color glassBorder(BuildContext context) =>
      isDark(context) ? glassBorderDark : glassBorderLight;

  // Backward compatibility alias used in older widgets
  static const Color success = incomeDark;
  static const Color error = expenseDark;
  static const Color background = backgroundDark;
  static const Color surface = surfaceDark;
  static const Color border = Color(0xFF232A3D);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final baseText = GoogleFonts.interTextTheme(ThemeData.light().textTheme);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0F172A),
        brightness: Brightness.light,
        primary: const Color(0xFF0F172A),
        surface: AppColors.surfaceLight,
        error: AppColors.expenseLight,
      ),
      textTheme: baseText.copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimaryLight,
          letterSpacing: -1.0,
        ),
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimaryLight,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryLight,
          letterSpacing: -0.4,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryLight,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryLight,
          letterSpacing: -0.2,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
        ),
        bodyLarge: baseText.bodyLarge?.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        bodyMedium: baseText.bodyMedium?.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        bodySmall: baseText.bodySmall?.copyWith(
          color: AppColors.textSecondaryLight,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimaryLight,
          letterSpacing: -0.3,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceLight.withValues(alpha: 0.95),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.glassBorderLight, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.glassBorderLight, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: Color(0xFF0F172A), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.expenseLight, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondaryLight),
        hintStyle: const TextStyle(color: AppColors.textMutedLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: const Color(0x33000000),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0F172A),
          side: const BorderSide(color: Color(0x4D0F172A), width: 1.5),
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: const Color(0x180F172A),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF0F172A) : AppColors.textSecondaryLight,
          );
        }),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF0F172A);
            }
            return Colors.white.withValues(alpha: 0.6);
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return AppColors.textSecondaryLight;
          }),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.glassBorderLight, width: 1.2),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimaryLight.withValues(alpha: 0.92),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
      ),
    );
  }

  static ThemeData get dark {
    final baseText = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.white,
        brightness: Brightness.dark,
        primary: Colors.white,
        surface: AppColors.surfaceDark,
        error: AppColors.expenseDark,
      ),
      textTheme: baseText.copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimaryDark,
          letterSpacing: -1.0,
        ),
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimaryDark,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryDark,
          letterSpacing: -0.4,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryDark,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryDark,
          letterSpacing: -0.2,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
        bodyLarge: baseText.bodyLarge?.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        bodyMedium: baseText.bodyMedium?.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        bodySmall: baseText.bodySmall?.copyWith(
          color: AppColors.textSecondaryDark,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimaryDark,
          letterSpacing: -0.3,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.cardBorder, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.cardBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.expenseDark, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
        hintStyle: const TextStyle(color: AppColors.textMutedDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0A0D14),
          elevation: 0,
          shadowColor: const Color(0x33000000),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Color(0x66FFFFFF), width: 1.5),
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: const Color(0x28FFFFFF),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondaryDark,
          );
        }),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return AppColors.surfaceHigh;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF0A0D14);
            }
            return AppColors.textSecondaryDark;
          }),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.glassBorderDark, width: 1.2),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
      ),
    );
  }
}
