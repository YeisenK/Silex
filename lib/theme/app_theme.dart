import 'package:flutter/material.dart';

class AppTheme {
  static const Color backgroundPrimary   = Color(0xFF0F1E25);
  static const Color backgroundSecondary = Color(0xFF162B33);
  static const Color surfaceColor        = Color(0xFF1F3A44);
  static const Color accentColor         = Color(0xFF2AABEE);
  static const Color accentGreen         = Color(0xFF00A884);
  static const Color errorColor          = Color(0xFFF15E6C);
  static const Color textPrimary         = Color(0xFFFFFFFF);
  static const Color textSecondary       = Color(0xFF9DB2BD);

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: backgroundPrimary,

      colorScheme: const ColorScheme.dark(
        primary:   accentColor,
        secondary: accentGreen,
        surface:   surfaceColor,
        error:     errorColor,
        onPrimary: textPrimary,
        onSurface: textPrimary,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundSecondary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color:      textPrimary,
          fontSize:   20,
          fontWeight: FontWeight.w600,
          fontFamily: 'GoogleSans',
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor:     backgroundSecondary,
        selectedItemColor:   accentColor,
        unselectedItemColor: textSecondary,
        type:      BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: textPrimary,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:    true,
        fillColor: surfaceColor,
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle:  const TextStyle(color: textSecondary),
        prefixIconColor: textSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(
            fontSize:   16,
            fontWeight: FontWeight.bold,
            fontFamily: 'GoogleSans',
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
        ),
      ),

      snackBarTheme: const SnackBarThemeData(
        backgroundColor: accentColor,
        contentTextStyle: TextStyle(color: textPrimary),
      ),

      dividerColor: surfaceColor,

      textTheme: const TextTheme(
        bodyLarge:   TextStyle(fontFamily: 'GoogleSans', color: textPrimary),
        bodyMedium:  TextStyle(fontFamily: 'GoogleSans', color: textPrimary),
        bodySmall:   TextStyle(fontFamily: 'GoogleSans', color: textSecondary),
        titleLarge:  TextStyle(fontFamily: 'GoogleSans', color: textPrimary,   fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontFamily: 'GoogleSans', color: textPrimary),
        titleSmall:  TextStyle(fontFamily: 'GoogleSans', color: textSecondary),
        labelLarge:  TextStyle(fontFamily: 'GoogleSans', color: textPrimary,   fontWeight: FontWeight.bold),
      ),
    );
  }
}