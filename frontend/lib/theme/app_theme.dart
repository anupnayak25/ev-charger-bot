import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() => _themeFrom(_lightScheme);

  static ThemeData dark() => _themeFrom(_darkScheme);

  static ThemeData _themeFrom(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: scheme.surface,
      ),
      iconTheme: IconThemeData(color: scheme.onSurface),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        contentTextStyle: TextStyle(color: scheme.onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: const OutlineInputBorder(),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    );
  }

  static final ColorScheme _lightScheme =
      ColorScheme.fromSeed(
        seedColor: Colors.grey,
        brightness: Brightness.light,
        surface: Colors.white,
      ).copyWith(
        primary: Colors.black,
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFEAEAEA),
        onPrimaryContainer: Colors.black,
        secondary: Colors.black,
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFFF2F2F2),
        onSecondaryContainer: Colors.black,
        surface: Colors.white,
        onSurface: Colors.black,
        surfaceContainerHighest: const Color(0xFFF5F5F5),
        onSurfaceVariant: const Color(0xFF3A3A3A),
        outline: const Color(0xFFB8B8B8),
        outlineVariant: const Color(0xFFE0E0E0),
      );

  static final ColorScheme _darkScheme =
      ColorScheme.fromSeed(
        seedColor: Colors.grey,
        brightness: Brightness.dark,
        surface: Colors.black,
      ).copyWith(
        primary: Colors.white,
        onPrimary: Colors.black,
        primaryContainer: const Color(0xFF1E1E1E),
        onPrimaryContainer: Colors.white,
        secondary: Colors.white,
        onSecondary: Colors.black,
        secondaryContainer: const Color(0xFF232323),
        onSecondaryContainer: Colors.white,
        surface: Colors.black,
        onSurface: Colors.white,
        surfaceContainerHighest: const Color(0xFF161616),
        onSurfaceVariant: const Color(0xFFDDDDDD),
        outline: const Color(0xFF505050),
        outlineVariant: const Color(0xFF2A2A2A),
      );
}
