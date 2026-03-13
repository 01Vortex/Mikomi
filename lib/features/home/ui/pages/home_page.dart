import 'package:flutter/material.dart';
import 'package:mikomi/features/home/ui/widgets/home_app_bar.dart';
import 'package:mikomi/features/home/ui/widgets/banner_section.dart';
import 'package:mikomi/features/home/ui/widgets/history_section.dart';
import 'package:mikomi/features/home/ui/widgets/recommend_section.dart';
import 'package:mikomi/core/services/bangumi_service.dart';
import 'package:mikomi/core/services/watch_history_service.dart';
import 'package:mikomi/core/models/bangumi_item.dart';
import 'package:mikomi/core/models/watch_history.dart';
import 'package:mikomi/shared/widgets/skeleton_card.dart';
import 'package:mikomi/shared/widgets/skeleton_grid_card.dart';
import 'package:mikomi/config/themes/app_colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  final BangumiService _bangumiService = BangumiService();
  final WatchHistoryService _historyService = WatchHistoryService();
  final ScrollController _scrollController = ScrollController();

  List<BangumiItem> _trendsList = [];
  List<BangumiItem> _bannerList = [];
  List<WatchHistory> _historyList = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentOffset = 0;
  final int _pageSize = 12;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore) {
        _loadMoreData();
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    _currentOffset = 0;

    final recommended = await _bangumiService.getRecommendedList(
      limit: _pageSize,
      offset: _currentOffset,
    );

    final history = await _historyService.getHistory();

    if (mounted) {
      setState(() {
        _trendsList = recommended;
        _bannerList = recommended.take(5).toList();
        _historyList = history.take(6).toList();
        _isLoading = false;
        _currentOffset = _pageSize;
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    final moreRecommended = await _bangumiService.getRecommendedList(
      limit: _pageSize,
      offset: _currentOffset,
    );

    if (mounted) {
      setState(() {
        _trendsList.addAll(moreRecommended);
        _isLoadingMore = false;
        _currentOffset += _pageSize;
      });
    }
  }

  Widget _buildHistorySkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            '播放记录',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 210,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (context, index) => const SkeletonCard(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Text(
            '推荐',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 7),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.58,
            ),
            itemCount: 12,
            itemBuilder: (context, index) => const SkeletonGridCard(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.surface,
                child: const HomeAppBar(),
              ),
            ),
            SliverToBoxAdapter(child: BannerSection(bannerList: _bannerList)),
            SliverToBoxAdapter(
              child: _isLoading
                  ? _buildHistorySkeleton()
                  : HistorySection(historyList: _historyList),
            ),
            SliverToBoxAdapter(
              child: _isLoading
                  ? _buildRecommendSkeleton()
                  : RecommendSection(
                      bangumiList: _trendsList,
                      isLoading: _isLoadingMore,
                      onLoadMore: _loadMoreData,
                    ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.bottom + 80,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
