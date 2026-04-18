import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Teal atlas palette — matches icon/splash branding.
class KuglaColors {
  static const deepSpace   = Color(0xFF071318);
  static const midnight    = Color(0xFF0C1E28);
  static const panel       = Color(0xFF112635);
  static const panelRaised = Color(0xFF163040);
  static const graphite    = Color(0xFF142C39);

  /// Primary label / teal highlights.
  static const cyan     = Color(0xFF7ADAEE);
  static const cyanSoft = Color(0xFFC0EEF8);

  /// Daily Pulse & primary actions — icon background teal.
  static const pulse = Color(0xFF26A5C3);

  /// World Atlas — jade green.
  static const atlas = Color(0xFF5FAF98);

  /// Landmark Lock — terracotta.
  static const landmark = Color(0xFFC7775A);

  /// Streaks — saffron/amber.
  static const amber = Color(0xFFD7A55A);

  /// Mauve secondary.
  static const rose = Color(0xFFB48AA0);

  /// Cool secondary / indigo.
  static const lilac = Color(0xFF6D78B8);

  static const success = Color(0xFF83B7A4);

  static const text      = Color(0xFFF0F9FC);
  static const textMuted = Color(0xFF88B5C5);

  /// Solid border.
  static const stroke = Color(0xFF1A3B4A);

  /// Muted chips / fog.
  static const fog = Color(0xFF8BBDCC);
}

TextStyle? _withTextColor(TextStyle? style) =>
    style?.copyWith(color: KuglaColors.text);

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
    primary: KuglaColors.pulse,
    onPrimary: KuglaColors.text,
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
      selectedColor: KuglaColors.pulse.withValues(alpha: 0.14),
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
