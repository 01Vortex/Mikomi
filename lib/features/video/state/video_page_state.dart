import 'package:flutter/foundation.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mikomi/features/settings/danmaku/danmaku_setting_service.dart';
import 'package:mikomi/features/video/controller/danmaku_controller.dart'
    as app_danmaku;
import 'package:mikomi/features/video/services/video_playback_service.dart';
import 'package:mikomi/features/video/state/fullscreen_video_state.dart';
import 'package:mikomi/features/video/state/video_player_listener.dart';
import 'package:mikomi/features/video/state/video_state.dart';
import 'package:mikomi/features/video/ui/widgets/video_fit.dart';

class VideoPageState {
  final String title;
  final String? animeTitle;
  final int? bangumiId;
  final VideoPlaybackService playbackService;
  final VideoPlayerState player;
  final VideoEpisodeState episode;
  final VideoDanmakuState danmaku;
  final VideoSourceState source;
  final Duration? initialProgress;
  final SmallscreenPlaybackState smallscreen;
  final app_danmaku.DanmakuController danmakuController;
  final DanmakuConfig danmakuConfig;
  final FullscreenVideoState fullscreenState;
  final ValueListenable<VideoPlayerSnapshot> playerSnapshotListenable;
  final VideoFitMode fullscreenFitMode;

  const VideoPageState({
    required this.title,
    required this.animeTitle,
    required this.bangumiId,
    required this.playbackService,
    required this.player,
    required this.episode,
    required this.danmaku,
    required this.source,
    required this.initialProgress,
    required this.smallscreen,
    required this.danmakuController,
    required this.danmakuConfig,
    required this.fullscreenState,
    required this.playerSnapshotListenable,
    required this.fullscreenFitMode,
  });
}

/// 小屏播放器状态（不含播放进度——进度由 [VideoPlayerSnapshot] 提供）。
class SmallscreenPlaybackState {
  final VideoController? videoController;
  final bool isInitialized;
  final bool isLoading;
  final Object? error;

  const SmallscreenPlaybackState({
    required this.videoController,
    required this.isInitialized,
    required this.isLoading,
    required this.error,
  });

  const SmallscreenPlaybackState.initial()
    : videoController = null,
      isInitialized = false,
      isLoading = true,
      error = null;

  bool get showPlayer =>
      error == null &&
      isInitialized &&
      !isLoading &&
      videoController != null;

  SmallscreenPlaybackState copyWith({
    VideoController? videoController,
    bool? isInitialized,
    bool? isLoading,
    Object? error,
  }) {
    return SmallscreenPlaybackState(
      videoController: videoController ?? this.videoController,
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
