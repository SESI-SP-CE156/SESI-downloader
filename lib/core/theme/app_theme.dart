import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class AppTheme {
  static const primaryColor = Color(0xFFDA251D); // Vermelho SESI
  static const backgroundColor = Color(0xFFF3F3F3); // Cinza Microsoft/Fluent
  static const surfaceColor = Colors.white;
  static const borderColor = Color(0xFFE0E0E0); // Bordas sutis
  static const textColor = Color(0xFF242424);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      visualDensity: VisualDensity.compact,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        surface: surfaceColor,
        onSurface: textColor,
        surfaceContainerLow: backgroundColor,
        outline: borderColor,
      ),
      scaffoldBackgroundColor: backgroundColor,

      // Typography
      textTheme: GoogleFonts.openSansTextTheme().copyWith(
        displayLarge: TextStyle(
          fontSize: 24.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        bodyLarge: TextStyle(fontSize: 12.sp, color: const Color(0xFF424242)),
        bodyMedium: TextStyle(fontSize: 11.sp, color: const Color(0xFF424242)),
        labelLarge: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: surfaceColor,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: borderColor, width: 1),
        ),
        margin: EdgeInsets.all(4.sp),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12.sp,
          vertical: 14.sp,
        ),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: GoogleFonts.openSans(
          color: Colors.grey[700],
          fontSize: 11.sp,
        ),
        floatingLabelStyle: GoogleFonts.openSans(
          color: primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 14.sp),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: GoogleFonts.openSans(fontWeight: FontWeight.w600),
        ),
      ),

      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: borderColor),
        ),
        titleTextStyle: GoogleFonts.openSans(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
