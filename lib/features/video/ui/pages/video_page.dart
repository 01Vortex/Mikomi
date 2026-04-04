import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mikomi/features/anime/selector/video_source_selector.dart';
import 'package:mikomi/features/settings/danmaku/danmaku_setting_service.dart';
import 'package:mikomi/features/settings/video_play/service/plugin_manager_service.dart';
import 'package:mikomi/features/video/controller/video_page_controller.dart';
import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/services/video_page_service.dart';
import 'package:mikomi/features/video/services/video_playback_service.dart';
import 'package:mikomi/features/video/state/video_state_manager.dart';
import 'package:mikomi/features/video/ui/widgets/comment_tab_content.dart';
import 'package:mikomi/features/video/ui/widgets/danmaku_overlay.dart';
import 'package:mikomi/features/video/ui/widgets/episcode_tab_content.dart';
import 'package:mikomi/features/video/ui/widgets/video_player_area.dart';
import 'package:mikomi/features/video/ui/widgets/video_tab.dart';

class VideoPage extends StatefulWidget {
  final String title;
  final String videoUrl;
  final int currentEpisode;
  final List<Episode> episodes;
  final List<VideoSource>? videoSources;
  final String? pluginName;
  final String? animeTitle;
  final String? animeName;
  final int? bangumiId;
  final String? coverUrl;
  final Duration? initialProgress;
  final VideoPageService? pageService;
  final VideoPlaybackService? playerController;

  const VideoPage({
    super.key,
    required this.title,
    required this.videoUrl,
    this.currentEpisode = 1,
    required this.episodes,
    this.videoSources,
    this.pluginName,
    this.animeTitle,
    this.animeName,
    this.bangumiId,
    this.coverUrl,
    this.initialProgress,
    this.pageService,
    this.playerController,
  });

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final VideoPageController _controller;

  final TextEditingController _danmakuController = TextEditingController();
  final VideoPluginManager _pluginManager = VideoPluginManager();

  @override
  void initState() {
    super.initState();
    _controller = VideoPageController(
      title: widget.title,
      videoUrl: widget.videoUrl,
      currentEpisode: widget.currentEpisode,
      episodes: widget.episodes,
      sourceName: widget.pluginName,
      initialProgress: widget.initialProgress,
      animeTitle: widget.animeTitle,
      animeName: widget.animeName,
      bangumiId: widget.bangumiId,
      pageService: widget.pageService,
      playbackService: widget.playerController,
    );
    _tabController = TabController(length: 2, vsync: this);

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );

    DanmakuSettingService().getShowDanmaku().then((enabled) {
      if (!mounted || _controller.isDisposed) {
        return;
      }
      _controller.setDanmakuEnabled(enabled);
    });

    _controller.initialize();
    _loadFallbackVideoSources();
  }

  void _clearDanmakuInput() {
    _danmakuController.clear();
  }

  Future<void> _setDanmakuEnabled(bool enabled) async {
    _controller.setDanmakuEnabled(enabled);
    if (!enabled) {
      _clearDanmakuInput();
    }
    await DanmakuSettingService().setShowDanmaku(enabled);
  }

  void _showVideoSourceSelector() {
    final sources =
        (widget.videoSources != null && widget.videoSources!.isNotEmpty)
        ? widget.videoSources!
        : <VideoSource>[];
    if (sources.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('暂无可用视频源')));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => VideoSourceSelector(
        sources: sources,
        animeTitle: widget.animeTitle,
        onSourceSelected: (source) {
          Navigator.pop(context);
          _controller.switchVideoSource(source);
        },
      ),
    );
  }

  Future<void> _loadFallbackVideoSources() async {
    await _pluginManager.init();
  }

  @override
  void reassemble() {
    super.reassemble();
    unawaited(Future<void>(() async {
      _controller.syncAfterReassemble();
    }));
  }

  @override
  void dispose() {
    _controller.saveHistory();
    unawaited(_controller.dispose());
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    _tabController.dispose();
    _danmakuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableHeight =
        MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top;
    final videoHeight = math.min(
      MediaQuery.of(context).size.width / (16 / 9),
      availableHeight,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Theme.of(context).scaffoldBackgroundColor,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: Theme.of(context).brightness,
      ),
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) {
            unawaited(_controller.disposePlaybackService());
          }
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          resizeToAvoidBottomInset: true,
          body: Column(
            children: [
              Container(
                height: MediaQuery.of(context).padding.top,
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              Expanded(
                child: Column(
                  children: [
                    ValueListenableBuilder<VideoPlayerViewState>(
                      valueListenable: _controller.playerViewNotifier,
                      builder: (context, playerState, _) {
                        return ValueListenableBuilder<Duration?>(
                          valueListenable: _controller.initialProgressNotifier,
                          builder: (context, initialProgress, _) {
                            return VideoPlayerArea(
                              videoHeight: videoHeight,
                              videoUrl: playerState.resolvedVideoUrl,
                              title: widget.title,
                              currentEpisode: playerState.currentEpisodeNumber,
                              totalEpisodes: playerState.totalEpisodes,
                              playerController: _controller.playbackService,
                              episodeTitle: playerState.currentEpisodeTitle,
                              onNextEpisode: playerState.hasNextEpisode
                                  ? _controller.playNextEpisode
                                  : null,
                              onPreviousEpisode: playerState.hasPreviousEpisode
                                  ? _controller.playPreviousEpisode
                                  : null,
                              hasNextEpisode: playerState.hasNextEpisode,
                              hasPreviousEpisode:
                                  playerState.hasPreviousEpisode,
                              initialProgress: initialProgress,
                              episodes: playerState.episodes,
                              onEpisodeSelected: _controller.playEpisode,
                              isLoadingEpisodes:
                                  playerState.isEpisodeListLoading,
                              isDescending:
                                  playerState.isEpisodeSortDescending,
                              onToggleSort: _controller.toggleEpisodeSort,
                              isDanmakuEnabled: playerState.isDanmakuEnabled,
                              animeTitle: widget.animeTitle,
                              bangumiId: widget.bangumiId,
                              onDanmakuToggle: _setDanmakuEnabled,
                              isLoading: playerState.isResolvingVideo,
                              hasError: playerState.hasPlaybackError,
                              showTimeoutHint: playerState.showTimeoutNotice,
                              onRetry: _controller.resolveCurrentVideoUrl,
                            );
                          },
                        );
                      },
                    ),
                    Expanded(
                      child: Container(
                        color: Theme.of(context).cardColor,
                        child: Column(
                          children: [
                            ValueListenableBuilder<VideoDanmakuViewState>(
                              valueListenable: _controller.danmakuViewNotifier,
                              builder: (context, danmakuState, _) {
                                return ValueListenableBuilder<VideoSourceViewState>(
                                  valueListenable: _controller.sourceViewNotifier,
                                  builder: (context, sourceState, _) {
                                    return VideoTab(
                                      tabController: _tabController,
                                      isDanmakuEnabled:
                                          danmakuState.isDanmakuEnabled,
                                      isDanmakuInputExpanded:
                                          danmakuState.isInputExpanded,
                                      onDanmakuToggle: () {
                                        _setDanmakuEnabled(
                                          !danmakuState.isDanmakuEnabled,
                                        );
                                      },
                                      onDanmakuInputTap:
                                          _controller.expandDanmakuInput,
                                      onVideoSourceTap: _showVideoSourceSelector,
                                      currentPluginName:
                                          sourceState.currentSourceName,
                                    );
                                  },
                                );
                              },
                            ),
                            Expanded(
                              child: ValueListenableBuilder<VideoDanmakuViewState>(
                                valueListenable: _controller.danmakuViewNotifier,
                                builder: (context, danmakuState, _) {
                                  return ValueListenableBuilder<VideoEpisodeViewState>(
                                    valueListenable: _controller.episodeViewNotifier,
                                    builder: (context, episodeState, _) {
                                      return TabBarView(
                                        controller: _tabController,
                                        physics: danmakuState.isDanmakuEnabled
                                            ? const NeverScrollableScrollPhysics()
                                            : null,
                                        children: [
                                          EpiscodeTabContent(
                                            isLoading: episodeState.isLoading,
                                            episodes: episodeState.episodes,
                                            isDescending: episodeState.isDescending,
                                            isEpisodesExpanded:
                                                episodeState.isExpanded,
                                            currentEpisode:
                                                episodeState.currentEpisodeNumber,
                                            onEpisodeSelected:
                                                _controller.playEpisode,
                                            onToggleExpand:
                                                _controller.toggleEpisodeListExpanded,
                                            onToggleSort:
                                                _controller.toggleEpisodeSort,
                                          ),
                                          const CommentTabContent.VideoComment(),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            ValueListenableBuilder<VideoDanmakuViewState>(
                              valueListenable: _controller.danmakuViewNotifier,
                              builder: (context, danmakuState, _) {
                                if (!danmakuState.isInputExpanded) {
                                  return const SizedBox.shrink();
                                }
                                return DanmakuInputBar(
                                  controller: _danmakuController,
                                  onSend: () {
                                    if (_danmakuController.text.isNotEmpty) {
                                    _clearDanmakuInput();
                                    }
                                  },
                                  onClose: () {
                                    _controller.collapseDanmakuInput();
                                    _danmakuController.clear();
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
