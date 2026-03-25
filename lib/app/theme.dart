import 'package:flutter/material.dart';

class KuglaColors {
  static const deepSpace = Color(0xFF08111F);
  static const midnight = Color(0xFF0D1B2F);
  static const panel = Color(0xFF13233D);
  static const panelRaised = Color(0xFF1A3152);
  static const cyan = Color(0xFF61E6E8);
  static const cyanSoft = Color(0xFF99F5F2);
  static const amber = Color(0xFFFFC86B);
  static const rose = Color(0xFFFF8D9C);
  static const lilac = Color(0xFFB6A9FF);
  static const success = Color(0xFF87F0A2);
  static const text = Color(0xFFEAF6FF);
  static const textMuted = Color(0xFFA8BED5);
  static const stroke = Color(0x3349D9FF);
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

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: KuglaColors.text,
      displayColor: KuglaColors.text,
    ),
    cardTheme: CardThemeData(
      color: KuglaColors.panel,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: KuglaColors.stroke),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: KuglaColors.panelRaised,
      selectedColor: KuglaColors.cyan.withValues(alpha: 0.18),
      side: const BorderSide(color: KuglaColors.stroke),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      labelStyle: const TextStyle(
        color: KuglaColors.text,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    ),
    dividerColor: KuglaColors.stroke,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: KuglaColors.text,
      centerTitle: false,
    ),
  );
}
