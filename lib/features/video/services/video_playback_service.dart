import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mikomi/features/settings/video_settings/service/play_settings_service.dart';

class VideoPlaybackService {
  Player? _player;
  VideoController? _videoController;
  bool _isInitialized = false;
  bool _isDisposing = false;
  final PlayService _playService = PlayService();

  bool get isInitialized => _isInitialized;
  Player? get player => _player;
  VideoController? get videoController => _videoController;

  /// 初始化播放器
  /// [smallScreen]: 小屏模式下使用 scale=0.75 降低渲染负担
  Future<void> initialize({bool smallScreen = false}) async {
    if (_isDisposing || _player != null) return;

    try {
      final hardwareDecoding = await _playService.getHardwareDecoding();

      _player = Player(
        configuration: const PlayerConfiguration(
          bufferSize: 32 * 1024 * 1024,
          logLevel: MPVLogLevel.error,
        ),
      );

      _videoController = VideoController(
        _player!,
        configuration: VideoControllerConfiguration(
          enableHardwareAcceleration: hardwareDecoding,
          hwdec: hardwareDecoding ? 'auto-safe' : 'no',
          scale: smallScreen ? 0.75 : 1.0,
        ),
      );

      _isInitialized = true;
    } catch (e) {
      debugPrint('VideoPlaybackService: 初始化失败 - $e');
      _isInitialized = false;
    }
  }

  /// 播放视频
  Future<void> play(String url) async {
    if (_player == null || !_isInitialized || _isDisposing) return;
    try {
      await _player!.open(Media(url), play: true);
    } catch (e) {
      debugPrint('VideoPlaybackService: 播放失败 - $e');
      rethrow;
    }
  }

  /// 停止播放
  Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (e) {
      debugPrint('VideoPlaybackService: 停止失败 - $e');
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    if (_isDisposing) return;
    _isDisposing = true;
    try {
      await _player?.pause();
      await _player?.stop();
      final player = _player;
      _player = null;
      _videoController = null;
      _isInitialized = false;
      await player?.dispose();
    } catch (e) {
      debugPrint('VideoPlaybackService: 释放失败 - $e');
    } finally {
      _isDisposing = false;
    }
  }
}
