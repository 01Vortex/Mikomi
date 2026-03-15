import 'package:flutter/material.dart';
import 'package:mikomi/config/themes/app_colors.dart';
import 'package:mikomi/features/video/ui/widgets/video_player_widget.dart';
import 'package:mikomi/features/video/ui/widgets/episode_list_widget.dart';
import 'package:mikomi/features/video/ui/widgets/comment_tab_widget.dart';
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
  final BangumiEpisodesService _episodesService = BangumiEpisodesService();
  final VideoSourceRepository _videoSourceRepo = VideoSourceRepository();

  // 为每个页面创建独立的播放器控制器
  late final VideoPlayerController _playerController;

  // 缓存当前视频URL的Future,避免重复解析
  Future<String>? _currentVideoUrlFuture;

  @override
  void initState() {
    super.initState();
    _currentEpisode = widget.currentEpisode;
    _episodes = widget.episodes;
    _videoUrl = widget.videoUrl;
    _tabController = TabController(length: 2, vsync: this);

    // 创建新的播放器控制器实例
    _playerController = VideoPlayerController();

    // 初始化视频URL
    _updateCurrentVideoUrl();

    if (_episodes.isEmpty && widget.pluginName != null) {
      _loadEpisodesInBackground();
    }
  }

  /// 更新当前视频URL(切换集数时调用)
  void _updateCurrentVideoUrl() {
    _currentVideoUrlFuture = _getCurrentVideoUrl();
  }

  Future<void> _loadEpisodesInBackground() async {
    if (_isLoadingEpisodes) return;

    setState(() => _isLoadingEpisodes = true);

    try {
      if (widget.animeTitle != null && widget.pluginName != null) {
        await _loadEpisodesWithVideoSource(widget.pluginName!);
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
          _videoUrl = mergedEpisodes.first.url ?? '';
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
        if (widget.pluginName != null && _videoUrl.isNotEmpty) {
          final parsedUrl = await _videoSourceRepo.parseVideoUrl(
            _videoUrl,
            widget.pluginName!,
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
      debugPrint('插件名称: ${widget.pluginName}');

      // 如果有插件名称,尝试解析视频地址
      if (widget.pluginName != null) {
        final parsedUrl = await _videoSourceRepo.parseVideoUrl(
          url,
          widget.pluginName!,
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

  @override
  void dispose() {
    // 释放播放器资源
    _playerController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          // 页面退出时确保释放播放器
          await _playerController.dispose();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: FutureBuilder<String>(
          key: ValueKey(_currentEpisode), // 添加key,确保切换集数时重建
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
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.divider,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: AppColors.divider,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            labelColor: AppColors.primary,
                            unselectedLabelColor: AppColors.textSecondary,
                            indicatorColor: AppColors.primary,
                            indicatorWeight: 3,
                            labelStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            tabs: const [
                              Tab(text: '选集'),
                              Tab(text: '评论'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _isLoadingEpisodes && _episodes.isEmpty
                                  ? const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CircularProgressIndicator(),
                                          SizedBox(height: 16),
                                          Text(
                                            '正在加载剧集...',
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : EpisodeListWidget(
                                      title: widget.title,
                                      currentEpisode: _currentEpisode,
                                      episodes: _episodes,
                                      videoSources: widget.videoSources,
                                      onEpisodeChanged: (episode) {
                                        setState(() {
                                          _currentEpisode = episode;
                                          _updateCurrentVideoUrl();
                                        });
                                      },
                                      onSourceChanged: (source) {
                                        // 视频源切换逻辑
                                      },
                                    ),
                              const CommentTabWidget(),
                            ],
                          ),
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
    );
  }
}
