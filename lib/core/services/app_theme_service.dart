import 'package:shared_preferences/shared_preferences.dart';
import 'package:mikomi/core/models/theme.dart';

class AppThemeService {
  static const String _themeIdKey = 'app_theme_id';
  static const String _useDynamicColorKey = 'use_dynamic_color';

  static Future<void> saveTheme(AppTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeIdKey, theme.id);
  }

  static Future<AppTheme> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeId = prefs.getString(_themeIdKey) ?? 'default';
    return AppTheme.fromId(themeId);
  }

  static Future<void> saveUseDynamicColor(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useDynamicColorKey, value);
  }

  static Future<bool> getUseDynamicColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useDynamicColorKey) ?? false;
  }
}
