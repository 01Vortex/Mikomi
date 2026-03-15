import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPlayerController {
  Player? _player;
  VideoController? _videoController;
  bool _isInitialized = false;
  bool _isDisposing = false;

  bool get isInitialized => _isInitialized;
  Player? get player => _player;
  VideoController? get videoController => _videoController;

  /// 初始化播放器
  Future<void> initialize() async {
    if (_isDisposing) {
      debugPrint('VideoPlayerController: 正在释放中，无法初始化');
      return;
    }

    if (_player != null) {
      debugPrint('VideoPlayerController: 播放器已存在，复用实例');
      return;
    }

    try {
      debugPrint('VideoPlayerController: 创建新播放器实例');

      _player = Player(
        configuration: const PlayerConfiguration(
          bufferSize: 50 * 1024 * 1024,
          logLevel: MPVLogLevel.error,
        ),
      );

      _videoController = VideoController(_player!);
      _isInitialized = true;

      debugPrint('VideoPlayerController: 播放器初始化成功');
    } catch (e) {
      debugPrint('VideoPlayerController: 初始化失败 - $e');
      _isInitialized = false;
    }
  }

  /// 播放视频
  Future<void> play(String url) async {
    if (_player == null || !_isInitialized || _isDisposing) {
      debugPrint('VideoPlayerController: 播放器未初始化或正在释放');
      return;
    }

    try {
      debugPrint('========== 播放器调试 ==========');
      debugPrint('VideoPlayerController: 开始播放');
      debugPrint('视频URL: $url');
      debugPrint('URL长度: ${url.length}');
      debugPrint('URL是否为空: ${url.isEmpty}');
      debugPrint('URL是否包含http: ${url.contains('http')}');

      // 验证URL格式
      if (!_isValidVideoUrl(url)) {
        debugPrint('警告: URL格式可能不正确,不是标准视频流地址');
      }

      debugPrint('==================================');

      await _player!.open(Media(url), play: true);
      debugPrint('VideoPlayerController: Media.open 调用完成');
    } catch (e) {
      debugPrint('VideoPlayerController: 播放失败 - $e');
      rethrow;
    }
  }

  /// 验证是否是有效的视频URL
  bool _isValidVideoUrl(String url) {
    if (url.isEmpty || !url.contains('http')) {
      return false;
    }

    // 检查是否是视频流格式
    final videoExtensions = ['.m3u8', '.mp4', '.flv', '.ts', '.mkv', '.avi'];
    final hasVideoExtension = videoExtensions.any((ext) => url.contains(ext));

    // 如果包含这些关键词,可能是网页而不是视频流
    final webPageKeywords = ['.html', '.php', '.jsp', '.asp'];
    final isWebPage = webPageKeywords.any((keyword) => url.contains(keyword));

    return hasVideoExtension || !isWebPage;
  }

  /// 停止播放
  Future<void> stop() async {
    if (_player == null) return;

    try {
      debugPrint('VideoPlayerController: 停止播放');
      await _player!.stop();
    } catch (e) {
      debugPrint('VideoPlayerController: 停止失败 - $e');
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    if (_isDisposing) {
      debugPrint('VideoPlayerController: 已在释放中');
      return;
    }

    _isDisposing = true;
    debugPrint('VideoPlayerController: 开始释放资源');

    try {
      // 先停止播放
      await stop();

      // 等待一小段时间确保停止完成
      await Future.delayed(const Duration(milliseconds: 100));

      // 释放播放器
      final player = _player;
      _player = null;
      _videoController = null;
      _isInitialized = false;

      if (player != null) {
        await player.dispose();
        debugPrint('VideoPlayerController: 播放器已释放');
      }
    } catch (e) {
      debugPrint('VideoPlayerController: 释放失败 - $e');
    } finally {
      _isDisposing = false;
    }
  }
}
