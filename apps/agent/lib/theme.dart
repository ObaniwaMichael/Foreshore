import 'package:flutter/material.dart';

ThemeData foreshoreTheme(TextTheme textTheme) {
  const sea = Color(0xFF0B3D4A);
  const foam = Color(0xFFE8F4F2);
  const sand = Color(0xFFF3EDE3);
  const coral = Color(0xFFC45C26);

  final scheme = ColorScheme.fromSeed(
    seedColor: sea,
    primary: sea,
    secondary: coral,
    surface: sand,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: foam,
    textTheme: textTheme.apply(bodyColor: sea, displayColor: sea),
    appBarTheme: AppBarTheme(
      backgroundColor: sea,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: coral,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: sea.withValues(alpha: 0.12),
      labelTextStyle: WidgetStatePropertyAll(
        textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
  );
}
