import 'package:flutter/material.dart';
import 'package:mikomi/features/home/data/repositories/home_repository_impl.dart';
import 'package:mikomi/core/models/bangumi_item.dart';
import 'package:mikomi/config/routes/app_routes.dart';
import 'package:mikomi/shared/utils/theme_extensions.dart';
import 'package:mikomi/shared/widgets/cached_image.dart';
import 'package:mikomi/shared/widgets/scrolling_text.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage>
    with SingleTickerProviderStateMixin {
  final HomeRepositoryImpl _homeRepository = HomeRepositoryImpl();
  TabController? _tabController;
  PageController? _pageController;
  List<List<BangumiItem>> _weekSchedule = [];
  bool _isLoading = true;
  final int _currentDay = DateTime.now().weekday - 1;

  final List<String> _weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 7,
      vsync: this,
      initialIndex: _currentDay,
    );
    _pageController = PageController(initialPage: _currentDay);
    _tabController?.addListener(_handleTabChange);
    _loadSchedule();
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabChange);
    _tabController?.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController?.indexIsChanging ?? false) {
      _pageController?.animateToPage(
        _tabController!.index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);
    try {
      final schedule = await _homeRepository.getCalendar();
      if (mounted) {
        setState(() {
          _weekSchedule = schedule;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _weekSchedule = List.generate(7, (_) => []);
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToToday() {
    _pageController?.animateToPage(
      _currentDay,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _tabController?.animateTo(_currentDay);
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController == null || _pageController == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: context.colors.primary),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('新番时间表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: _scrollToToday,
            tooltip: '回到今天',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelColor: context.colors.primary,
          unselectedLabelColor: context.colors.onSurfaceVariant,
          indicatorColor: context.colors.primary,
          tabs: _weekDays.map((day) => Tab(text: day.substring(1))).toList(),
        ),
      ),
      body: _isLoading && _weekSchedule.isEmpty
          ? Center(
              child: CircularProgressIndicator(color: context.colors.primary),
            )
          : PageView.builder(
              controller: _pageController,
              itemCount: 7,
              onPageChanged: (index) {
                _tabController?.animateTo(index);
              },
              itemBuilder: (context, index) {
                final daySchedule =
                    _weekSchedule.isNotEmpty && index < _weekSchedule.length
                    ? _weekSchedule[index]
                    : <BangumiItem>[];
                return _buildDayGrid(context, daySchedule);
              },
            ),
    );
  }

  Widget _buildDayGrid(BuildContext context, List<BangumiItem> bangumiList) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossCount = 1;
    if (screenWidth > 600) crossCount = 2;
    if (screenWidth > 900) crossCount = 3;

    final cardHeight = screenWidth > 600 ? 160.0 : 120.0;

    if (bangumiList.isEmpty) {
      return Center(
        child: Text(
          '暂无新番',
          style: TextStyle(color: context.colors.onSurfaceVariant),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: cardHeight + 12,
      ),
      itemCount: bangumiList.length,
      itemBuilder: (context, index) {
        final bangumi = bangumiList[index];
        return _buildScheduleCard(context, bangumi, cardHeight);
      },
    );
  }

  Widget _buildScheduleCard(
    BuildContext context,
    BangumiItem bangumiItem,
    double cardHeight,
  ) {
    final imageWidth = cardHeight * 0.7;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.bangumiDetail,
            arguments: bangumiItem,
          );
        },
        child: SizedBox(
          height: cardHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedImage(
                  imageUrl: bangumiItem.coverUrl,
                  width: imageWidth,
                  height: cardHeight,
                  fit: BoxFit.cover,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ScrollingText(
                        text: bangumiItem.displayName,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        height: 40,
                      ),
                      const SizedBox(height: 4),
                      if ((bangumiItem.info.isNotEmpty) ||
                          (bangumiItem.summary.isNotEmpty))
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: context.colors.primaryContainer
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                bangumiItem.info.isNotEmpty
                                    ? bangumiItem.info
                                    : bangumiItem.summary,
                                style: context.textTheme.labelMedium?.copyWith(
                                  color: context.colors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      const Spacer(),
                      Row(
                        children: [
                          if (bangumiItem.ratingScore > 0) ...[
                            Icon(
                              Icons.star_rounded,
                              size: 15,
                              color: context.colors.primary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              bangumiItem.ratingScore.toStringAsFixed(1),
                              style: context.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (bangumiItem.rank > 0) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.leaderboard,
                              size: 15,
                              color: context.colors.tertiary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'Rank ${bangumiItem.rank}',
                              style: context.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (bangumiItem.ratingCount > 0)
                            Text(
                              '${bangumiItem.ratingCount}人',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.colors.onSurfaceVariant,
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
    );
  }
}
