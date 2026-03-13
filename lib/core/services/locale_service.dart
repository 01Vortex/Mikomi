import 'package:flutter/material.dart';

class LocaleService {
  static Locale? _currentLocale;

  static void setLocale(Locale locale) {
    _currentLocale = locale;
  }

  static Locale? getCurrentLocale() {
    return _currentLocale;
  }

  /// 获取当前语言代码用于API请求
  static String getLanguageCode() {
    if (_currentLocale == null) return 'zh-CN';

    final languageCode = _currentLocale!.languageCode;
    final countryCode = _currentLocale!.countryCode;

    // 返回完整的语言代码
    if (countryCode != null) {
      return '$languageCode-$countryCode';
    }

    // 默认映射
    switch (languageCode) {
      case 'ar':
        return 'ar-SA';
      case 'de':
        return 'de-DE';
      case 'en':
        return 'en-US';
      case 'es':
        return 'es-ES';
      case 'fr':
        return 'fr-FR';
      case 'ja':
        return 'ja-JP';
      case 'pt':
        return 'pt-BR';
      case 'ru':
        return 'ru-RU';
      case 'zh':
        return 'zh-CN';
      default:
        return 'en-US';
    }
  }

  /// 获取Accept-Language请求头
  static String getAcceptLanguage() {
    return getLanguageCode();
  }
}
