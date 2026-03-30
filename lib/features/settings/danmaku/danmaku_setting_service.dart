import 'package:shared_preferences/shared_preferences.dart';

class DanmakuSettingService {
  static const _keyShowDanmaku = 'danmaku_show_danmaku';

  Future<bool> getShowDanmaku() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowDanmaku) ?? false;
  }

  Future<void> setShowDanmaku(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowDanmaku, value);
  }
}
