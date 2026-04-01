import 'package:flutter/material.dart';
import 'package:mikomi/config/app_routes.dart';
import 'package:mikomi/features/home/models/home_anime_model.dart';
import 'package:mikomi/features/home/service/rank_service.dart';
import 'package:mikomi/shared/theme_extensions.dart';
import 'package:mikomi/shared/cached_image.dart';
import 'package:mikomi/shared/skeleton.dart';

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

  RankCategory _currentCategory = RankCategory.play;
  List<HomeAnimeModel> _rankList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRankList();
  }

  Future<void> _loadRankList() async {
    setState(() => _isLoading = true);

    final list = await _rankService.getRankList(_currentCategory, limit: 30);

    if (!mounted) {
      return;
    }

    setState(() {
      _rankList = list;
      _isLoading = false;
    });
  }

  Future<void> _switchCategory(RankCategory category) async {
    if (_currentCategory == category) {
      return;
    }

    setState(() {
      _currentCategory = category;
    });

    await _loadRankList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('排行榜')),
      body: RefreshIndicator(
        onRefresh: _loadRankList,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildTabBar(context)),
            if (_isLoading)
              SliverList.builder(
                itemCount: 8,
                itemBuilder: (context, index) => _buildSkeletonItem(context),
              )
            else if (_rankList.isEmpty)
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
                itemCount: _rankList.length,
                itemBuilder: (context, index) {
                  final item = _rankList[index];
                  return _buildRankItem(context, index + 1, item);
                },
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
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

  Widget _buildRankItem(BuildContext context, int rank, HomeAnimeModel item) {
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
            Navigator.pushNamed(
              context,
              AppRoutes.animeDetail,
              arguments: item,
            );
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
                                '${_rankService.metricLabel(_currentCategory)} ${_rankService.metricValue(item, _currentCategory)}',
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
