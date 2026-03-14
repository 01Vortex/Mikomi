import 'package:flutter/material.dart';
import 'package:mikomi/config/themes/app_colors.dart';
import 'package:mikomi/core/models/bangumi_item.dart';
import 'package:mikomi/core/services/bangumi_detail_service.dart';
import 'package:mikomi/features/anime/ui/widgets/anime_header.dart';
import 'package:mikomi/features/anime/ui/widgets/anime_overview_tab.dart';
import 'package:mikomi/features/anime/ui/widgets/anime_detail_tab.dart';
import 'package:mikomi/features/anime/ui/widgets/anime_tucao_tab.dart';
import 'package:mikomi/features/anime/ui/widgets/anime_comments_tab.dart';

class BangumiDetailPage extends StatefulWidget {
  final BangumiItem bangumiItem;

  const BangumiDetailPage({super.key, required this.bangumiItem});

  @override
  State<BangumiDetailPage> createState() => _BangumiDetailPageState();
}

class _BangumiDetailPageState extends State<BangumiDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final BangumiDetailService _detailService = BangumiDetailService();
  bool _showTitle = false;
  late BangumiItem _bangumiItem;
  bool _commentsLoaded = false;

  @override
  void initState() {
    super.initState();
    _bangumiItem = widget.bangumiItem;
    _tabController = TabController(length: 4, vsync: this);
    _scrollController.addListener(_onScroll);
    _tabController.addListener(_onTabChanged);
    _loadDetailInfo();
  }

  void _onTabChanged() {
    // 当切换到吐槽tab时标记为已加载
    if (_tabController.index == 2) {
      setState(() {
        _commentsLoaded = true;
      });
    }
  }

  Future<void> _loadDetailInfo() async {
    // 如果已有完整信息，不再请求
    if (_bangumiItem.summary.isNotEmpty && _bangumiItem.ratingCount > 0) {
      return;
    }

    final detail = await _detailService.getBangumiDetailById(_bangumiItem.id);
    if (detail != null && mounted) {
      setState(() {
        _bangumiItem = detail;
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
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 400,
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.surface,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: AnimatedOpacity(
                opacity: _showTitle ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _bangumiItem.displayName,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: AnimeHeader(bangumiItem: _bangumiItem),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
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
            AnimeOverviewTab(bangumiItem: _bangumiItem),
            AnimeDetailTab(bangumiItem: _bangumiItem),
            _commentsLoaded
                ? AnimeTucaoTab(bangumiItem: _bangumiItem)
                : const Center(child: Text('切换到此标签页加载评论')),
            const AnimeCommentsTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('开始观看'),
        onPressed: () {},
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
    return Container(color: AppColors.surface, child: tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
