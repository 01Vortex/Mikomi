import 'package:flutter/material.dart';
import 'package:mikomi/config/themes/app_colors.dart';
import 'package:mikomi/features/video/ui/widgets/video_player_widget.dart';
import 'package:mikomi/features/video/ui/widgets/episode_list_widget.dart';
import 'package:mikomi/features/video/ui/widgets/comment_tab_widget.dart';
import 'package:mikomi/features/anime/ui/widgets/video_source_selector.dart';
import 'package:mikomi/core/models/episode.dart';
import 'package:mikomi/core/services/bangumi_episodes_service.dart';
import 'package:mikomi/features/video/data/repositories/video_source_repository.dart';

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

  // 使用Key来控制播放器重建
  Key _playerKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _currentEpisode = widget.currentEpisode;
    _episodes = widget.episodes;
    _videoUrl = widget.videoUrl;
    _tabController = TabController(length: 2, vsync: this);

    if (_episodes.isEmpty && widget.pluginName != null) {
      _loadEpisodesInBackground();
    }
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

  String get _currentVideoUrl {
    try {
      final url =
          _episodes.firstWhere((ep) => ep.number == _currentEpisode).url ??
          _videoUrl;
      debugPrint('当前播放URL: $url');
      return url;
    } catch (e) {
      debugPrint('获取当前视频URL失败: $e');
      return _videoUrl;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            VideoPlayerWidget(
              key: _playerKey,
              videoUrl: _currentVideoUrl,
              title: widget.title,
              currentEpisode: _currentEpisode,
              totalEpisodes: _totalEpisodes,
              episodeTitle: _currentEpisodeTitle,
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                      // 切换剧集时重新创建播放器
                                      _playerKey = UniqueKey();
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
        ),
      ),
    );
  }
}
