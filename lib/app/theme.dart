import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Polished, vibrant palette: deep map blacks with coral, rose, sage, and oat accents.
class KuglaColors {
  static const deepSpace = Color(0xFF0E0D0B);
  static const midnight = Color(0xFF181614);
  static const panel = Color(0xFF23211E);
  static const panelRaised = Color(0xFF2D2A26);

  /// Primary signal (historically named `cyan`); warm oat accent used across Atlas surfaces.
  static const cyan = Color(0xFFD4B896);
  static const cyanSoft = Color(0xFFE8D4B8);

  static const amber = Color(0xFFFF6B57);
  static const rose = Color(0xFFC97D6B);
  static const lilac = Color(0xFF9A8FB0);

  static const success = Color(0xFF7CAA8E);

  static const text = Color(0xFFF2EBE3);
  static const textMuted = Color(0xFF9B968C);

  /// Faint warm rules, like printed grid lines.
  static const stroke = Color(0x4DD4B896);
}

TextStyle? _withTextColor(TextStyle? style) =>
    style?.copyWith(color: KuglaColors.text);

/// Narrow display (Barlow Condensed) for display / headline / title; humanist
/// body (Source Sans 3) for body and labels.
TextTheme _kuglaTextTheme(TextTheme base) {
  final humanist = GoogleFonts.sourceSans3TextTheme(base);
  final narrow = GoogleFonts.barlowCondensedTextTheme(base);

  return humanist.copyWith(
    displayLarge: _withTextColor(narrow.displayLarge),
    displayMedium: _withTextColor(narrow.displayMedium),
    displaySmall: _withTextColor(narrow.displaySmall),
    headlineLarge: _withTextColor(narrow.headlineLarge),
    headlineMedium: _withTextColor(narrow.headlineMedium),
    headlineSmall: _withTextColor(narrow.headlineSmall),
    titleLarge: _withTextColor(narrow.titleLarge),
    titleMedium: _withTextColor(narrow.titleMedium),
    titleSmall: _withTextColor(narrow.titleSmall),
    bodyLarge: _withTextColor(humanist.bodyLarge),
    bodyMedium: _withTextColor(humanist.bodyMedium),
    bodySmall: _withTextColor(humanist.bodySmall),
    labelLarge: _withTextColor(humanist.labelLarge),
    labelMedium: _withTextColor(humanist.labelMedium),
    labelSmall: _withTextColor(humanist.labelSmall),
  );
}

ThemeData buildKuglaTheme() {
  const colorScheme = ColorScheme.dark(
    primary: KuglaColors.cyan,
    secondary: KuglaColors.amber,
    surface: KuglaColors.panel,
    onSurface: KuglaColors.text,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: KuglaColors.deepSpace,
  );

  final textTheme = _kuglaTextTheme(base.textTheme);

  return base.copyWith(
    textTheme: textTheme,
    primaryTextTheme: _kuglaTextTheme(base.primaryTextTheme),
    cardTheme: CardThemeData(
      color: KuglaColors.panel,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: KuglaColors.stroke),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: KuglaColors.panelRaised,
      selectedColor: KuglaColors.cyan.withValues(alpha: 0.14),
      side: const BorderSide(color: KuglaColors.stroke),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: GoogleFonts.sourceSans3(
        color: KuglaColors.text,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        fontSize: 14,
      ),
    ),
    dividerColor: KuglaColors.stroke,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: KuglaColors.text,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
      toolbarTextStyle: textTheme.bodyMedium,
    ),
  );
}
