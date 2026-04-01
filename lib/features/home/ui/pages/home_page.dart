import 'package:flutter/material.dart';
import 'package:mikomi/features/home/ui/widgets/home_header_bar.dart';
import 'package:mikomi/features/home/ui/widgets/home_slider_image.dart';
import 'package:mikomi/features/home/ui/widgets/home_button_tab.dart';
import 'package:mikomi/features/home/ui/widgets/home_display.dart';
import 'package:mikomi/features/home/data/bangumi_basis.dart';
import 'package:mikomi/core/models/bangumi_item.dart';
import 'package:mikomi/shared/widgets/skeleton.dart';
import 'package:mikomi/config/themes/app_colors.dart';
import 'package:mikomi/config/routes/app_routes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  final BangumiBasis _homeRepository = BangumiBasis();
  final ScrollController _scrollController = ScrollController();

  List<BangumiItem> _trendsList = [];
  List<BangumiItem> _bannerList = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentOffset = 0;
  final int _pageSize = 12;
  final int _selectedTab = 0;

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

    final results = await Future.wait([
      _homeRepository.getRecommendedList(
        limit: _pageSize,
        offset: _currentOffset,
      ),
      _homeRepository.getBannerList(count: 5),
    ]);

    final recommended = results[0];
    final banners = results[1];
    final resolvedBanners =
        banners.isNotEmpty ? banners : recommended.take(5).toList();

    if (mounted) {
      setState(() {
        _trendsList = recommended;
        _bannerList = resolvedBanners;
        _isLoading = false;
        _currentOffset = _pageSize;
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    final moreRecommended = await _homeRepository.getRecommendedList(
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

  Widget _buildRecommendSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              child: HomeActionTabs(
                selectedIndex: _selectedTab,
                onTabSelected: (index) {
                  if (index == 0) {
                    Navigator.pushNamed(context, AppRoutes.schedule);
                  } else if (index == 1) {
                    Navigator.pushNamed(context, AppRoutes.ranking);
                  } else if (index == 2) {
                    Navigator.pushNamed(context, AppRoutes.category);
                  }
                },
              ),
            ),
            SliverToBoxAdapter(
              child: _isLoading
                  ? _buildRecommendSkeleton()
                  : HomeDisplay(
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
