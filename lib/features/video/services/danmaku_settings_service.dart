import 'package:shared_preferences/shared_preferences.dart';

class DanmakuSettingsService {
  static const _keyFontSize = 'danmaku_font_size';
  static const _keyOpacity = 'danmaku_opacity';
  static const _keyArea = 'danmaku_area';
  static const _keyDuration = 'danmaku_duration';
  static const _keyStrokeWidth = 'danmaku_stroke_width';
  static const _keyShowTop = 'danmaku_show_top';
  static const _keyShowBottom = 'danmaku_show_bottom';
  static const _keyShowScroll = 'danmaku_show_scroll';

  static Future<double> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyFontSize) ?? 16.0;
  }

  static Future<void> setFontSize(double v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFontSize, v);
  }

  static Future<double> getOpacity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyOpacity) ?? 1.0;
  }

  static Future<void> setOpacity(double v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyOpacity, double.parse(v.toStringAsFixed(2)));
  }

  static Future<double> getArea() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyArea) ?? 0.5;
  }

  static Future<void> setArea(double v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyArea, v);
  }

  static Future<double> getDuration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyDuration) ?? 8.0;
  }

  static Future<void> setDuration(double v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyDuration, v);
  }

  static Future<double> getStrokeWidth() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyStrokeWidth) ?? 1.0;
  }

  static Future<void> setStrokeWidth(double v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyStrokeWidth, double.parse(v.toStringAsFixed(1)));
  }

  static Future<bool> getShowTop() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowTop) ?? true;
  }

  static Future<void> setShowTop(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowTop, v);
  }

  static Future<bool> getShowBottom() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowBottom) ?? false;
  }

  static Future<void> setShowBottom(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowBottom, v);
  }

  static Future<bool> getShowScroll() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowScroll) ?? true;
  }

  static Future<void> setShowScroll(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowScroll, v);
  }

  /// 一次性读取所有设置
  static Future<DanmakuConfig> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    return DanmakuConfig(
      fontSize: prefs.getDouble(_keyFontSize) ?? 16.0,
      opacity: prefs.getDouble(_keyOpacity) ?? 1.0,
      area: prefs.getDouble(_keyArea) ?? 0.5,
      duration: prefs.getDouble(_keyDuration) ?? 8.0,
      strokeWidth: prefs.getDouble(_keyStrokeWidth) ?? 1.0,
      showTop: prefs.getBool(_keyShowTop) ?? true,
      showBottom: prefs.getBool(_keyShowBottom) ?? false,
      showScroll: prefs.getBool(_keyShowScroll) ?? true,
    );
  }
}

class DanmakuConfig {
  final double fontSize;
  final double opacity;
  final double area;
  final double duration;
  final double strokeWidth;
  final bool showTop;
  final bool showBottom;
  final bool showScroll;

  const DanmakuConfig({
    this.fontSize = 16.0,
    this.opacity = 1.0,
    this.area = 0.5,
    this.duration = 8.0,
    this.strokeWidth = 1.0,
    this.showTop = true,
    this.showBottom = false,
    this.showScroll = true,
  });

  DanmakuConfig copyWith({
    double? fontSize,
    double? opacity,
    double? area,
    double? duration,
    double? strokeWidth,
    bool? showTop,
    bool? showBottom,
    bool? showScroll,
  }) {
    return DanmakuConfig(
      fontSize: fontSize ?? this.fontSize,
      opacity: opacity ?? this.opacity,
      area: area ?? this.area,
      duration: duration ?? this.duration,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      showTop: showTop ?? this.showTop,
      showBottom: showBottom ?? this.showBottom,
      showScroll: showScroll ?? this.showScroll,
    );
  }
}
