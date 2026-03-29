import 'package:flutter/material.dart';
import 'package:mikomi/core/models/app_theme_model.dart';
import 'package:mikomi/core/services/app_theme_service.dart';

class AppThemeProvider extends ChangeNotifier {
  AppTheme _currentTheme = AppTheme.defaultTheme;
  bool _useDynamicColor = false;

  AppTheme get currentTheme => _currentTheme;
  bool get useDynamicColor => _useDynamicColor;

  AppThemeProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _currentTheme = await AppThemeService.getTheme();
    _useDynamicColor = await AppThemeService.getUseDynamicColor();
    notifyListeners();
  }

  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    _useDynamicColor = false;
    await AppThemeService.saveTheme(theme);
    await AppThemeService.saveUseDynamicColor(false);
    notifyListeners();
  }

  Future<void> setUseDynamicColor(bool value) async {
    _useDynamicColor = value;
    await AppThemeService.saveUseDynamicColor(value);
    notifyListeners();
  }

  Color getEffectiveColor(BuildContext context) {
    if (_useDynamicColor) {
      return Theme.of(context).colorScheme.primary;
    }
    return _currentTheme.primaryColor;
  }
}
