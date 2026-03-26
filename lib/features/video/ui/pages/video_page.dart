import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mikomi/features/video/ui/widgets/smallscreen_video.dart';
import 'package:mikomi/features/video/ui/widgets/video_comment.dart';
import 'package:mikomi/features/video/ui/widgets/video_tab.dart';
import 'package:mikomi/features/video/ui/widgets/smallscreen_episcode.dart';
import 'package:mikomi/features/video/ui/widgets/danmaku_input.dart';
import 'package:mikomi/features/anime/selector/video_source_selector.dart';
import 'package:mikomi/features/settings/video_settings/service/plugin_manager_service.dart';
import 'package:mikomi/shared/widgets/skeleton.dart';
import 'package:mikomi/core/models/episode.dart';
import 'package:mikomi/core/services/bangumi_episodes_service.dart';
import 'package:mikomi/features/video/data/video_source_repository.dart';
import 'package:mikomi/features/video/services/parser/video_source_provider.dart'
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
  final int? bangumiId;
  final String? coverUrl;
  final Duration? initialProgress; // 初始播放进度

  const VideoPage({
    super.key,
    required this.title,
    required this.videoUrl,
    this.currentEpisode = 1,
    required this.episodes,
    this.videoSources,
    this.pluginName,
    this.animeTitle,
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
  bool _isEpisodesExpanded = true; // 剧集列表是否展开
  List<VideoSource> _fallbackVideoSources = [];
  final TextEditingController _danmakuController = TextEditingController();
  final BangumiEpisodesService _episodesService = BangumiEpisodesService();
  final VideoSourceRepository _videoSourceRepo = VideoSourceRepository();
  final VideoPluginManager _pluginManager = VideoPluginManager();
  final WatchHistoryService _historyService = WatchHistoryService();

  late final VideoPlaybackService _playerController;
  Future<String>? _currentVideoUrlFuture;
  bool _showTimeoutHint = false;
  Timer? _timeoutTimer;
  Timer? _saveHistoryTimer; // 定期保存历史的计时器
  Duration? _currentInitialProgress; // 当前使用的初始进度
  bool _isReassembling = false;

  @override
  void initState() {
    super.initState();
    _currentEpisode = widget.currentEpisode;
    _episodes = widget.episodes;
    _videoUrl = widget.videoUrl;
    _currentPluginName = widget.pluginName;
    _tabController = TabController(length: 2, vsync: this);

    // 只在第一次加载时使用初始进度
    _currentInitialProgress = widget.initialProgress;

    // 显示状态栏和导航栏
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );

    // 初始化播放器
    _playerController = VideoPlaybackService();

    // 立即开始解析视频
    _currentVideoUrlFuture = _getCurrentVideoUrl();

    // 启动超时计时器
    _timeoutTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showTimeoutHint = true;
        });
      }
    });

    // 异步加载剧集列表，不阻塞视频播放
    if (_episodes.isEmpty && _currentPluginName != null) {
      _loadEpisodesInBackground();
    }

    // 启动定期保存历史的计时器(每2秒保存一次)
    _saveHistoryTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _saveWatchHistory();
    });

    // 兜底加载可切换的视频源（历史入口通常不传 videoSources）
    _loadFallbackVideoSources();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 在这里设置状态栏样式,因为需要访问Theme
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
      if (mounted) {
        _updateCurrentVideoUrl();
      }
    } finally {
      _isReassembling = false;
    }
  }

@override
  void reassemble() {
    super.reassemble();
    debugPrint('VideoPage: 热重启检测到，暂停并重建播放器监听');
    unawaited(_handleReassemble());
  }

  /// 更新当前视频URL(切换集数时调用)
  void _updateCurrentVideoUrl() {
    _videoSourceRepo.cancelVideoParsing();

    setState(() {
      _showTimeoutHint = false;
      _currentVideoUrlFuture = _getCurrentVideoUrl();
    });

    _timeoutTimer?.cancel();

    // 启动3秒超时计时器
    _timeoutTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showTimeoutHint = true;
        });
      }
    });
  }

  Future<void> _loadEpisodesInBackground() async {
    if (_isLoadingEpisodes) return;

    setState(() => _isLoadingEpisodes = true);

    try {
      if (widget.animeTitle != null && _currentPluginName != null) {
        // 异步加载剧集，不影响当前视频播放
        await _loadEpisodesWithVideoSource(_currentPluginName!);
      } else if (widget.bangumiId != null) {
        await _loadBangumiEpisodes();
      }
    } catch (e) {
      debugPrint('后台加载剧集失败: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingEpisodes = false);
      }
    }
  }

  Future<void> _loadEpisodesWithVideoSource(String pluginName) async {
    if (widget.animeTitle == null) return;

    try {
      // 异步获取视频源剧集
      final videoEpisodes = await _videoSourceRepo
          .searchAndGetEpisodes(widget.animeTitle!, pluginName)
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              debugPrint('搜索视频源超时');
              return [];
            },
          );

      if (videoEpisodes.isEmpty) {
        debugPrint('未找到视频源剧集');
        return;
      }

      // 异步获取Bangumi剧集信息（如果有）
      List<Episode>? bangumiEpisodes;
      if (widget.bangumiId != null) {
        try {
          bangumiEpisodes = await _episodesService
              .getEpisodesBySubjectId(widget.bangumiId!)
              .timeout(
                const Duration(seconds: 15),
                onTimeout: () {
                  debugPrint('获取Bangumi剧集超时，使用视频源数据');
                  return [];
                },
              );
        } catch (e) {
          debugPrint('获取Bangumi剧集失败: $e，使用视频源数据');
        }
      }

      // 合并剧集信息
      final mergedEpisodes = <Episode>[];
      for (int i = 0; i < videoEpisodes.length; i++) {
        final videoEp = videoEpisodes[i];
        String? title = videoEp.title;

        if (bangumiEpisodes != null && i < bangumiEpisodes.length) {
          title = bangumiEpisodes[i].title;
        }

        mergedEpisodes.add(
          Episode(number: videoEp.number, title: title, url: videoEp.url),
        );
      }

      if (mounted && mergedEpisodes.isNotEmpty) {
        setState(() {
          _episodes = mergedEpisodes;
          // 保持当前集数,如果超出范围则使用第一集
          if (_currentEpisode > mergedEpisodes.length) {
            _currentEpisode = 1;
          }
        });
        debugPrint('成功加载 ${mergedEpisodes.length} 集');
        debugPrint('第一集URL: ${mergedEpisodes.first.url}');

        // 剧集加载完成后，重新解析视频URL
        debugPrint('剧集加载完成，重新解析视频URL');
        _updateCurrentVideoUrl();
      }
    } on CaptchaRequiredException catch (e) {
      debugPrint('加载视频源剧集触发验证码: $e');
      if (mounted) {
        MessageDialog.warning(context, '当前视频源需要验证码验证，请先在视频源站点完成人机验证');
      }
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

      if (mounted && episodes.isNotEmpty) {
        setState(() {
          _episodes = episodes;
        });
      }
    } catch (e) {
      debugPrint('加载Bangumi剧集失败: $e');
    }
  }

  int get _totalEpisodes => _episodes.length;

  String? get _currentEpisodeTitle {
    try {
      return _episodes.firstWhere((ep) => ep.number == _currentEpisode).title;
    } catch (e) {
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
      // 切换集数时清除初始进度
      _currentInitialProgress = null;
    });

    _updateCurrentVideoUrl();
  }

  Future<void> _playNextEpisode() async {
    if (_hasNextEpisode) {
      final nextEpisode = _episodes.firstWhere(
        (ep) => ep.number == _currentEpisode + 1,
        orElse: () => Episode(number: _currentEpisode + 1),
      );
      await _playEpisode(nextEpisode);
    }
  }

  Future<void> _playPreviousEpisode() async {
    if (_hasPreviousEpisode) {
      final previousEpisode = _episodes.firstWhere(
        (ep) => ep.number == _currentEpisode - 1,
        orElse: () => Episode(number: _currentEpisode - 1),
      );
      await _playEpisode(previousEpisode);
    }
  }

  Future<String> _getCurrentVideoUrl() async {
    try {
      // 如果剧集列表为空,返回初始URL
      if (_episodes.isEmpty) {
        debugPrint('========== 视频播放调试 ==========');
        debugPrint('剧集列表为空,使用初始URL: $_videoUrl');
        debugPrint('==================================');

        // 即使剧集列表为空,也尝试解析初始URL
        if (_currentPluginName != null && _videoUrl.isNotEmpty) {
          final parsedUrl = await _videoSourceRepo.parseVideoUrl(
            _videoUrl,
            _currentPluginName!,
          );
          return parsedUrl;
        }

        return _videoUrl;
      }

      // 从剧集列表获取URL
      final url =
          _episodes.firstWhere((ep) => ep.number == _currentEpisode).url ??
          _videoUrl;
      debugPrint('========== 视频播放调试 ==========');
      debugPrint('原始播放URL: $url');
      debugPrint('插件名称: $_currentPluginName');

      // 如果有插件名称,尝试解析视频地址
      if (_currentPluginName != null) {
        final parsedUrl = await _videoSourceRepo.parseVideoUrl(
          url,
          _currentPluginName!,
        );
        debugPrint('最终播放URL: $parsedUrl');
        debugPrint('==================================');
        return parsedUrl;
      }

      debugPrint('无需解析,直接使用原始URL');
      debugPrint('==================================');
      return url;
    } on VideoSourceCancelledException {
      debugPrint('当前解析任务被取消，等待新任务结果');
      return '';
    } catch (e) {
      debugPrint('获取当前视频URL失败: $e');
      debugPrint('==================================');
      if (mounted) {
        MessageDialog.error(context, '视频解析失败，请切换视频源或稍后重试');
      }
      rethrow;
    }
  }


  Future<void> _switchVideoSource(VideoSource source) async {
    debugPrint('========== 切换视频源 ==========');
    debugPrint('新视频源: ${source.name}');
    debugPrint('==================================');

    _videoSourceRepo.cancelVideoParsing();
    await _playerController.stop();

    setState(() {
      _currentPluginName = source.name;
      _isLoadingEpisodes = true;
      // 切换视频源时清除初始进度
      _currentInitialProgress = null;
    });

    try {
      // 异步加载新视频源的剧集列表
      await _loadEpisodesWithVideoSource(source.name);

      // 加载完成后更新当前视频URL
      if (mounted) {
        _updateCurrentVideoUrl();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingEpisodes = false);
      }
    }
  }

  List<Episode> get _sortedEpisodes {
    return _isDescending ? _episodes.reversed.toList() : _episodes;
  }

  void _showVideoSourceSelector() {
    final availableSources =
        (widget.videoSources != null && widget.videoSources!.isNotEmpty)
        ? widget.videoSources!
        : _fallbackVideoSources;

    if (availableSources.isEmpty) {
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
        sources: availableSources,
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
          .map((plugin) => VideoSource(name: plugin.name))
          .toList();
    });
  }

  void _saveWatchHistory() {
    // 只有在有番剧ID和标题时才保存历史
    if (widget.bangumiId == null || widget.title.isEmpty) {
      return;
    }

    // 只有在播放器已初始化时才保存
    if (_playerController.player == null || !_playerController.isInitialized) {
      return;
    }

    try {
      // 获取播放进度和总时长
      final progress = _playerController.player!.state.position;
      final duration = _playerController.player!.state.duration;

      // 如果进度为0或总时长为0,跳过保存
      if (progress.inSeconds == 0 || duration.inSeconds == 0) {
        return;
      }

      final history = WatchHistory(
        bangumiId: widget.bangumiId!,
        bangumiName: widget.title,
        bangumiNameCn: widget.animeTitle ?? widget.title,
        lastWatchEpisode: _currentEpisode,
        lastWatchEpisodeName: _currentEpisodeTitle ?? '',
        lastWatchTime: DateTime.now(),
        pluginName: _currentPluginName ?? '',
        progress: progress,
        duration: duration,
      );

      _historyService.addHistory(history);
    } catch (e) {
      // 静默处理错误
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _saveHistoryTimer?.cancel(); // 取消定期保存计时器

    // 最后保存一次观看历史
    _saveWatchHistory();

    try {
      _playerController.dispose();
    } catch (e) {
      debugPrint('释放播放器失败: $e');
    }

    // 恢复默认状态栏
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
              debugPrint('释放播放器失败: $e');
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
                child: FutureBuilder<String>(
                  future: _currentVideoUrlFuture,
                  builder: (context, snapshot) {
                    final videoUrl = snapshot.data ?? '';
                    final isLoading =
                        snapshot.connectionState == ConnectionState.waiting ||
                        (_isLoadingEpisodes &&
                            videoUrl.isEmpty &&
                            !snapshot.hasError);
                    final hasError = snapshot.hasError;

                    debugPrint('========== FutureBuilder状态 ==========');
                    debugPrint('connectionState: ${snapshot.connectionState}');
                    debugPrint('hasData: ${snapshot.hasData}');
                    debugPrint('hasError: $hasError');
                    debugPrint('videoUrl: $videoUrl');
                    debugPrint('isLoading: $isLoading');
                    if (hasError) {
                      debugPrint('error: ${snapshot.error}');
                    }
                    debugPrint('==================================');

                    return Column(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.width * 9 / 16,
                          color: Colors.black,
                          child: Stack(
                            children: [
                              // SmallscreenVideo 始终保留在树中，避免全屏页被 pop
                              if (videoUrl.isNotEmpty)
                                SmallscreenVideo(
                                  videoUrl: videoUrl,
                                  title: widget.title,
                                  currentEpisode: _currentEpisode,
                                  totalEpisodes: _totalEpisodes,
                                  playerController: _playerController,
                                  episodeTitle: _currentEpisodeTitle,
                                  onNextEpisode: _hasNextEpisode
                                      ? _playNextEpisode
                                      : null,
                                  onPreviousEpisode: _hasPreviousEpisode
                                      ? _playPreviousEpisode
                                      : null,
                                  hasNextEpisode: _hasNextEpisode,
                                  hasPreviousEpisode: _hasPreviousEpisode,
                                  initialProgress: _currentInitialProgress,
                                  episodes: _episodes,
                                  onEpisodeSelected: _playEpisode,
                                  isLoadingEpisodes: _isLoadingEpisodes,
                                  isDescending: _isDescending,
                                  onToggleSort: () {
                                    setState(() {
                                      _isDescending = !_isDescending;
                                    });
                                  },
                                  isDanmakuEnabled: _isDanmakuEnabled,
                                  animeTitle: widget.animeTitle,
                                  bangumiId: widget.bangumiId,
                                ),
                              if (isLoading)
                                Stack(
                                  children: [
                                    // 顶部渐变遮罩（超时后显示）
                                    if (_showTimeoutHint)
                                      Positioned(
                                        top: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          height: 80,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.black.withValues(
                                                  alpha: 0.7,
                                                ),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    // 返回按钮（超时后显示）
                                    if (_showTimeoutHint)
                                      Positioned(
                                        top: 10,
                                        left: 4,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.arrow_back,
                                            color: Colors.white,
                                          ),
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          iconSize: 24,
                                        ),
                                      ),
                                    // 中间加载提示
                                    Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            '解析中',
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.8,
                                              ),
                                              fontSize: 14,
                                            ),
                                          ),
                                          if (_showTimeoutHint) ...[
                                            const SizedBox(height: 12),
                                            Text(
                                              '加载时间较长，点击右下角切换视频源',
                                              style: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: 0.7,
                                                ),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              if (!isLoading && videoUrl.isEmpty)
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        hasError
                                            ? Icons.error_outline
                                            : Icons.play_circle_outline,
                                        size: 80,
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                      if (hasError) ...[
                                        const SizedBox(height: 16),
                                        Text(
                                          '视频解析失败',
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.8,
                                            ),
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _updateCurrentVideoUrl();
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: const Text(
                                              '重试',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                            ),
                            child: Column(
                              children: [
                                VideoTab(
                                  tabController: _tabController,
                                  isDanmakuEnabled: _isDanmakuEnabled,
                                  isDanmakuInputExpanded:
                                      _isDanmakuInputExpanded,
                                  onDanmakuToggle: () {
                                    setState(() {
                                      _isDanmakuEnabled = !_isDanmakuEnabled;
                                      if (!_isDanmakuEnabled) {
                                        _isDanmakuInputExpanded = false;
                                        _danmakuController.clear();
                                      }
                                    });
                                  },
                                  onDanmakuInputTap: () {
                                    setState(() {
                                      _isDanmakuInputExpanded = true;
                                    });
                                  },
                                  onVideoSourceTap: _showVideoSourceSelector,
                                  currentPluginName: _currentPluginName,
                                ),
                                Expanded(
                                  child: TabBarView(
                                    controller: _tabController,
                                    physics: _isDanmakuEnabled
                                        ? const NeverScrollableScrollPhysics()
                                        : null,
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
                                      if (_danmakuController.text.isNotEmpty) {
                                        debugPrint(
                                          '发送弹幕: ${_danmakuController.text}',
                                        );
                                        _danmakuController.clear();
                                      }
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox.shrink(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_upward,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '正序',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 收起/展开按钮（集数超过12集时显示）
              if (_episodes.length > 12)
                InkWell(
                  onTap: () {
                    setState(() {
                      _isEpisodesExpanded = !_isEpisodesExpanded;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isEpisodesExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isEpisodesExpanded ? '收起' : '展开',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              // 排序按钮
              InkWell(
                onTap: () {
                  setState(() {
                    _isDescending = !_isDescending;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isDescending
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isDescending ? '倒序' : '正序',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
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
              crossAxisCount: 3,
              childAspectRatio: 2.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _isEpisodesExpanded || _episodes.length <= 12
                ? _episodes.length
                : 12,
            itemBuilder: (context, index) {
              final episode = _sortedEpisodes[index];
              final isCurrent = episode.number == _currentEpisode;
              return SmallscreenEpisode(
                episode: episode,
                isCurrent: isCurrent,
                onTap: () => _playEpisode(episode),
              );
            },
          ),
        ),
      ],
    );
  }
}
