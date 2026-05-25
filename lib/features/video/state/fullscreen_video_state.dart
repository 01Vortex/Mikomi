import 'package:flutter/foundation.dart';
import 'package:mikomi/features/video/controller/danmaku_controller.dart'
    as app_danmaku;
import 'package:mikomi/features/video/controller/danmaku_facade.dart';
import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/state/video_player_listener.dart';

class FullscreenVideoState {
  final int currentEpisode;
  final List<Episode> episodes;
  final bool isLoadingEpisodes;
  final bool isDescending;
  final bool hasNextEpisode;
  final bool hasPreviousEpisode;
  final String? currentSmallTitle;
  final bool isDanmakuEnabled;
  final app_danmaku.DanmakuController? danmakuController;
  final DanmakuFacade? danmakuFacade;
  final ValueListenable<VideoPlayerSnapshot>? playerSnapshotListenable;

  const FullscreenVideoState({
    required this.currentEpisode,
    required this.episodes,
    required this.isLoadingEpisodes,
    required this.isDescending,
    required this.hasNextEpisode,
    required this.hasPreviousEpisode,
    this.currentSmallTitle,
    this.isDanmakuEnabled = false,
    this.danmakuController,
    this.danmakuFacade,
    this.playerSnapshotListenable,
  });

  FullscreenVideoState copyWith({
    int? currentEpisode,
    List<Episode>? episodes,
    bool? isLoadingEpisodes,
    bool? isDescending,
    bool? hasNextEpisode,
    bool? hasPreviousEpisode,
    Object? currentSmallTitle = _sentinel,
    bool? isDanmakuEnabled,
    app_danmaku.DanmakuController? danmakuController,
    DanmakuFacade? danmakuFacade,
    ValueListenable<VideoPlayerSnapshot>? playerSnapshotListenable,
  }) {
    return FullscreenVideoState(
      currentEpisode: currentEpisode ?? this.currentEpisode,
      episodes: episodes ?? this.episodes,
      isLoadingEpisodes: isLoadingEpisodes ?? this.isLoadingEpisodes,
      isDescending: isDescending ?? this.isDescending,
      hasNextEpisode: hasNextEpisode ?? this.hasNextEpisode,
      hasPreviousEpisode: hasPreviousEpisode ?? this.hasPreviousEpisode,
      currentSmallTitle: currentSmallTitle == _sentinel
          ? this.currentSmallTitle
          : currentSmallTitle as String?,
      isDanmakuEnabled: isDanmakuEnabled ?? this.isDanmakuEnabled,
      danmakuController: danmakuController ?? this.danmakuController,
      danmakuFacade: danmakuFacade ?? this.danmakuFacade,
      playerSnapshotListenable:
          playerSnapshotListenable ?? this.playerSnapshotListenable,
    );
  }

  static const Object _sentinel = Object();
}
