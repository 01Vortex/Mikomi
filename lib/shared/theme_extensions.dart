import 'package:flutter/material.dart';

extension ColorExtension on Color {
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightened = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return lightened.toColor();
  }

  Color lightenMore([double amount = 0.2]) {
    return lighten(amount);
  }

  Color lightenMost([double amount = 0.35]) {
    return lighten(amount);
  }

  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final darkened = hsl.withLightness(
      (hsl.lightness - amount).clamp(0.0, 1.0),
    );
    return darkened.toColor();
  }
}

class ThemeColorScheme {
  final Color primary;
  final Color primaryLight;
  final Color primaryLighter;
  final Color primaryLightest;

  ThemeColorScheme({
    required this.primary,
    Color? primaryLight,
    Color? primaryLighter,
    Color? primaryLightest,
  })  : primaryLight = primaryLight ?? primary.lighten(0.15),
        primaryLighter = primaryLighter ?? primary.lighten(0.25),
        primaryLightest = primaryLightest ?? primary.lighten(0.4);

  factory ThemeColorScheme.auto(Color primary) {
    return ThemeColorScheme(primary: primary);
  }

  Color get surface => primaryLightest;
  Color get surfaceVariant => primaryLighter;
  Color get onSurface => primary;
  Color get onSurfaceVariant => primaryLight;

  LinearGradient getBackgroundGradient() {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        primaryLightest,
        primaryLighter,
        primaryLight,
        primary.withValues(alpha: 0.1),
      ],
      stops: const [0.0, 0.33, 0.66, 1.0],
    );
  }
}

extension ThemeColorExtensions on ColorScheme {
  Color get textPrimary => onSurface;

  Color get textSecondary => onSurface.withValues(alpha: 0.6);

  Color get textHint => onSurface.withValues(alpha: 0.5);

  Color get textDisabled => onSurface.withValues(alpha: 0.38);

  Color get textLight => onSurface.withValues(alpha: 0.3);

  Color get primaryLight => primary.withValues(alpha: 0.15);

  Color get primaryLighter => primary.withValues(alpha: 0.1);

  Color get primaryOverlay => primary.withValues(alpha: 0.3);
}

extension ThemeContextExtensions on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get textTheme => Theme.of(this).textTheme;
}
