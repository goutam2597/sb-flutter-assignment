import 'package:flutter/material.dart';

abstract final class Spacing {
  static const xxs = 4.0, xs = 8.0, sm = 12.0, md = 16.0, lg = 24.0, xl = 32.0;
}

abstract final class AppTheme {
  static ThemeData get light => _theme(
    Brightness.light,
    const Color(0xff4055a8),
    const Color(0xff00796f),
  );
  static ThemeData get dark =>
      _theme(Brightness.dark, const Color(0xffb9c3ff), const Color(0xff73d6c8));
  static ThemeData _theme(
    Brightness brightness,
    Color primary,
    Color secondary,
  ) {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(primary: primary, secondary: secondary);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surfaceContainerLowest,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.all(Spacing.md),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.surfaceContainerHighest,
          disabledForegroundColor: scheme.onSurfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
