import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'widgets/admin_ui.dart';

ThemeData adminTheme([TextTheme? base]) {
  final textTheme = base ?? GoogleFonts.dmSansTextTheme();

  final scheme = ColorScheme.fromSeed(
    seedColor: AdminTokens.sea,
    primary: AdminTokens.sea,
    secondary: AdminTokens.coral,
    surface: Colors.white,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AdminTokens.mist,
    textTheme: textTheme.apply(
      bodyColor: AdminTokens.sea,
      displayColor: AdminTokens.sea,
    ),
    dividerColor: AdminTokens.line,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AdminTokens.sea,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: AdminTokens.sea,
        fontWeight: FontWeight.w800,
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.white,
      selectedIconTheme: const IconThemeData(color: AdminTokens.sea),
      unselectedIconTheme: IconThemeData(color: AdminTokens.sea.withValues(alpha: 0.45)),
      selectedLabelTextStyle: textTheme.labelLarge?.copyWith(
        color: AdminTokens.sea,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: textTheme.labelLarge?.copyWith(
        color: AdminTokens.inkMuted,
      ),
      indicatorColor: AdminTokens.seaSoft,
      minWidth: 72,
      minExtendedWidth: 200,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AdminTokens.sea,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AdminTokens.sea,
        side: const BorderSide(color: AdminTokens.line),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AdminTokens.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AdminTokens.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AdminTokens.sea, width: 1.4),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AdminTokens.seaDeep,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
