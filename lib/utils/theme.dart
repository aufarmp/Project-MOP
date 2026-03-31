// lib/utils/theme.dart
import 'package:flutter/material.dart';

class AppColors {
  // Warna Utama dari Tailwind Config Anda
  static const Color primary = Color(0xFF256AF4);
  static const Color primaryHover = Color(0xFF1D54C4);
  static const Color accentPurple = Color(0xFFA855F7);
  
  // Warna Background
  static const Color backgroundDark = Color(0xFF16263B);
  static const Color backgroundCard = Color(0xFF1E324F);
  
  // Warna Teks
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8);
}

class AppTheme {
  // --- KONFIGURASI LIGHT MODE ---
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF3F4F6), // Warna abu-abu sangat terang
    cardColor: const Color(0xFFFFFFFF), // Putih bersih untuk Card/AppBar
    primaryColor: AppColors.primary,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      surface: Color(0xFFFFFFFF),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFFFFF),
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF1E293B)), // Ikon warna gelap
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFFFFFFF),
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Color(0xFF94A3B8),
    ),
  );

  // --- KONFIGURASI DARK MODE ---
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    cardColor: AppColors.backgroundCard,
    primaryColor: AppColors.primary,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      surface: AppColors.backgroundCard,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundCard,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.backgroundCard,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
    ),
  );
}