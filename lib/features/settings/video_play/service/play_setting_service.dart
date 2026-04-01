import 'package:shared_preferences/shared_preferences.dart';
import 'package:mikomi/features/video/ui/widgets/video_fit.dart';

class PlaySettingsService {
  static const String _keyAutoPlayNext = 'auto_play_next';
  static const String _keyPlaySpeed = 'play_speed';
  static const String _keyVideoFitMode = 'video_fit_mode';
  static const String _keyLowLatencyAudio = 'low_latency_audio';

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

  Future<VideoFitMode> getVideoFitMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyVideoFitMode);
    return VideoFitMode.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => VideoFitMode.contain,
    );
  }

  Future<void> setVideoFitMode(VideoFitMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyVideoFitMode, mode.name);
  }

  Future<bool> getLowLatencyAudio() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLowLatencyAudio) ?? true;
  }

  Future<void> setLowLatencyAudio(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLowLatencyAudio, value);
  }
}
