import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mikomi/features/settings/video_play/service/hardware_decode_service.dart';
import 'package:mikomi/features/settings/video_play/service/play_setting_service.dart';
import 'package:mikomi/features/settings/video_play/service/video_renderer_service.dart';

class VideoPlaybackService {
  Player? _player;
  VideoController? _videoController;
  bool _isInitialized = false;
  bool _isDisposing = false;
  final HardwareDecodeService _hwService = HardwareDecodeService();
  final PlaySettingsService _basisService = PlaySettingsService();
  final VideoRendererService _rendererService = VideoRendererService();

  bool get isInitialized => _isInitialized;
  Player? get player => _player;
  VideoController? get videoController => _videoController;

  String? _resolveVo(VideoRenderer renderer) {
    return switch (renderer) {
      VideoRenderer.auto => null,
      VideoRenderer.textureView => 'gpu',
      VideoRenderer.surfaceView => 'mediacodec_embed',
    };
  }

  bool? _resolveAttachSurfaceAfterVideoParameters(VideoRenderer renderer) {
    return switch (renderer) {
      VideoRenderer.auto => null,
      VideoRenderer.textureView => true,
      VideoRenderer.surfaceView => false,
    };
  }

  Future<String> _applyLowLatencyAudio(bool lowLatencyAudio) async {
    if (!lowLatencyAudio || _player == null) return 'default';
    if (!Platform.isAndroid || _player!.platform is! NativePlayer) {
      return 'default';
    }

    final nativePlayer = _player!.platform as NativePlayer;
    await nativePlayer.setProperty('ao', 'opensles');
    return await nativePlayer.getProperty('ao');
  }

  Future<void> initialize({bool smallScreen = false}) async {
    if (_isDisposing || _player != null) return;
    try {
      final enabled = await _hwService.getEnabled();
      final decoder = await _hwService.getDecoder();
      final renderer = await _rendererService.getRenderer();
      final lowLatencyAudio = await _basisService.getLowLatencyAudio();
      final playSpeed = await _basisService.getPlaySpeed();

      _player = Player(
        configuration: const PlayerConfiguration(
          bufferSize: 32 * 1024 * 1024,
          logLevel: MPVLogLevel.error,
        ),
      );

      final resolvedVo = _resolveVo(renderer);
      final resolvedAttachSurfaceAfterVideoParameters =
          _resolveAttachSurfaceAfterVideoParameters(renderer);

      final videoControllerConfig = VideoControllerConfiguration(
        enableHardwareAcceleration: enabled,
        hwdec: enabled ? decoder.hwdecValue : 'no',
        vo: resolvedVo,
        androidAttachSurfaceAfterVideoParameters:
            resolvedAttachSurfaceAfterVideoParameters,
        scale: smallScreen ? 0.75 : 1.0,
      );

      _videoController = VideoController(
        _player!,
        configuration: videoControllerConfig,
      );

      final resolvedAo = await _applyLowLatencyAudio(lowLatencyAudio);

      final platformController = await _videoController!.platform.future;
      debugPrint(
        '✅ VideoPlaybackService: renderer=${renderer.name}, '
        'vo=${platformController.configuration.vo ?? 'default'}, '
        'hwdec=${platformController.configuration.hwdec ?? 'default'}, '
        'lowLatencyAudio=$lowLatencyAudio, ao=$resolvedAo',
      );

      // 设置默认播放速度
      await _player!.setRate(playSpeed);

      _isInitialized = true;
    } catch (e) {
      debugPrint('VideoPlaybackService: 初始化失败 - $e');
      _isInitialized = false;
    }
  }

  Future<void> play(String url) async {
    if (_player == null || !_isInitialized || _isDisposing) return;
    try {
      await _player!.open(Media(url), play: true);
    } catch (e) {
      debugPrint('VideoPlaybackService: 播放失败 - $e');
      rethrow;
    }
  }

  Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (e) {
      debugPrint('VideoPlaybackService: 停止失败 - $e');
    }
  }

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

