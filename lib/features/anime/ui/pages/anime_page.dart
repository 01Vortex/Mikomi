import 'package:flutter/material.dart';
import 'package:mikomi/core/models/anime.dart';
import 'package:mikomi/core/services/bangumi_detail_service.dart';
import 'package:mikomi/features/anime/ui/widgets/anime_header.dart';
import 'package:mikomi/features/anime/ui/widgets/overview_tab_content.dart';
import 'package:mikomi/features/anime/ui/widgets/detail_tab_content.dart';
import 'package:mikomi/features/anime/ui/widgets/teasing_tab_content.dart';
import 'package:mikomi/features/anime/selector/collection_status_selector.dart';
import 'package:mikomi/features/anime/ui/widgets/play_button.dart';
import 'package:mikomi/core/models/collection_item.dart';
import 'package:mikomi/core/services/collection_service.dart';
import 'package:mikomi/features/anime/selector/video_source_selector.dart';
import 'package:mikomi/features/settings/video_play/service/plugin_manager_service.dart';
import 'package:mikomi/shared/utils/theme_extensions.dart';

class AnimePage extends StatefulWidget {
  final Anime anime;

  const AnimePage({super.key, required this.anime});

  @override
  State<AnimePage> createState() => _animePageState();
}

class _animePageState extends State<AnimePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final BangumiDetailService _detailService = BangumiDetailService();
  final VideoPluginManager _pluginManager = VideoPluginManager();
  final CollectionService _collectionService = CollectionService();

  bool _showTitle = false;
  late Anime _anime;
  CollectionStatus _collectionStatus = CollectionStatus.notCollected;

  // 视频源列表（从插件动态加载）
  List<VideoSource> _videoSources = [];

  @override
  void initState() {
    super.initState();
    _anime = widget.anime;
    _tabController = TabController(length: 4, vsync: this);
    _scrollController.addListener(_onScroll);
    _loadVideoSources();
    _loadDetailInfo();
    _loadCollectionStatus();
  }

  Future<void> _loadCollectionStatus() async {
    final collected = await _collectionService.isCollected(_anime.id);
    if (mounted) {
      setState(() {
        _collectionStatus = collected
            ? CollectionStatus.collected
            : CollectionStatus.notCollected;
      });
    }
  }

  Future<void> _onCollectionChanged(CollectionStatus status) async {
    if (status == CollectionStatus.collected) {
      await _collectionService.addCollection(
        CollectionItem(
          bangumiId: _anime.id,
          bangumiName: _anime.name,
          bangumiNameCn: _anime.nameCn,
          coverUrl: _anime.coverUrl,
          collectedAt: DateTime.now(),
        ),
      );
    } else {
      await _collectionService.removeCollection(_anime.id);
    }
    if (mounted) {
      setState(() {
        _collectionStatus = status;
      });
    }
  }

  Future<void> _loadVideoSources() async {
    await _pluginManager.init();
    if (mounted) {
      setState(() {
        _videoSources = _pluginManager.plugins
            .map((plugin) => VideoSource(name: plugin.name))
            .toList();
      });
    }
  }

  Future<void> _loadDetailInfo() async {
    // 如果已有完整信息，不再请求
    if (_anime.summary.isNotEmpty && _anime.ratingCount > 0) {
      return;
    }

    final detail = await _detailService.getBangumiDetailById(_anime.id);
    if (detail != null && mounted) {
      setState(() {
        _anime = detail;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 200 && !_showTitle) {
      setState(() => _showTitle = true);
    } else if (_scrollController.offset <= 200 && _showTitle) {
      setState(() => _showTitle = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 400,
              pinned: true,
              elevation: 0,
              backgroundColor: Theme.of(context).cardColor,
              titleSpacing: 0,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: AnimatedOpacity(
                opacity: _showTitle ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _anime.displayName,
                  style: const TextStyle(fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: AnimeHeader(anime: _anime),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: context.colors.textSecondary,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  tabs: const [
                    Tab(text: '概述'),
                    Tab(text: '详细'),
                    Tab(text: '吐槽'),
                    Tab(text: '评论'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            OverviewTabContent(anime: _anime),
            DetailTabContent(anime: _anime),
            AnimeTeasingContent(anime: _anime),
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.construction, size: 48),
                    SizedBox(height: 16),
                    Text('评论功能开发中', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CollectionStatusSelector(
              currentStatus: _collectionStatus,
              onStatusChanged: _onCollectionChanged,
            ),
            const SizedBox(height: 16),
            PlayButton(
              videoSources: _videoSources,
              animeTitle: _anime.displayName,
              animeName: _anime.name,
              bangumiId: _anime.id,
              onPlay: () {
                // 播放回调
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Theme.of(context).cardColor, child: tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
