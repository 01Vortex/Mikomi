import 'package:flutter/material.dart';
import 'package:mikomi/core/models/theme_color_scheme.dart';

class AppTheme {
  final String id;
  final String name;
  final Color primaryColor;
  final ThemeColorScheme colorScheme;

  AppTheme({
    required this.id,
    required this.name,
    required this.primaryColor,
    ThemeColorScheme? colorScheme,
  }) : colorScheme = colorScheme ?? ThemeColorScheme.auto(primaryColor);

  /// 默认主题：主题色 #0099ff
  static final AppTheme defaultTheme = AppTheme(
    id: 'default',
    name: '默认蓝',
    primaryColor: const Color(0xFF0099FF),
  );

  /// 清新绿
  static final AppTheme greenTheme = AppTheme(
    id: 'green',
    name: '清新绿',
    primaryColor: const Color(0xFF4CAF50),
  );

  static final List<AppTheme> allThemes = [
    defaultTheme,
    greenTheme,
  ];

  static AppTheme fromId(String id) {
    try {
      return allThemes.firstWhere((theme) => theme.id == id);
    } catch (_) {
      return defaultTheme;
    }
  }

  /// 获取背景色渐变（四色混合）
  LinearGradient getBackgroundGradient() {
    return colorScheme.getBackgroundGradient();
  }
}

