import 'package:flutter/material.dart';

class AppColors {
  // 主题色
  static const Color primary = Colors.deepPurple;
  static const Color secondary = Colors.purpleAccent;

  // 状态色
  static const Color error = Colors.red;
  static const Color success = Colors.green;
  static const Color warning = Colors.orange;

  // 背景色
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;

  // 文本色
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);

  // 边框和分割线
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFBDBDBD);

  // 图标色
  static const Color iconActive = Color(0xFF212121);
  static const Color iconInactive = Color(0xFF757575);

  // 骨架屏
  static const Color skeletonBase = Color(0xFFE0E0E0);
  static const Color skeletonHighlight = Color(0xFFEEEEEE);

  // 阴影
  static Color shadow = Colors.black.withValues(alpha: 0.1);

  // 占位符
  static const Color placeholder = Color(0xFFE0E0E0);
  static const Color placeholderIcon = Color(0xFF9E9E9E);
}
