import 'package:flutter/material.dart';
import 'package:mikomi/config/app_routes.dart';
import 'package:mikomi/features/home/models/home_anime_model.dart';
import 'package:mikomi/features/home/service/rank_service.dart';
import 'package:mikomi/shared/cached_image.dart';
import 'package:mikomi/shared/skeleton.dart';
import 'package:mikomi/shared/theme_extensions.dart';

class RankPage extends StatefulWidget {
  const RankPage({super.key});

  @override
  State<RankPage> createState() => _RankPageState();
}

class _RankPageState extends State<RankPage> {
  final RankService _rankService = RankService();
  final List<_RankTabItem> _tabs = const [
    _RankTabItem(label: '播放', category: RankCategory.play),
    _RankTabItem(label: '收藏', category: RankCategory.collection),
    _RankTabItem(label: '国漫', category: RankCategory.chinese),
    _RankTabItem(label: '日漫', category: RankCategory.japanese),
  ];

  late final PageController _pageController;
  RankCategory _currentCategory = RankCategory.play;
  final Map<RankCategory, List<HomeAnimeModel>> _rankByCategory = {};
  final Set<RankCategory> _loadingCategories = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadRankList(RankCategory.play, forceRefresh: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadRankList(
    RankCategory category, {
    bool forceRefresh = false,
  }) async {
    if (_loadingCategories.contains(category)) return;
    if (!forceRefresh && _rankByCategory.containsKey(category)) return;

    setState(() => _loadingCategories.add(category));
    final list = await _rankService.getRankList(category, limit: 100);
    if (!mounted) return;

    setState(() {
      _rankByCategory[category] = list;
      _loadingCategories.remove(category);
    });
  }

  Future<void> _switchCategory(RankCategory category) async {
    if (_currentCategory == category) return;
    final targetIndex = _tabs.indexWhere((tab) => tab.category == category);
    if (targetIndex < 0) return;

    setState(() => _currentCategory = category);
    if (_pageController.hasClients) {
      await _pageController.animateToPage(
        targetIndex,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
    await _loadRankList(category);
  }

  Future<void> _onPageChanged(int index) async {
    final category = _tabs[index].category;
    if (_currentCategory != category) {
      setState(() => _currentCategory = category);
    }
    await _loadRankList(category);
  }

  Future<void> _refreshCurrentCategory() {
    return _loadRankList(_currentCategory, forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('排行榜'), centerTitle: true),
      body: Column(
        children: [
          _buildTabBar(context),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _tabs.length,
              onPageChanged: (index) => _onPageChanged(index),
              itemBuilder: (context, index) {
                final category = _tabs[index].category;
                return _buildCategoryPage(context, category);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPage(BuildContext context, RankCategory category) {
    final isLoading = _loadingCategories.contains(category);
    final list = _rankByCategory[category] ?? const <HomeAnimeModel>[];

    return RefreshIndicator(
      onRefresh: _refreshCurrentCategory,
      child: CustomScrollView(
        slivers: [
          if (isLoading)
            SliverList.builder(
              itemCount: 8,
              itemBuilder: (context, index) => _buildSkeletonItem(context),
            )
          else if (list.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  '暂无排行数据',
                  style: TextStyle(color: context.colors.textSecondary),
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];
                return _buildRankItem(context, index + 1, item, category);
              },
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: _tabs.map((tab) {
          final selected = _currentCategory == tab.category;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: selected ? context.colors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _switchCategory(tab.category),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    tab.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? context.colors.onPrimary
                          : context.colors.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRankItem(
    BuildContext context,
    int rank,
    HomeAnimeModel item,
    RankCategory category,
  ) {
    final rankColor = switch (rank) {
      1 => const Color(0xFFFFB300),
      2 => const Color(0xFF90A4AE),
      3 => const Color(0xFFBF8F68),
      _ => context.colors.primary,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.animeDetail, arguments: item);
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: rankColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      color: rankColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedImage(
                    imageUrl: item.coverUrl,
                    width: 72,
                    height: 96,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 96,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: context.colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.airDate.isEmpty ? '未知' : item.airDate,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: context.colors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.ratingScore > 0
                                  ? item.ratingScore.toStringAsFixed(1)
                                  : '暂无评分',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.colors.onSurface,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              Icons.people_alt_outlined,
                              size: 15,
                              color: context.colors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${_rankService.metricLabel(category)} ${_rankService.metricValue(item, category)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.colors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonItem(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            SkeletonLoader(
              width: 34,
              height: 34,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(width: 10),
            SkeletonLoader(
              width: 72,
              height: 96,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    width: double.infinity,
                    height: 14,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  SkeletonLoader(
                    width: 100,
                    height: 12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 24),
                  SkeletonLoader(
                    width: 140,
                    height: 12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankTabItem {
  final String label;
  final RankCategory category;

  const _RankTabItem({required this.label, required this.category});
}
