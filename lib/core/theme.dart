import 'package:flutter/material.dart';

/// Paleta inspirada en los colores de la Universidad Anáhuac
/// (naranja = sol, café = tierra). Los valores son aproximados.
class AppColors {
  AppColors._();

  static const orange = Color(0xFFF47B20);
  static const brown = Color(0xFF4E2E1B);
  static const cream = Color(0xFFFFF6EE);

  static const free = Color(0xFF2E9E5B);
  static const occupied = Color(0xFFD64545);
  static const reserved = Color(0xFFF2B01E);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.orange,
    primary: AppColors.orange,
    secondary: AppColors.brown,
    surface: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.cream,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.brown,
      foregroundColor: Colors.white,
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
        foregroundColor: AppColors.brown,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: AppColors.brown),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
