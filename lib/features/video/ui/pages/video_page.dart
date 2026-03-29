import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mikomi/features/video/ui/widgets/danmaku_overlay.dart';
import 'package:mikomi/features/video/ui/widgets/smallscreen_video.dart';
import 'package:mikomi/features/video/ui/widgets/video_comment.dart';
import 'package:mikomi/features/video/ui/widgets/video_tab.dart';
import 'package:mikomi/features/video/ui/widgets/smallscreen_episcode.dart';
import 'package:mikomi/features/anime/selector/video_source_selector.dart';
import 'package:mikomi/features/settings/video_play/service/plugin_manager_service.dart';
import 'package:mikomi/shared/widgets/skeleton.dart';
import 'package:mikomi/core/models/episode.dart';
import 'package:mikomi/core/services/bangumi_episodes_service.dart';
import 'package:mikomi/features/video/services/video_content_service.dart';
import 'package:mikomi/features/video/services/video_source_provider.dart'
    show CaptchaRequiredException, VideoSourceCancelledException;
import 'package:mikomi/features/video/services/video_playback_service.dart';
import 'package:mikomi/core/services/watch_history_service.dart';
import 'package:mikomi/core/models/watch_history.dart';
import 'package:mikomi/shared/widgets/message_dialog.dart';

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
  int _currentEpisode = 1;
  List<Episode> _episodes = [];
  String _videoUrl = '';
  bool _isLoadingEpisodes = false;
  String? _currentPluginName;
  bool _isDescending = false;
  bool _isDanmakuEnabled = false;
  bool _isDanmakuInputExpanded = false;
  bool _isEpisodesExpanded = true;
  List<VideoSource> _fallbackVideoSources = [];
  final TextEditingController _danmakuController = TextEditingController();
  final BangumiEpisodesService _episodesService = BangumiEpisodesService();
  final VideoContentService _videoSourceRepo = VideoContentService();
  final VideoPluginManager _pluginManager = VideoPluginManager();
  final WatchHistoryService _historyService = WatchHistoryService();

  late final VideoPlaybackService _playerController;
  Future<String>? _currentVideoUrlFuture;
  bool _showTimeoutHint = false;
  bool _hasParseError = false;
  Timer? _timeoutTimer;
  Timer? _saveHistoryTimer;
  Duration? _currentInitialProgress;
  bool _isReassembling = false;
  bool _shouldParseAfterEpisodesLoaded = false;
  bool _isUsingCachedPlayUrl = false;
  String _lastResolvedVideoUrl = '';

  @override
  void initState() {
    super.initState();
    _currentEpisode = widget.currentEpisode;
    _episodes = widget.episodes;
    _videoUrl = widget.videoUrl;
    _currentPluginName = widget.pluginName;
    _tabController = TabController(length: 2, vsync: this);
    _currentInitialProgress = widget.initialProgress;
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    _playerController = VideoPlaybackService();

    if (_episodes.isEmpty && _currentPluginName != null && widget.animeTitle != null) {
      if (_videoUrl.isNotEmpty) {
        if (_isDirectStreamUrl(_videoUrl)) {
          _isUsingCachedPlayUrl = true;
          _shouldParseAfterEpisodesLoaded = true;
          _lastResolvedVideoUrl = _videoUrl;
          _currentVideoUrlFuture = Future.value(_videoUrl);
        } else {
          _currentVideoUrlFuture = _getCurrentVideoUrl();
        }
      } else {
        _shouldParseAfterEpisodesLoaded = true;
        _currentVideoUrlFuture = Future.value('');
      }
    } else {
      _currentVideoUrlFuture = _getCurrentVideoUrl();
    }
    _timeoutTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showTimeoutHint = true);
    });
    if (_episodes.isEmpty && _currentPluginName != null) {
      _isLoadingEpisodes = true; // 同步设置，确保第一帧 isLoading 为 true
      _loadEpisodesInBackground();
    }
    _saveHistoryTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _saveWatchHistory();
    });
    _loadFallbackVideoSources();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Theme.of(context).scaffoldBackgroundColor,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: Theme.of(context).brightness,
      ),
    );
  }

  Future<void> _handleReassemble() async {
    if (_isReassembling) return;
    _isReassembling = true;
    try {
      await _playerController.stop();
      await Future.delayed(const Duration(milliseconds: 80));
      if (mounted) _updateCurrentVideoUrl();
    } finally {
      _isReassembling = false;
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    unawaited(_handleReassemble());
  }

  bool _isDirectStreamUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.m3u8') || lower.contains('.mp4');
  }

  Future<void> _refreshParsedUrlSilently() async {
    if (_currentPluginName == null || _episodes.isEmpty) return;
    try {
      final pageUrl =
          _episodes.firstWhere((ep) => ep.number == _currentEpisode).url ?? _videoUrl;
      final parsedUrl = await _videoSourceRepo.parseVideoUrl(pageUrl, _currentPluginName!);
      if (!mounted || parsedUrl.isEmpty || parsedUrl == _lastResolvedVideoUrl) return;
      _lastResolvedVideoUrl = parsedUrl;
      setState(() => _currentVideoUrlFuture = Future.value(parsedUrl));
    } catch (e) {
      debugPrint('静默刷新失败: $e');
    }
  }

  void _updateCurrentVideoUrl() {
    _videoSourceRepo.cancelVideoParsing();
    setState(() {
      _showTimeoutHint = false;
      _hasParseError = false;
      _currentVideoUrlFuture = _getCurrentVideoUrl();
    });
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showTimeoutHint = true);
    });
  }

  Future<void> _loadEpisodesInBackground() async {
    try {
      if (widget.animeTitle != null && _currentPluginName != null) {
        await _loadEpisodesWithVideoSource(_currentPluginName!);
      } else if (widget.bangumiId != null) {
        await _loadBangumiEpisodes();
      }
    } catch (e) {
      debugPrint('后台加载剧集失败: $e');
    } finally {
      if (mounted) setState(() => _isLoadingEpisodes = false);
    }
  }

  Future<void> _loadEpisodesWithVideoSource(String pluginName) async {
    if (widget.animeTitle == null) return;
    try {
      var videoEpisodes = await _videoSourceRepo
          .searchAndGetEpisodes(widget.animeTitle!, pluginName)
          .timeout(const Duration(seconds: 60), onTimeout: () => []);
      if (videoEpisodes.isEmpty && widget.animeName != null && widget.animeName != widget.animeTitle) {
        videoEpisodes = await _videoSourceRepo
            .searchAndGetEpisodes(widget.animeName!, pluginName)
            .timeout(const Duration(seconds: 60), onTimeout: () => []);
      }
      if (videoEpisodes.isEmpty) return;
      List<Episode>? bangumiEpisodes;
      if (widget.bangumiId != null) {
        try {
          bangumiEpisodes = await _episodesService
              .getEpisodesBySubjectId(widget.bangumiId!)
              .timeout(const Duration(seconds: 15), onTimeout: () => []);
        } catch (e) {
          debugPrint('获取Bangumi剧集失败: $e');
        }
      }
      final mergedEpisodes = <Episode>[];
      for (int i = 0; i < videoEpisodes.length; i++) {
        final videoEp = videoEpisodes[i];
        String? title = videoEp.title;
        if (bangumiEpisodes != null && i < bangumiEpisodes.length) {
          title = bangumiEpisodes[i].title;
        }
        mergedEpisodes.add(Episode(number: videoEp.number, title: title, url: videoEp.url));
      }
      if (mounted && mergedEpisodes.isNotEmpty) {
        setState(() {
          _episodes = mergedEpisodes;
          if (_currentEpisode > mergedEpisodes.length) _currentEpisode = 1;
        });
        if (_shouldParseAfterEpisodesLoaded) {
          _shouldParseAfterEpisodesLoaded = false;
          if (_isUsingCachedPlayUrl) {
            _isUsingCachedPlayUrl = false;
            unawaited(_refreshParsedUrlSilently());
          } else {
            _updateCurrentVideoUrl();
          }
        }
      }
    } on CaptchaRequiredException catch (e) {
      debugPrint('验证码: $e');
      if (mounted) MessageDialog.warning(context, '当前视频源需要验证码验证');
    } catch (e) {
      debugPrint('加载视频源剧集失败: $e');
    }
  }

  Future<void> _loadBangumiEpisodes() async {
    if (widget.bangumiId == null) return;
    try {
      final episodes = await _episodesService
          .getEpisodesBySubjectId(widget.bangumiId!)
          .timeout(const Duration(seconds: 10), onTimeout: () => []);
      if (mounted && episodes.isNotEmpty) setState(() => _episodes = episodes);
    } catch (e) {
      debugPrint('加载Bangumi剧集失败: $e');
    }
  }

  int get _totalEpisodes => _episodes.length;

  String? get _currentEpisodeTitle {
    try {
      return _episodes.firstWhere((ep) => ep.number == _currentEpisode).title;
    } catch (_) {
      return null;
    }
  }

  bool get _hasNextEpisode => _currentEpisode < _totalEpisodes;
  bool get _hasPreviousEpisode => _currentEpisode > 1;

  Future<void> _playEpisode(Episode episode) async {
    if (episode.number == _currentEpisode) return;
    _saveWatchHistory();
    await _playerController.stop();
    if (!mounted) return;
    setState(() {
      _currentEpisode = episode.number;
      _currentInitialProgress = null;
    });
    _updateCurrentVideoUrl();
  }

  Future<void> _playNextEpisode() async {
    if (!_hasNextEpisode) return;
    final ep = _episodes.firstWhere(
      (e) => e.number == _currentEpisode + 1,
      orElse: () => Episode(number: _currentEpisode + 1),
    );
    await _playEpisode(ep);
  }

  Future<void> _playPreviousEpisode() async {
    if (!_hasPreviousEpisode) return;
    final ep = _episodes.firstWhere(
      (e) => e.number == _currentEpisode - 1,
      orElse: () => Episode(number: _currentEpisode - 1),
    );
    await _playEpisode(ep);
  }

  Future<String> _getCurrentVideoUrl() async {
    try {
      if (_episodes.isEmpty) {
        if (_isDirectStreamUrl(_videoUrl)) {
          _lastResolvedVideoUrl = _videoUrl;
          return _videoUrl;
        }
        if (_currentPluginName != null && _videoUrl.isNotEmpty) {
          final parsed = await _videoSourceRepo.parseVideoUrl(_videoUrl, _currentPluginName!);
          _lastResolvedVideoUrl = parsed;
          return parsed;
        }
        _lastResolvedVideoUrl = _videoUrl;
        return _videoUrl;
      }
      final url = _episodes.firstWhere((ep) => ep.number == _currentEpisode).url ?? _videoUrl;
      if (_currentPluginName != null) {
        final parsed = await _videoSourceRepo.parseVideoUrl(url, _currentPluginName!);
        _lastResolvedVideoUrl = parsed;
        return parsed;
      }
      _lastResolvedVideoUrl = url;
      return url;
    } on VideoSourceCancelledException {
      return '';
    } catch (e) {
      debugPrint('获取视频URL失败: $e');
      if (mounted) setState(() => _hasParseError = true);
      rethrow;
    }
  }

  Future<void> _switchVideoSource(VideoSource source) async {
    _videoSourceRepo.cancelVideoParsing();
    await _playerController.stop();
    setState(() {
      _currentPluginName = source.name;
      _isLoadingEpisodes = true;
      _currentInitialProgress = null;
    });
    try {
      await _loadEpisodesWithVideoSource(source.name);
      if (mounted) _updateCurrentVideoUrl();
    } finally {
      if (mounted) setState(() => _isLoadingEpisodes = false);
    }
  }

  List<Episode> get _sortedEpisodes =>
      _isDescending ? _episodes.reversed.toList() : _episodes;

  void _showVideoSourceSelector() {
    final sources = (widget.videoSources != null && widget.videoSources!.isNotEmpty)
        ? widget.videoSources!
        : _fallbackVideoSources;
    if (sources.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('暂无可用视频源')));
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
    if (!mounted) return;
    setState(() {
      _fallbackVideoSources = _pluginManager.plugins
          .map((p) => VideoSource(name: p.name))
          .toList();
    });
  }

  void _saveWatchHistory() {
    if (widget.bangumiId == null || widget.title.isEmpty) return;
    if (_playerController.player == null || !_playerController.isInitialized) return;
    try {
      final progress = _playerController.player!.state.position;
      final duration = _playerController.player!.state.duration;
      if (progress.inSeconds == 0 || duration.inSeconds == 0) return;
      _historyService.addHistory(WatchHistory(
        bangumiId: widget.bangumiId!,
        bangumiName: widget.title,
        bangumiNameCn: widget.animeTitle ?? widget.title,
        lastWatchEpisode: _currentEpisode,
        lastWatchEpisodeName: _currentEpisodeTitle ?? '',
        lastWatchTime: DateTime.now(),
        pluginName: _currentPluginName ?? '',
        progress: progress,
        duration: duration,
        cachedPlayUrl: _lastResolvedVideoUrl,
        cachedPlayUrlTime: _lastResolvedVideoUrl.isNotEmpty ? DateTime.now() : null,
      ));
    } catch (_) {}
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _saveHistoryTimer?.cancel();
    _saveWatchHistory();
    try { _playerController.dispose(); } catch (e) { debugPrint('释放播放器失败: $e'); }
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _tabController.dispose();
    _danmakuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            try { await _playerController.dispose(); } catch (e) { debugPrint('$e'); }
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
                child: FutureBuilder<String>(
                  future: _currentVideoUrlFuture,
                  builder: (context, snapshot) {
                    final videoUrl = snapshot.data ?? '';
                    final isLoading =
                        snapshot.connectionState == ConnectionState.waiting ||
                        (_isLoadingEpisodes && videoUrl.isEmpty && !snapshot.hasError);
                    final hasError = snapshot.hasError || _hasParseError;
                    return Column(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.width * 9 / 16,
                          color: Colors.black,
                          child: Stack(
                            children: [
                              if (videoUrl.isNotEmpty)
                                SmallscreenVideo(
                                  videoUrl: videoUrl,
                                  title: widget.title,
                                  currentEpisode: _currentEpisode,
                                  totalEpisodes: _totalEpisodes,
                                  playerController: _playerController,
                                  episodeTitle: _currentEpisodeTitle,
                                  onNextEpisode: _hasNextEpisode ? _playNextEpisode : null,
                                  onPreviousEpisode: _hasPreviousEpisode ? _playPreviousEpisode : null,
                                  hasNextEpisode: _hasNextEpisode,
                                  hasPreviousEpisode: _hasPreviousEpisode,
                                  initialProgress: _currentInitialProgress,
                                  episodes: _episodes,
                                  onEpisodeSelected: _playEpisode,
                                  isLoadingEpisodes: _isLoadingEpisodes,
                                  isDescending: _isDescending,
                                  onToggleSort: () => setState(() => _isDescending = !_isDescending),
                                  isDanmakuEnabled: _isDanmakuEnabled,
                                  animeTitle: widget.animeTitle,
                                  bangumiId: widget.bangumiId,
                                  onDanmakuToggle: (enabled) => setState(() => _isDanmakuEnabled = enabled),
                                ),
                              if (hasError && !isLoading)
                                Positioned.fill(
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.error_outline, color: Colors.white70, size: 40),
                                        const SizedBox(height: 12),
                                        const Text('视频解析失败，请切换视频源重试',
                                            style: TextStyle(color: Colors.white70, fontSize: 13),
                                            textAlign: TextAlign.center),
                                        const SizedBox(height: 12),
                                        TextButton(onPressed: _updateCurrentVideoUrl, child: const Text('重试')),
                                      ],
                                    ),
                                  ),
                                ),
                              if (isLoading)
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                      const SizedBox(height: 16),
                                      Text('解析中', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                                      if (_showTimeoutHint) ...[
                                        const SizedBox(height: 12),
                                        Text('加载时间较长，点击右下角切换视频源',
                                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                                      ],
                                    ],
                                  ),
                                ),
                              // 顶部返回键：仅在无视频URL时显示（有视频时由 SmallscreenVideo 自身处理）
                              if ((isLoading || hasError) && videoUrl.isEmpty)
                                Positioned(
                                  top: 0, left: 0, right: 0,
                                  child: Container(
                                    height: 64,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 4, top: 8),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                                            onPressed: () => Navigator.of(context).pop(),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            iconSize: 24,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(widget.title,
                                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                                maxLines: 1, overflow: TextOverflow.ellipsis),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            color: Theme.of(context).cardColor,
                            child: Column(
                              children: [
                                VideoTab(
                                  tabController: _tabController,
                                  isDanmakuEnabled: _isDanmakuEnabled,
                                  isDanmakuInputExpanded: _isDanmakuInputExpanded,
                                  onDanmakuToggle: () {
                                    setState(() {
                                      _isDanmakuEnabled = !_isDanmakuEnabled;
                                      if (!_isDanmakuEnabled) {
                                        _isDanmakuInputExpanded = false;
                                        _danmakuController.clear();
                                      }
                                    });
                                  },
                                  onDanmakuInputTap: () => setState(() => _isDanmakuInputExpanded = true),
                                  onVideoSourceTap: _showVideoSourceSelector,
                                  currentPluginName: _currentPluginName,
                                ),
                                Expanded(
                                  child: TabBarView(
                                    controller: _tabController,
                                    physics: _isDanmakuEnabled ? const NeverScrollableScrollPhysics() : null,
                                    children: [
                                      _buildEpisodeTab(),
                                      const CommentTabWidget.VideoComment(),
                                    ],
                                  ),
                                ),
                                if (_isDanmakuInputExpanded)
                                  DanmakuInputBar(
                                    controller: _danmakuController,
                                    onSend: () {
                                      if (_danmakuController.text.isNotEmpty) _danmakuController.clear();
                                    },
                                    onClose: () {
                                      setState(() {
                                        _isDanmakuInputExpanded = false;
                                        _danmakuController.clear();
                                      });
                                    },
                                  ),
                              ],
                            ),
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

  Widget _buildEpisodeTab() {
    if (_isLoadingEpisodes && _episodes.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 56),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, childAspectRatio: 2.2, crossAxisSpacing: 12, mainAxisSpacing: 12,
              ),
              itemCount: 12,
              itemBuilder: (context, index) => const SkeletonEpisodeCard(),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_episodes.length > 12)
                InkWell(
                  onTap: () => setState(() => _isEpisodesExpanded = !_isEpisodesExpanded),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_isEpisodesExpanded ? Icons.expand_less : Icons.expand_more,
                            size: 16, color: Theme.of(context).colorScheme.onSurface),
                        const SizedBox(width: 6),
                        Text(_isEpisodesExpanded ? '收起' : '展开',
                            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                      ],
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              InkWell(
                onTap: () => setState(() => _isDescending = !_isDescending),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_isDescending ? Icons.arrow_downward : Icons.arrow_upward,
                          size: 16, color: Theme.of(context).colorScheme.onSurface),
                      const SizedBox(width: 6),
                      Text(_isDescending ? '倒序' : '正序',
                          style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, childAspectRatio: 2.2, crossAxisSpacing: 12, mainAxisSpacing: 12,
            ),
            itemCount: _isEpisodesExpanded || _episodes.length <= 12 ? _episodes.length : 12,
            itemBuilder: (context, index) {
              final episode = _sortedEpisodes[index];
              return SmallscreenEpisode(
                episode: episode,
                isCurrent: episode.number == _currentEpisode,
                onTap: () => _playEpisode(episode),
              );
            },
          ),
        ),
      ],
    );
  }
}
