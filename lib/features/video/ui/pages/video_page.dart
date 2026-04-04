import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mikomi/features/video/ui/widgets/danmaku_overlay.dart';
import 'package:mikomi/features/video/ui/widgets/comment_tab_content.dart';
import 'package:mikomi/features/video/ui/widgets/video_tab.dart';
import 'package:mikomi/features/anime/selector/video_source_selector.dart';
import 'package:mikomi/features/settings/video_play/service/plugin_manager_service.dart';
import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/services/video_playback_service.dart';
import 'package:mikomi/features/settings/danmaku/danmaku_setting_service.dart';
import 'package:mikomi/features/video/state/video_state_manager.dart';
import 'package:mikomi/features/video/services/video_page_service.dart';
import 'package:mikomi/features/video/ui/widgets/video_player_area.dart';
import 'package:mikomi/features/video/ui/widgets/episcode_tab_content.dart';

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
  });

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late VideoStateManager _state;
  late VideoPageService _pageService;
  late VideoPlaybackService _playerController;

  final TextEditingController _danmakuController = TextEditingController();
  final VideoPluginManager _pluginManager = VideoPluginManager();

  Timer? _timeoutTimer;
  Timer? _saveHistoryTimer;
  Duration? _currentInitialProgress;

  @override
  void initState() {
    super.initState();
    _pageService = VideoPageService();
    _playerController = VideoPlaybackService();
    _state = _pageService.initializeState(
      currentEpisode: widget.currentEpisode,
      episodes: widget.episodes,
      videoUrl: widget.videoUrl,
      pluginName: widget.pluginName,
    );
    _currentInitialProgress = widget.initialProgress;

    _tabController = TabController(length: 2, vsync: this);

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );

    DanmakuSettingService().getShowDanmaku().then((v) {
      if (!mounted) return;
      setState(() {
        _state = _pageService.updateDanmakuEnabled(_state, v);
      });
    });

    final initResult = _pageService.initializeVideoUrl(
      state: _state,
      animeTitle: widget.animeTitle,
    );
    _state = initResult.state;

    _setupTimers();
    if (initResult.shouldLoadEpisodes) {
      _loadEpisodesIfNeeded();
    } else if (_state.isResolvingVideo) {
      unawaited(_resolveCurrentVideoUrl());
    }
    _loadFallbackVideoSources();
  }

  void _setupTimers() {
    final handles = _pageService.startTimers(
      onTimeout: () {
        if (!mounted) return;
        setState(() {
          _state = _pageService.showTimeoutHint(_state);
        });
      },
      onSaveHistory: _saveHistoryModel,
    );
    _timeoutTimer = handles.timeoutTimer;
    _saveHistoryTimer = handles.saveHistoryTimer;
  }

  void _restartTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = _pageService.restartTimeoutTimer(
      onTimeout: () {
        if (!mounted) return;
        setState(() {
          _state = _pageService.showTimeoutHint(_state);
        });
      },
    );
  }

  void _loadEpisodesIfNeeded() {
    if (_state.episodes.isEmpty && _state.currentPluginName != null) {
      setState(() {
        _state = _pageService.beginEpisodeLoading(_state);
      });
      unawaited(_loadEpisodesInBackground());
    }
  }

  Future<void> _loadEpisodesInBackground() async {
    try {
      final result = await _pageService.loadEpisodesInBackground(
        state: _state,
        animeTitle: widget.animeTitle,
        animeName: widget.animeName,
        bangumiId: widget.bangumiId,
      );
      if (!mounted) return;
      setState(() {
        _state = result.state;
      });
      if (result.shouldRefreshParsedUrlSilently) {
        await _refreshParsedUrlSilently();
      } else if (result.shouldUpdateCurrentVideoUrl) {
        await _resolveCurrentVideoUrl();
      }
    } finally {
      if (mounted) {
        setState(() {
          _state = _pageService.endEpisodeLoading(_state);
        });
      }
    }
  }

  Future<void> _refreshParsedUrlSilently() async {
    final nextState = await _pageService.refreshParsedUrlSilently(_state);
    if (!mounted || identical(nextState, _state)) {
      return;
    }
    setState(() {
      _state = nextState;
    });
  }

  Future<void> _resolveCurrentVideoUrl() async {
    setState(() {
      _state = _pageService.resetResolveState(_state);
    });
    _restartTimeoutTimer();
    final nextState = await _pageService.resolveCurrentVideoUrl(_state);
    if (!mounted) return;
    setState(() {
      _state = nextState;
    });
  }

  Future<void> _playEpisode(Episode episode) async {
    final nextState = _pageService.playEpisode(_state, episode);
    if (nextState == null) return;
    _saveHistoryModel();
    await _playerController.stop();
    if (!mounted) return;
    setState(() {
      _state = nextState;
      _currentInitialProgress = null;
    });
    await _resolveCurrentVideoUrl();
  }

  Future<void> _playNextEpisode() async {
    final ep = _pageService.getNextEpisode(_state);
    if (ep == null) return;
    await _playEpisode(ep);
  }

  Future<void> _playPreviousEpisode() async {
    final ep = _pageService.getPreviousEpisode(_state);
    if (ep == null) return;
    await _playEpisode(ep);
  }

  Future<void> _switchVideoSource(VideoSource source) async {
    setState(() {
      _state = _pageService.beginSourceSwitch(_state);
      _currentInitialProgress = null;
    });
    await _playerController.stop();
    try {
      final result = await _pageService.switchVideoSource(
        state: _state,
        source: source,
        animeTitle: widget.animeTitle,
        animeName: widget.animeName,
        bangumiId: widget.bangumiId,
      );
      if (!mounted) return;
      setState(() {
        _state = result.state;
      });
      await _resolveCurrentVideoUrl();
    } finally {
      if (mounted) {
        setState(() {
          _state = _pageService.endEpisodeLoading(_state);
        });
      }
    }
  }

  void _showVideoSourceSelector() {
    final sources =
        (widget.videoSources != null && widget.videoSources!.isNotEmpty)
        ? widget.videoSources!
        : <VideoSource>[];
    if (sources.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('���޿�����ƵԴ')));
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
          _switchVideoSource(source);
        },
      ),
    );
  }

  Future<void> _loadFallbackVideoSources() async {
    await _pluginManager.init();
  }

  void _saveHistoryModel() {
    _pageService.saveHistoryModel(
      bangumiId: widget.bangumiId,
      title: widget.title,
      animeTitle: widget.animeTitle,
      state: _state,
      playerController: _playerController,
    );
  }

  Future<void> _handleReassemble() async {
    if (_state.isReassembling) return;
    setState(() {
      _state = _pageService.beginReassemble(_state);
    });
    try {
      await _playerController.stop();
      await Future.delayed(const Duration(milliseconds: 80));
      if (mounted) {
        await _resolveCurrentVideoUrl();
      }
    } finally {
      if (mounted) {
        setState(() {
          _state = _pageService.endReassemble(_state);
        });
      }
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    unawaited(_handleReassemble());
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _saveHistoryTimer?.cancel();
    _saveHistoryModel();
    try {
      _playerController.dispose();
    } catch (e) {
      debugPrint('�ͷŲ�����ʧ��: $e');
    }
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
    final videoUrl = _state.resolvedVideoUrl;
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
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) {
            try {
              await _playerController.dispose();
            } catch (e) {
              debugPrint('$e');
            }
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
                    VideoPlayerArea(
                      videoHeight: videoHeight,
                      videoUrl: videoUrl,
                      title: widget.title,
                      currentEpisode: _state.currentEpisode,
                      totalEpisodes: _state.totalEpisodes,
                      playerController: _playerController,
                      episodeTitle: _state.currentEpisodeTitle,
                      onNextEpisode: _state.hasNextEpisode
                          ? _playNextEpisode
                          : null,
                      onPreviousEpisode: _state.hasPreviousEpisode
                          ? _playPreviousEpisode
                          : null,
                      hasNextEpisode: _state.hasNextEpisode,
                      hasPreviousEpisode: _state.hasPreviousEpisode,
                      initialProgress: _currentInitialProgress,
                      episodes: _state.episodes,
                      onEpisodeSelected: _playEpisode,
                      isLoadingEpisodes: _state.isLoadingEpisodes,
                      isDescending: _state.isDescending,
                      onToggleSort: () {
                        setState(() {
                          _state = _pageService.toggleEpisodeSort(_state);
                        });
                      },
                      isDanmakuEnabled: _state.isDanmakuEnabled,
                      animeTitle: widget.animeTitle,
                      bangumiId: widget.bangumiId,
                      onDanmakuToggle: (enabled) {
                        setState(() {
                          _state = _pageService.updateDanmakuEnabled(
                            _state,
                            enabled,
                          );
                        });
                        if (!enabled) {
                          _danmakuController.clear();
                        }
                        DanmakuSettingService().setShowDanmaku(enabled);
                      },
                      isLoading: _state.isResolvingVideo,
                      hasError: _state.hasParseError,
                      showTimeoutHint: _state.showTimeoutHint,
                      onRetry: _resolveCurrentVideoUrl,
                    ),
                    Expanded(
                      child: Container(
                        color: Theme.of(context).cardColor,
                        child: Column(
                          children: [
                            VideoTab(
                              tabController: _tabController,
                              isDanmakuEnabled: _state.isDanmakuEnabled,
                              isDanmakuInputExpanded:
                                  _state.isDanmakuInputExpanded,
                              onDanmakuToggle: () {
                                final enabled = !_state.isDanmakuEnabled;
                                setState(() {
                                  _state = _pageService.updateDanmakuEnabled(
                                    _state,
                                    enabled,
                                  );
                                });
                                if (!enabled) {
                                  _danmakuController.clear();
                                }
                                DanmakuSettingService().setShowDanmaku(enabled);
                              },
                              onDanmakuInputTap: () {
                                setState(() {
                                  _state = _pageService.expandDanmakuInput(
                                    _state,
                                  );
                                });
                              },
                              onVideoSourceTap: _showVideoSourceSelector,
                              currentPluginName: _state.currentPluginName,
                            ),
                            Expanded(
                              child: TabBarView(
                                controller: _tabController,
                                physics: _state.isDanmakuEnabled
                                    ? const NeverScrollableScrollPhysics()
                                    : null,
                                children: [
                                  EpiscodeTabContent(
                                    isLoading: _state.isLoadingEpisodes,
                                    episodes: _state.episodes,
                                    isDescending: _state.isDescending,
                                    isEpisodesExpanded:
                                        _state.isEpisodesExpanded,
                                    currentEpisode: _state.currentEpisode,
                                    onEpisodeSelected: _playEpisode,
                                    onToggleExpand: () {
                                      setState(() {
                                        _state = _pageService
                                            .toggleEpisodeExpand(_state);
                                      });
                                    },
                                    onToggleSort: () {
                                      setState(() {
                                        _state = _pageService.toggleEpisodeSort(
                                          _state,
                                        );
                                      });
                                    },
                                  ),
                                  const CommentTabContent.VideoComment(),
                                ],
                              ),
                            ),
                            if (_state.isDanmakuInputExpanded)
                              DanmakuInputBar(
                                controller: _danmakuController,
                                onSend: () {
                                  if (_danmakuController.text.isNotEmpty) {
                                    _danmakuController.clear();
                                  }
                                },
                                onClose: () {
                                  setState(() {
                                    _state = _pageService.collapseDanmakuInput(
                                      _state,
                                    );
                                  });
                                  _danmakuController.clear();
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
