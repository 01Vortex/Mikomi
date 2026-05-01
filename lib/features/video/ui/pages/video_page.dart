import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mikomi/features/anime/selector/video_source_selector.dart';
import 'package:mikomi/features/video/facade/video_page_facade.dart';
import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/state/video_page_state.dart';
import 'package:mikomi/features/video/ui/widgets/danmaku_overlay.dart';
import 'package:mikomi/features/video/ui/widgets/episcode_tab_content.dart';
import 'package:mikomi/features/video/ui/widgets/fullscreen/fullscreen_danmaku_settings.dart';
import 'package:mikomi/features/video/ui/widgets/smallscreen/smallscreen_area.dart';
import 'package:mikomi/features/video/ui/widgets/video_tab.dart';

class VideoPage extends StatefulWidget {
  final String title;
  final String videoUrl;
  final int currentEpisode;
  final List<Episode> episodes;
  final List<VideoSource>? videoSources;
  final String? sourceName;
  final String? animeTitle;
  final String? animeName;
  final int? bangumiId;
  final String? coverUrl;
  final Duration? initialProgress;

  const VideoPage({
    super.key,
    required this.title,
    required this.videoUrl,
    this.currentEpisode = 1,
    required this.episodes,
    this.videoSources,
    this.sourceName,
    this.animeTitle,
    this.animeName,
    this.bangumiId,
    this.coverUrl,
    this.initialProgress,
  });

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final VideoPageFacade _facade;

  final TextEditingController _danmakuController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _facade = VideoPageFacade(
      title: widget.title,
      videoUrl: widget.videoUrl,
      currentEpisode: widget.currentEpisode,
      episodes: widget.episodes,
      videoSources: widget.videoSources,
      sourceName: widget.sourceName,
      initialProgress: widget.initialProgress,
      animeTitle: widget.animeTitle,
      animeName: widget.animeName,
      bangumiId: widget.bangumiId,
    );
    _tabController = TabController(length: 2, vsync: this);
    unawaited(_facade.initializePage());
  }

  Future<void> _setDanmakuEnabled(bool enabled) async {
    await _facade.setDanmakuEnabled(enabled);
    if (!enabled) _danmakuController.clear();
  }

  Future<void> _handleDanmakuConfigChanged(
    VideoPageDanmakuConfig config,
  ) async {
    await _facade.updateDanmakuConfig(config);
    if (!mounted) return;
    setState(() {});
  }

  void _showVideoSourceSelector() {
    if (!_facade.hasVideoSources) {
      if (!mounted) return;
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
        sources: _facade.videoSources,
        animeTitle: _facade.state.animeTitle,
        onSourceSelected: (source) {
          Navigator.pop(context);
          _facade.switchVideoSource(source);
        },
      ),
    );
  }

  @override
  void reassemble() {
    super.reassemble();
    _facade.syncAfterReassemble();
  }

  @override
  void dispose() {
    unawaited(_facade.disposePage());
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
          if (didPop) unawaited(_facade.handlePagePop());
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
                child: ValueListenableBuilder<VideoPageState>(
                  valueListenable: _facade.stateListenable,
                  builder: (context, pageState, _) {
                    return Column(
                      children: [
                        _VideoPlayerSection(
                          pageState: pageState,
                          videoHeight: videoHeight,
                          onDanmakuToggle: _setDanmakuEnabled,
                          facade: _facade,
                        ),
                        Expanded(
                          child: _VideoTabsSection(
                            pageState: pageState,
                            tabController: _tabController,
                            danmakuController: _danmakuController,
                            onDanmakuToggle: _setDanmakuEnabled,
                            onVideoSourceTap: _showVideoSourceSelector,
                            onDanmakuConfigChanged: _handleDanmakuConfigChanged,
                            facade: _facade,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoPlayerSection extends StatelessWidget {
  final VideoPageState pageState;
  final double videoHeight;
  final Future<void> Function(bool enabled) onDanmakuToggle;
  final VideoPageFacade facade;

  const _VideoPlayerSection({
    required this.pageState,
    required this.videoHeight,
    required this.onDanmakuToggle,
    required this.facade,
  });

  @override
  Widget build(BuildContext context) {
    final player = pageState.player;
    return VideoPlayerArea(
      videoHeight: videoHeight,
      videoUrl: player.resolvedVideoUrl,
      title: pageState.title,
      currentEpisode: player.currentEpisodeNumber,
      totalEpisodes: player.totalEpisodes,
      playbackService: pageState.playbackService,
      currentSmallTitle: player.currentSmallTitle,
      onNextEpisode: player.hasNextEpisode ? facade.playNextEpisode : null,
      onPreviousEpisode: player.hasPreviousEpisode
          ? facade.playPreviousEpisode
          : null,
      hasNextEpisode: player.hasNextEpisode,
      hasPreviousEpisode: player.hasPreviousEpisode,
      initialProgress: pageState.initialProgress,
      episodes: player.episodes,
      onEpisodeSelected: facade.playEpisode,
      isLoadingEpisodes: player.isEpisodeListLoading,
      isDescending: player.isEpisodeSortDescending,
      onToggleSort: facade.toggleEpisodeSort,
      isDanmakuEnabled: player.isDanmakuEnabled,
      animeTitle: pageState.animeTitle,
      bangumiId: pageState.bangumiId,
      onDanmakuToggle: onDanmakuToggle,
      isLoading: player.isResolvingVideo,
      hasError: player.hasPlaybackError,
      showTimeoutHint: player.showTimeoutNotice,
      onRetry: facade.retryResolveVideoUrl,
    );
  }
}

class _VideoTabsSection extends StatelessWidget {
  final VideoPageState pageState;
  final TabController tabController;
  final TextEditingController danmakuController;
  final Future<void> Function(bool enabled) onDanmakuToggle;
  final VoidCallback onVideoSourceTap;
  final Future<void> Function(VideoPageDanmakuConfig config)
  onDanmakuConfigChanged;
  final VideoPageFacade facade;

  const _VideoTabsSection({
    required this.pageState,
    required this.tabController,
    required this.danmakuController,
    required this.onDanmakuToggle,
    required this.onVideoSourceTap,
    required this.onDanmakuConfigChanged,
    required this.facade,
  });

  @override
  Widget build(BuildContext context) {
    final danmaku = pageState.danmaku;
    final episode = pageState.episode;
    return Container(
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          VideoTab(
            tabController: tabController,
            isDanmakuEnabled: danmaku.isDanmakuEnabled,
            isDanmakuInputExpanded: danmaku.isInputExpanded,
            onDanmakuToggle: () {
              onDanmakuToggle(!danmaku.isDanmakuEnabled);
            },
            onDanmakuInputTap: facade.expandDanmakuInput,
            onVideoSourceTap: onVideoSourceTap,
            currentSourceName: pageState.source.currentSourceName,
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              physics: danmaku.isDanmakuEnabled
                  ? const NeverScrollableScrollPhysics()
                  : null,
              children: [
                EpisodeTabContent(
                  isLoading: episode.isLoading,
                  episodes: episode.episodes,
                  isDescending: episode.isDescending,
                  isEpisodesExpanded: episode.isExpanded,
                  currentEpisode: episode.currentEpisodeNumber,
                  onEpisodeSelected: facade.playEpisode,
                  onToggleExpand: facade.toggleEpisodeListExpanded,
                  onToggleSort: facade.toggleEpisodeSort,
                ),
                FullscreenDanmakuSettings(
                  onConfigChanged: onDanmakuConfigChanged,
                ),
              ],
            ),
          ),
          if (danmaku.isInputExpanded)
            DanmakuInputBar(
              controller: danmakuController,
              onSend: () {
                if (danmakuController.text.isNotEmpty) {
                  danmakuController.clear();
                }
              },
              onClose: () {
                facade.collapseDanmakuInput();
                danmakuController.clear();
              },
            ),
        ],
      ),
    );
  }
}
