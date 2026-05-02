import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mikomi/features/settings/video_play/service/hardware_decode_service.dart';
import 'package:mikomi/features/settings/video_play/service/play_setting_service.dart';
import 'package:mikomi/features/settings/video_play/service/video_renderer_service.dart';
import 'package:path_provider/path_provider.dart';

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
      VideoRenderer.auto => Platform.isAndroid ? 'gpu' : null,
      VideoRenderer.textureView => 'gpu',
      VideoRenderer.surfaceView => 'mediacodec_embed',
    };
  }

  HwDecoder _resolveDecoder({
    required bool hardwareAccelerationEnabled,
    required VideoRenderer renderer,
    required HwDecoder decoder,
  }) {
    if (!hardwareAccelerationEnabled) return HwDecoder.none;
    if (Platform.isAndroid && renderer == VideoRenderer.surfaceView) {
      return HwDecoder.mediacodec;
    }
    return decoder;
  }

  Future<void> _applyNativePlayerOptions({
    required bool lowLatencyAudio,
    required VideoRenderer renderer,
  }) async {
    final player = _player;
    if (player == null || player.platform is! NativePlayer) return;

    try {
      final nativePlayer = player.platform as NativePlayer;
      final tempDir = await getTemporaryDirectory();
      await nativePlayer.setProperty('demuxer-cache-dir', tempDir.path);
      await nativePlayer.setProperty('af', 'scaletempo2=max-speed=8');
      await nativePlayer.setProperty('vd-lavc-dr', 'yes');

      if (renderer != VideoRenderer.surfaceView) {
        await nativePlayer.setProperty('video-sync', 'display-resample');
        await nativePlayer.setProperty('interpolation', 'yes');
        await nativePlayer.setProperty('tscale', 'oversample');
      }

      if (Platform.isAndroid) {
        await nativePlayer.setProperty('volume-max', '100');
        await nativePlayer.setProperty(
          'ao',
          lowLatencyAudio ? 'opensles' : 'audiotrack',
        );
      }
    } catch (error) {
      debugPrint('VideoPlaybackService: 原生播放器参数设置失败 - $error');
    }
  }

  Future<void> initialize({bool smallScreen = false}) async {
    if (_isDisposing || _player != null) return;
    try {
      final enabled = await _hwService.getEnabled();
      final decoder = await _hwService.getDecoder();
      final renderer = await _rendererService.getRenderer();
      final lowLatencyAudio = await _basisService.getLowLatencyAudio();
      final playSpeed = await _basisService.getPlaySpeed();
      final resolvedVo = _resolveVo(renderer);
      final resolvedDecoder = _resolveDecoder(
        hardwareAccelerationEnabled: enabled,
        renderer: renderer,
        decoder: decoder,
      );

      _player = Player(
        configuration: const PlayerConfiguration(
          bufferSize: 1500 * 1024 * 1024,
          osc: false,
          logLevel: MPVLogLevel.error,
        ),
      );

      await _applyNativePlayerOptions(
        lowLatencyAudio: lowLatencyAudio,
        renderer: renderer,
      );

      _videoController = VideoController(
        _player!,
        configuration: VideoControllerConfiguration(
          enableHardwareAcceleration: enabled,
          hwdec: resolvedDecoder.hwdecValue,
          vo: resolvedVo,
          androidAttachSurfaceAfterVideoParameters: false,
        ),
      );

      final platformController = await _videoController!.platform.future;
      debugPrint(
        'VideoPlaybackService: renderer=${renderer.name}, '
        'vo=${platformController.configuration.vo ?? 'default'}, '
        'hwdec=${platformController.configuration.hwdec ?? 'default'}, '
        'lowLatencyAudio=$lowLatencyAudio, '
        'smoothOutput=${renderer != VideoRenderer.surfaceView}',
      );

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
