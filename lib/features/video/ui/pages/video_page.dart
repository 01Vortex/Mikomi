import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mikomi/features/anime/selector/video_source_selector.dart';
import 'package:mikomi/features/settings/danmaku/danmaku_setting_service.dart';
import 'package:mikomi/features/video/controller/video_page_controller.dart';
import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/state/video_page_state.dart';
import 'package:mikomi/features/video/ui/widgets/player/fullscreen_danmaku.dart';
import 'package:mikomi/features/video/ui/widgets/video_player_section.dart';
import 'package:mikomi/features/video/ui/widgets/video_tabs_section.dart';

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
  late final VideoPageController _controller;

  final TextEditingController _danmakuController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = VideoPageController(
      title: widget.title,
      videoUrl: widget.videoUrl,
      currentEpisode: widget.currentEpisode,
      episodes: widget.episodes,
      videoSources: widget.videoSources ?? const [],
      sourceName: widget.sourceName,
      initialProgress: widget.initialProgress,
      animeTitle: widget.animeTitle,
      animeName: widget.animeName,
      bangumiId: widget.bangumiId,
    );
    _tabController = TabController(length: 2, vsync: this);
    unawaited(_controller.initialize());
  }

  Future<void> _setDanmakuEnabled(bool enabled) async {
    await _controller.setDanmakuEnabled(enabled);
    if (!enabled) _danmakuController.clear();
  }

  Future<void> _handleDanmakuConfigChanged(DanmakuConfig config) async {
    await _controller.updateDanmakuConfig(config);
    if (!mounted) return;
    setState(() {});
  }

  void _showVideoSourceSelector() {
    if (!_controller.hasVideoSources) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无可用视频源')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => VideoSourceSelector(
        sources: _controller.videoSources,
        animeTitle: _controller.state.animeTitle,
        onSourceSelected: (source) {
          Navigator.pop(context);
          _controller.switchVideoSource(source);
        },
      ),
    );
  }

  void _showDanmakuSettings() {
    final state = _controller.state;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FullscreenDanmakuSettings(
        initialConfig: state.danmakuConfig,
        onConfigChanged: (config) {
          unawaited(_controller.updateDanmakuConfig(config));
        },
      ),
    );
  }

  @override
  void reassemble() {
    super.reassemble();
    _controller.syncAfterReassemble();
  }

  void _onPopInvoked(bool didPop, _) {
    if (didPop) unawaited(_controller.handlePagePop());
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
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
        onPopInvokedWithResult: _onPopInvoked,
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
                  valueListenable: _controller.stateListenable,
                  builder: (context, pageState, _) {
                    return Column(
                      children: [
                        VideoPlayerSection(
                          pageState: pageState,
                          videoHeight: videoHeight,
                          onDanmakuToggle: _setDanmakuEnabled,
                          controller: _controller,
                        ),
                        Expanded(
                          child: VideoTabsSection(
                            pageState: pageState,
                            tabController: _tabController,
                            danmakuController: _danmakuController,
                            onDanmakuToggle: _setDanmakuEnabled,
                            onVideoSourceTap: _showVideoSourceSelector,
                            onDanmakuSettingsTap: _showDanmakuSettings,
                            onDanmakuConfigChanged: _handleDanmakuConfigChanged,
                            controller: _controller,
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
