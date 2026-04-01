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
        VideoRenderer.textureView => 'TextureView',
        VideoRenderer.surfaceView => 'SurfaceView',
      };

  String get description => switch (this) {
        VideoRenderer.auto => '由系统自动选择渲染方式（推荐）',
        VideoRenderer.textureView => '兼容性更好，支持更多 UI 变换',
        VideoRenderer.surfaceView => '性能更高，适合高码率视频播放',
      };

  static List<VideoRenderer> get platformRenderers {
    if (Platform.isAndroid) {
      return [VideoRenderer.auto, VideoRenderer.textureView, VideoRenderer.surfaceView];
    }
    return [VideoRenderer.auto, VideoRenderer.textureView];
  }

  static VideoRenderer fromValue(String value) {
    return VideoRenderer.values.firstWhere(
      (e) => e.value == value,
      orElse: () => VideoRenderer.auto,
    );
  }
}

class VideoRendererService {
  static const String _keyRenderer = 'video_renderer';

  Future<VideoRenderer> getRenderer() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyRenderer) ?? VideoRenderer.auto.value;
    return VideoRenderer.fromValue(value);
  }

  Future<void> setRenderer(VideoRenderer renderer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRenderer, renderer.value);
  }
}
