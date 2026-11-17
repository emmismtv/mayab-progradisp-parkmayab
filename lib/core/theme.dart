import 'package:flutter/material.dart';

/// Paleta institucional de la Universidad Anáhuac:
/// naranja #EC652B y arena #D6B7A0.
class AppColors {
  AppColors._();

  static const orange = Color(0xFFEC652B);
  static const tan = Color(0xFFD6B7A0);
  static const ink = Color(0xFF262626); // texto/íconos sobre arena
  static const cream = Color(0xFFFBF5F0);

  static const free = Color(0xFF2E9E5B);
  static const occupied = Color(0xFFD64545);
  static const reserved = Color(0xFFF2B01E);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.orange,
    primary: AppColors.orange,
    secondary: AppColors.tan,
    surface: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.cream,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.tan,
      foregroundColor: AppColors.ink,
      centerTitle: true,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: AppColors.ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
