import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Industrial atlas palette — aligned with `output/mockups/generate_ui_mockups.py`.
class KuglaColors {
  static const deepSpace = Color(0xFF0B0D12);
  static const midnight = Color(0xFF12161D);
  static const panel = Color(0xFF1A1F27);
  static const panelRaised = Color(0xFF212833);
  static const graphite = Color(0xFF20252D);

  /// Primary label / ice highlights (mockup `ICE`).
  static const cyan = Color(0xFF9FC3FF);
  static const cyanSoft = Color(0xFFD9E8FF);

  /// Daily Pulse & primary actions (mockup `OCEAN`).
  static const pulse = Color(0xFF3E7CBF);

  /// World Atlas (mockup `JADE`).
  static const atlas = Color(0xFF5FAF98);

  /// Landmark Lock (mockup `TERRACOTTA`).
  static const landmark = Color(0xFFC7775A);

  /// Mauve secondary (mockup `ROSE`).
  static const rose = Color(0xFFB48AA0);

  /// Rough tier / cool secondary (mockup `INDIGO`).
  static const lilac = Color(0xFF6D78B8);

  static const success = Color(0xFF83B7A4);

  static const text = Color(0xFFF4F7FB);
  static const textMuted = Color(0xFF9DA7B6);

  /// Mockup `STROKE` — solid border.
  static const stroke = Color(0xFF2D3644);

  /// Silver-muted chips (mockup `FOG`).
  static const fog = Color(0xFFA9B5C6);
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
    secondary: KuglaColors.atlas,
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
