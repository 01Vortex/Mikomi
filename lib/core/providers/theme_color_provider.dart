import 'package:flutter/material.dart';
import 'package:mikomi/core/services/theme_service.dart';

class ColorProvider extends ChangeNotifier {
  Color? _themeColor;
  bool _useDynamicColor = false;

  Color? get themeColor => _themeColor;
  bool get useDynamicColor => _useDynamicColor;

  ColorProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _themeColor = await ThemeService.getThemeColor();
    _useDynamicColor = await ThemeService.getUseDynamicColor();
    notifyListeners();
  }

  Future<void> setThemeColor(Color color) async {
    _themeColor = color;
    _useDynamicColor = false;
    await ThemeService.saveThemeColor(color);
    await ThemeService.saveUseDynamicColor(false);
    notifyListeners();
  }

  Future<void> setUseDynamicColor(bool value) async {
    _useDynamicColor = value;
    if (value) {
      _themeColor = null;
    }
    await ThemeService.saveUseDynamicColor(value);
    notifyListeners();
  }

  Color getEffectiveColor(BuildContext context) {
    if (_useDynamicColor) {
      return Theme.of(context).colorScheme.primary;
    }
    return _themeColor ?? Colors.blue;
  }
}
