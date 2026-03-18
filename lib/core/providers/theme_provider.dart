import 'package:flutter/material.dart';
import 'package:mikomi/core/services/theme_service.dart';

class ThemeProvider extends ChangeNotifier {
  Color? _themeColor;
  bool _useDynamicColor = false;
  String _fontFamily = 'system';

  Color? get themeColor => _themeColor;
  bool get useDynamicColor => _useDynamicColor;
  String get fontFamily => _fontFamily;

  ThemeProvider() {
    _loadThemeSettings();
  }

  Future<void> _loadThemeSettings() async {
    _themeColor = await ThemeService.getThemeColor();
    _useDynamicColor = await ThemeService.getUseDynamicColor();
    _fontFamily = await ThemeService.getFontFamily();
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

  Future<void> setFontFamily(String fontFamily) async {
    _fontFamily = fontFamily;
    await ThemeService.saveFontFamily(fontFamily);
    debugPrint('字体已设置为: $fontFamily, 实际字体: ${getEffectiveFontFamily()}');
    notifyListeners();
  }

  Color getEffectiveColor(BuildContext context) {
    if (_useDynamicColor) {
      return Theme.of(context).colorScheme.primary;
    }
    return _themeColor ?? Colors.blue;
  }

  String? getEffectiveFontFamily() {
    final fontFamily = _fontFamily == 'system' ? null : 'LXGWWenKai';
    debugPrint('当前字体设置: $_fontFamily, 返回字体: $fontFamily');
    return fontFamily;
  }
}
