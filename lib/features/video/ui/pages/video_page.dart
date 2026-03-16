import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mikomi/config/themes/app_colors.dart';
import 'package:mikomi/features/video/ui/widgets/video_player_widget.dart';
import 'package:mikomi/features/video/ui/widgets/comment_tab_widget.dart';
import 'package:mikomi/features/video/ui/widgets/video_tab_bar.dart';
import 'package:mikomi/features/video/ui/widgets/episode_card.dart';
import 'package:mikomi/features/video/ui/widgets/danmaku_input_bar.dart';
import 'package:mikomi/features/anime/ui/widgets/video_source_selector.dart';
import 'package:mikomi/core/models/episode.dart';
import 'package:mikomi/core/services/bangumi_episodes_service.dart';
import 'package:mikomi/features/video/data/repositories/video_source_repository.dart';
import 'package:mikomi/features/video/controllers/video_player_controller.dart';

class VideoPage extends StatefulWidget {
  final String title;
  final String videoUrl;
  final int currentEpisode;
  final List<Episode> episodes;
  final List<VideoSource>? videoSources;
  final String? pluginName;
  final String? animeTitle;
  final int? bangumiId;

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
  final TextEditingController _danmakuController = TextEditingController();
  final BangumiEpisodesService _episodesService = BangumiEpisodesService();
  final VideoSourceRepository _videoSourceRepo = VideoSourceRepository();

  late final VideoPlayerController _playerController;
  Future<String>? _currentVideoUrlFuture;

  @override
  void initState() {
    super.initState();
    _currentEpisode = widget.currentEpisode;
    _episodes = widget.episodes;
    _videoUrl = widget.videoUrl;
    _currentPluginName = widget.pluginName;
    _tabController = TabController(length: 2, vsync: this);

    // 显示状态栏 - 使用edgeToEdge模式
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // 设置状态栏样式 - 白色背景，黑色图标
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    _initializePlayer();

    if (_episodes.isEmpty && _currentPluginName != null) {
      _loadEpisodesInBackground();
    }
  }

  Future<void> _initializePlayer() async {
    try {
      _playerController = VideoPlayerController();
      _updateCurrentVideoUrl();
    } catch (e) {
      debugPrint('初始化播放器失败: $e');
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    // 热重启时重新初始化播放器
    debugPrint('VideoPage: 热重启检测到，重新初始化');
    _initializePlayer();
  }

  /// 更新当前视频URL(切换集数时调用)
  void _updateCurrentVideoUrl() {
    _currentVideoUrlFuture = _getCurrentVideoUrl();
  }

  Future<void> _loadEpisodesInBackground() async {
    if (_isLoadingEpisodes) return;

    setState(() => _isLoadingEpisodes = true);

    try {
      if (widget.animeTitle != null && _currentPluginName != null) {
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
          // 更新视频URL
          _updateCurrentVideoUrl();
        });
        debugPrint('成功加载 ${mergedEpisodes.length} 集');
        debugPrint('第一集URL: ${mergedEpisodes.first.url}');
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
    } catch (e) {
      debugPrint('获取当前视频URL失败: $e');
      debugPrint('==================================');
      return _videoUrl;
    }
  }

  Future<void> _switchVideoSource(VideoSource source) async {
    debugPrint('========== 切换视频源 ==========');
    debugPrint('新视频源: ${source.name}');
    debugPrint('==================================');

    setState(() {
      _currentPluginName = source.name;
      _isLoadingEpisodes = true;
    });

    try {
      await _loadEpisodesWithVideoSource(source.name);
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
    if (widget.videoSources == null || widget.videoSources!.isEmpty) {
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => VideoSourceSelector(
        sources: widget.videoSources!,
        animeTitle: widget.animeTitle,
        onSourceSelected: (source) {
          Navigator.pop(context);
          _switchVideoSource(source);
        },
      ),
    );
  }

  @override
  void dispose() {
    try {
      _playerController.dispose();
    } catch (e) {
      debugPrint('释放播放器失败: $e');
    }

    // 恢复默认状态栏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white, // 白色背景
        statusBarIconBrightness: Brightness.dark, // 黑色图标
        statusBarBrightness: Brightness.light,
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
          backgroundColor: Colors.black,
          resizeToAvoidBottomInset: true,
          extendBodyBehindAppBar: true,
          body: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              Expanded(
                child: FutureBuilder<String>(
                  key: ValueKey(_currentEpisode),
                  future: _currentVideoUrlFuture,
                  builder: (context, snapshot) {
                    final videoUrl = snapshot.data ?? _videoUrl;

                    return Column(
                      children: [
                        VideoPlayerWidget(
                          videoUrl: videoUrl,
                          title: widget.title,
                          currentEpisode: _currentEpisode,
                          totalEpisodes: _totalEpisodes,
                          episodeTitle: _currentEpisodeTitle,
                          playerController: _playerController,
                        ),
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppColors.surface,
                            ),
                            child: Column(
                              children: [
                                VideoTabBar(
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
                                      const CommentTabWidget(),
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载剧集...', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
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
                      color: AppColors.background,
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
                          color: AppColors.textPrimary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isEpisodesExpanded ? '收起' : '展开',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
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
                    color: AppColors.background,
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
                        color: AppColors.textPrimary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isDescending ? '倒序' : '正序',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
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
              return EpisodeCard(
                episode: episode,
                isCurrent: isCurrent,
                onTap: () {
                  setState(() {
                    _currentEpisode = episode.number;
                    _updateCurrentVideoUrl();
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
