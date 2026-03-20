import 'package:shared_preferences/shared_preferences.dart';

/// 播放设置服务
/// 管理播放相关的设置项持久化
class PlayService {
  static const String _keyVideoSource = 'video_source';
  static const String _keyHardwareDecoding = 'hardware_decoding';
  static const String _keyAutoPlayNext = 'auto_play_next';
  static const String _keyPlaySpeed = 'play_speed';

  /// 获取视频源
  Future<String?> getVideoSource() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyVideoSource);
  }

  /// 设置视频源
  Future<void> setVideoSource(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyVideoSource, value);
  }

  /// 获取硬件解码设置
  Future<bool> getHardwareDecoding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHardwareDecoding) ?? true;
  }

  /// 设置硬件解码
  Future<void> setHardwareDecoding(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHardwareDecoding, value);
  }

  /// 获取自动连播设置
  Future<bool> getAutoPlayNext() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoPlayNext) ?? true;
  }

  /// 设置自动连播
  Future<void> setAutoPlayNext(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoPlayNext, value);
  }

  /// 获取播放速度
  Future<double> getPlaySpeed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyPlaySpeed) ?? 1.0;
  }

  /// 设置播放速度
  Future<void> setPlaySpeed(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyPlaySpeed, value);
  }
}
