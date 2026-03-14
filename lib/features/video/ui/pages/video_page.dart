import 'package:flutter/material.dart';
import 'package:mikomi/config/themes/app_colors.dart';
import 'package:mikomi/features/video/ui/widgets/video_player_widget.dart';
import 'package:mikomi/features/video/ui/widgets/episode_list_widget.dart';
import 'package:mikomi/features/video/ui/widgets/comment_tab_widget.dart';
import 'package:mikomi/features/anime/ui/widgets/video_source_selector.dart';
import 'package:mikomi/core/models/episode.dart';

class VideoPage extends StatefulWidget {
  final String title;
  final String videoUrl;
  final int currentEpisode;
  final List<Episode> episodes;
  final List<VideoSource>? videoSources;

  const VideoPage({
    super.key,
    required this.title,
    required this.videoUrl,
    this.currentEpisode = 1,
    required this.episodes,
    this.videoSources,
  });

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentEpisode = 1;

  @override
  void initState() {
    super.initState();
    _currentEpisode = widget.currentEpisode;
    _tabController = TabController(length: 2, vsync: this);
  }

  int get _totalEpisodes => widget.episodes.length;

  String? get _currentEpisodeTitle {
    try {
      return widget.episodes
          .firstWhere((ep) => ep.number == _currentEpisode)
          .title;
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          VideoPlayerWidget(
            videoUrl: widget.videoUrl,
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
                        EpisodeListWidget(
                          title: widget.title,
                          currentEpisode: _currentEpisode,
                          episodes: widget.episodes,
                          videoSources: widget.videoSources,
                          onEpisodeChanged: (episode) {
                            setState(() {
                              _currentEpisode = episode;
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
    );
  }
}
