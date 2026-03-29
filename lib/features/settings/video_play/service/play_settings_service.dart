import 'package:shared_preferences/shared_preferences.dart';

class PlayService {
  static const String _keyVideoSource = 'video_source';
  static const String _keyAutoPlayNext = 'auto_play_next';
  static const String _keyPlaySpeed = 'play_speed';

  Future<String?> getVideoSource() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyVideoSource);
  }

  Future<void> setVideoSource(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyVideoSource, value);
  }

  Future<bool> getAutoPlayNext() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoPlayNext) ?? true;
  }

  Future<void> setAutoPlayNext(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoPlayNext, value);
  }

  Future<double> getPlaySpeed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyPlaySpeed) ?? 1.0;
  }

  Future<void> setPlaySpeed(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyPlaySpeed, value);
  }
}
