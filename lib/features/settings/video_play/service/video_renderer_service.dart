import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

enum VideoRenderer {
  auto,
  textureView,
  surfaceView;

  String get value => switch (this) {
    VideoRenderer.auto => 'auto',
    VideoRenderer.textureView => 'texture_view',
    VideoRenderer.surfaceView => 'surface_view',
  };

  String get label => switch (this) {
    VideoRenderer.auto => '自动',
    VideoRenderer.textureView => 'GPU',
    VideoRenderer.surfaceView => 'MediaCodec',
  };

  String get description => switch (this) {
    VideoRenderer.auto => 'Android 默认使用 GPU 渲染，整体帧率更稳定',
    VideoRenderer.textureView => '使用 MPV GPU 渲染，适合叠加 Flutter 控制层和弹幕',
    VideoRenderer.surfaceView => '使用 MediaCodec 嵌入渲染，视频解码压力低但可能影响页面帧率',
  };

  static List<VideoRenderer> get platformRenderers {
    if (Platform.isAndroid) {
      return [
        VideoRenderer.auto,
        VideoRenderer.textureView,
        VideoRenderer.surfaceView,
      ];
    }
    return [VideoRenderer.auto, VideoRenderer.textureView];
  }

  static VideoRenderer get platformDefault {
    return VideoRenderer.auto;
  }

  static VideoRenderer fromValue(String value) {
    return VideoRenderer.values.firstWhere(
      (e) => e.value == value,
      orElse: () => platformDefault,
    );
  }
}

class VideoRendererService {
  static const String _keyRenderer = 'video_renderer';
  static const String _keyRendererMigrated = 'video_renderer_gpu_default_v2';

  Future<VideoRenderer> getRenderer() async {
    final prefs = await SharedPreferences.getInstance();
    final migrated = prefs.getBool(_keyRendererMigrated) ?? false;
    final value = prefs.getString(_keyRenderer);

    if (!migrated && Platform.isAndroid && value == VideoRenderer.surfaceView.value) {
      await prefs.setString(_keyRenderer, VideoRenderer.auto.value);
      await prefs.setBool(_keyRendererMigrated, true);
      return VideoRenderer.auto;
    }

    if (!migrated) {
      await prefs.setBool(_keyRendererMigrated, true);
    }

    if (value == null) return VideoRenderer.platformDefault;
    return VideoRenderer.fromValue(value);
  }

  Future<void> setRenderer(VideoRenderer renderer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRendererMigrated, true);
    await prefs.setString(_keyRenderer, renderer.value);
  }
}
