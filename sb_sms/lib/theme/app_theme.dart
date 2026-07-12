import 'package:flutter/material.dart';

abstract final class Spacing {
  static const xxs = 4.0, xs = 8.0, sm = 12.0, md = 16.0, lg = 24.0, xl = 32.0;
}

abstract final class AppTheme {
  static ThemeData get light => _theme(
    Brightness.light,
    const Color(0xff4f46e5), // Indigo 600
    const Color(0xff0ea5e9), // Sky 500
  );
  static ThemeData get dark => _theme(
    Brightness.dark,
    const Color(0xff818cf8), // Indigo 400
    const Color(0xff38bdf8), // Sky 400
  );
  static ThemeData _theme(
    Brightness brightness,
    Color primary,
    Color secondary,
  ) {
    final isDark = brightness == Brightness.dark;
    var scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(primary: primary, secondary: secondary);

    // OLED pure black dark mode
    if (isDark) {
      scheme = scheme.copyWith(
        surface: Colors.black,
        surfaceContainerLowest: Colors.black,
        surfaceContainerLow: Colors.black, // Pure black
        surfaceContainer: Colors.black,
        surfaceContainerHigh: Colors.black,
        surfaceContainerHighest: Colors.black,
        onSurface: Colors.white,
        onSurfaceVariant: Colors.white.withValues(alpha: 0.7),
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surfaceContainerLowest,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? Colors.black : scheme.surface,
        surfaceTintColor: isDark ? Colors.transparent : null,
        foregroundColor: isDark ? Colors.white : scheme.onSurface,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? Colors.black : scheme.primaryContainer,
        foregroundColor: isDark ? Colors.white : scheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isDark
              ? const BorderSide(color: Colors.white54, width: 1)
              : BorderSide.none,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? Colors.black : scheme.surface,
        surfaceTintColor: isDark ? Colors.transparent : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: isDark
              ? const BorderSide(color: Colors.white54, width: 1)
              : BorderSide.none,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: isDark
              ? const BorderSide(color: Colors.white54, width: 1)
              : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white24
                : scheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white : scheme.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.all(Spacing.lg),
      ),
      cardTheme: CardThemeData(
        elevation: 8,
        shadowColor: scheme.shadow.withValues(alpha: 0.08),
        margin: EdgeInsets.zero,
        color: scheme.surface,
        surfaceTintColor: isDark ? Colors.transparent : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: isDark
              ? const BorderSide(color: Colors.white24, width: 1)
              : BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 56),
          backgroundColor: isDark ? Colors.black : scheme.primary,
          foregroundColor: isDark ? Colors.white : scheme.onPrimary,
          disabledBackgroundColor: scheme.surfaceContainerHighest,
          disabledForegroundColor: scheme.onSurfaceVariant,
          elevation: 4,
          shadowColor: isDark
              ? Colors.transparent
              : scheme.primary.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isDark
                ? const BorderSide(color: Colors.white54, width: 1)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
