import 'package:flutter/material.dart';

/// 主题颜色扩展
/// 提供常用的颜色透明度变体,避免重复代码
extension ThemeColorExtensions on ColorScheme {
  /// 主要文本颜色 (完全不透明)
  Color get textPrimary => onSurface;

  /// 次要文本颜色 (60% 不透明度)
  Color get textSecondary => onSurface.withValues(alpha: 0.6);

  /// 提示文本颜色 (50% 不透明度)
  Color get textHint => onSurface.withValues(alpha: 0.5);

  /// 禁用文本颜色 (38% 不透明度)
  Color get textDisabled => onSurface.withValues(alpha: 0.38);

  /// 浅色文本颜色 (30% 不透明度)
  Color get textLight => onSurface.withValues(alpha: 0.3);

  /// 主色调浅色背景 (15% 不透明度)
  Color get primaryLight => primary.withValues(alpha: 0.15);

  /// 主色调极浅背景 (10% 不透明度)
  Color get primaryLighter => primary.withValues(alpha: 0.1);

  /// 主色调覆盖层 (30% 不透明度)
  Color get primaryOverlay => primary.withValues(alpha: 0.3);
}

/// BuildContext 主题扩展
/// 快速访问主题颜色
extension ThemeContextExtensions on BuildContext {
  /// 获取当前主题的 ColorScheme
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// 获取当前主题的 TextTheme
  TextTheme get textTheme => Theme.of(this).textTheme;
}
