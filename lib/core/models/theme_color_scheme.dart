import 'package:flutter/material.dart';

extension ColorExtension on Color {
  /// 生成浅色版本（增加亮度）
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightened = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return lightened.toColor();
  }

  /// 生成更浅的版本
  Color lightenMore([double amount = 0.2]) {
    return lighten(amount);
  }

  /// 生成最浅的版本（背景色）
  Color lightenMost([double amount = 0.35]) {
    return lighten(amount);
  }

  /// 生成深色版本（降低亮度）
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final darkened = hsl.withLightness(
      (hsl.lightness - amount).clamp(0.0, 1.0),
    );
    return darkened.toColor();
  }
}

/// 主题色系统
class ThemeColorScheme {
  final Color primary;           // 主题色（最深）
  final Color primaryLight;      // 浅色版本
  final Color primaryLighter;    // 更浅版本
  final Color primaryLightest;   // 最浅版本（背景）

  ThemeColorScheme({
    required this.primary,
    Color? primaryLight,
    Color? primaryLighter,
    Color? primaryLightest,
  })  : primaryLight = primaryLight ?? primary.lighten(0.15),
        primaryLighter = primaryLighter ?? primary.lighten(0.25),
        primaryLightest = primaryLightest ?? primary.lighten(0.4);

  /// 从主题色自动生成色系
  factory ThemeColorScheme.auto(Color primary) {
    return ThemeColorScheme(primary: primary);
  }

  // 衍生色
  Color get surface => primaryLightest;
  Color get surfaceVariant => primaryLighter;
  Color get onSurface => primary;
  Color get onSurfaceVariant => primaryLight;

  /// 获取背景渐变（四色混合）
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
