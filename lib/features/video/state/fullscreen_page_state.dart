import 'package:media_kit_video/media_kit_video.dart';
import 'package:mikomi/features/settings/danmaku/danmaku_setting_service.dart';
import 'package:mikomi/features/video/controller/danmaku_controller.dart'
    as app_danmaku;
import 'package:mikomi/features/video/ui/widgets/smallscreen/smallscreen_video.dart';
import 'package:mikomi/features/video/ui/widgets/video_fit.dart';

class FullscreenPageState {
  final FullscreenVideoState videoState;
  final VideoController? videoController;
  final app_danmaku.DanmakuController danmakuController;
  final DanmakuConfig danmakuConfig;
  final VideoFitMode fitMode;
  final bool isVideoReady;

  const FullscreenPageState({
    required this.videoState,
    required this.videoController,
    required this.danmakuController,
    required this.danmakuConfig,
    required this.fitMode,
    required this.isVideoReady,
  });

  FullscreenPageState copyWith({
    FullscreenVideoState? videoState,
    VideoController? videoController,
    app_danmaku.DanmakuController? danmakuController,
    DanmakuConfig? danmakuConfig,
    VideoFitMode? fitMode,
    bool? isVideoReady,
  }) {
    return FullscreenPageState(
      videoState: videoState ?? this.videoState,
      videoController: videoController ?? this.videoController,
      danmakuController: danmakuController ?? this.danmakuController,
      danmakuConfig: danmakuConfig ?? this.danmakuConfig,
      fitMode: fitMode ?? this.fitMode,
      isVideoReady: isVideoReady ?? this.isVideoReady,
    );
  }
}
