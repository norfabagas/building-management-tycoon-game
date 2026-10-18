import 'package:flutter/material.dart';

abstract final class GameColors {
  static const canvas = Color(0xFFF5F3EB);
  static const surface = Color(0xFFFFFCF1);
  static const ink = Color(0xFF203B3A);
  static const muted = Color(0xFF66766D);
  static const border = Color(0xFFCAD2C6);
  static const primary = Color(0xFF237563);
  static const pressed = Color(0xFF185343);
  static const mint = Color(0xFFDBEBDD);
  static const land = Color(0xFFBBD995);
  static const apartment = Color(0xFFE9B754);
  static const hotel = Color(0xFFE98D70);
  static const office = Color(0xFF65B1C5);
  static const danger = Color(0xFFAF443F);
}

ThemeData buildGameTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: GameColors.primary).copyWith(
    primary: GameColors.primary,
    onPrimary: GameColors.surface,
    surface: GameColors.surface,
    onSurface: GameColors.ink,
    error: GameColors.danger,
    outline: GameColors.border,
  );
  return ThemeData(
    colorScheme: scheme,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    scaffoldBackgroundColor: GameColors.canvas,
    fontFamily: 'Trebuchet MS',
    fontFamilyFallback: const ['Roboto', 'NotoSansThai', 'sans-serif'],
    iconButtonTheme: const IconButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(48, 48)),
        visualDensity: VisualDensity.standard,
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: GameColors.canvas,
      foregroundColor: GameColors.ink,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: GameColors.border, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: GameColors.primary, width: 3),
      ),
    ),
  );
}
