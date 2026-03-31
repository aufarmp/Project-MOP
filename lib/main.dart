// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'views/nav.dart';
import 'utils/theme.dart';

// 1. STATE GLOBAL: Menyimpan status tema saat ini (Default: Gelap)
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. ValueListenableBuilder akan me-rebuild aplikasi ketika themeNotifier berubah
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'Comi.id',
          debugShowCheckedModeBanner: false,
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {
              PointerDeviceKind.mouse,
              PointerDeviceKind.touch,
              PointerDeviceKind.stylus,
            },
          ),
          
          // 3. TERAPKAN TEMA DI SINI
          themeMode: currentMode, // Akan membaca Light / Dark dari tombol
          theme: AppTheme.lightTheme.copyWith(
            textTheme: GoogleFonts.beVietnamProTextTheme(ThemeData.light().textTheme),
          ),
          darkTheme: AppTheme.darkTheme.copyWith(
            textTheme: GoogleFonts.beVietnamProTextTheme(ThemeData.dark().textTheme).apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
          ),
          
          home: const Nav(), 
        );
      }
    );
  }
}