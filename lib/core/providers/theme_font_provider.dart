import 'package:flutter/material.dart';
import 'package:mikomi/core/services/theme_service.dart';

class FontProvider extends ChangeNotifier {
  String _fontFamily = 'system';

  String get fontFamily => _fontFamily;

  FontProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _fontFamily = await ThemeService.getFontFamily();
    notifyListeners();
  }

  Future<void> setFontFamily(String fontFamily) async {
    _fontFamily = fontFamily;
    await ThemeService.saveFontFamily(fontFamily);
    notifyListeners();
  }

  String? getEffectiveFontFamily() {
    return _fontFamily == 'system' ? null : 'LXGWWenKai';
  }
}
