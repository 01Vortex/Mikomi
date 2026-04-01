import 'package:flutter/material.dart';
import 'package:mikomi/features/home/service/schedule_service.dart';
import 'package:mikomi/features/home/models/home_anime_model.dart';
import 'package:mikomi/config/app_routes.dart';
import 'package:mikomi/shared/theme_extensions.dart';
import 'package:mikomi/shared/cached_image.dart';
import 'package:mikomi/shared/scrolling_text.dart';
import 'package:mikomi/core/providers/app_theme_provider.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage>
    with SingleTickerProviderStateMixin {
  final ScheduleService _scheduleService = ScheduleService();
  TabController? _tabController;
  PageController? _pageController;
  List<List<HomeAnimeModel>> _weekSchedule = [];
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
    final schedule = await _scheduleService.getWeekSchedule();
    if (mounted) {
      setState(() {
        _weekSchedule = schedule;
        _isLoading = false;
      });
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
                    : <HomeAnimeModel>[];
                return _buildDayGrid(context, daySchedule);
              },
            ),
    );
  }

  Widget _buildDayGrid(BuildContext context, List<HomeAnimeModel> animeList) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossCount = 1;
    if (screenWidth > 600) crossCount = 2;
    if (screenWidth > 900) crossCount = 3;

    final cardHeight = screenWidth > 600 ? 160.0 : 120.0;

    if (animeList.isEmpty) {
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
      itemCount: animeList.length,
      itemBuilder: (context, index) {
        final anime = animeList[index];
        return _buildScheduleCard(context, anime, cardHeight);
      },
    );
  }

  Widget _buildScheduleCard(
    BuildContext context,
    HomeAnimeModel anime,
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
            AppRoutes.animeDetail,
            arguments: anime,
          );
        },
        child: SizedBox(
          height: cardHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Hero(
                  tag: 'anime_${anime.id}',
                  transitionOnUserGestures: true,
                  flightShuttleBuilder:
                      AnimationProvider.buildHeroFlightShuttle,
                  child: CachedImage(
                    imageUrl: anime.coverUrl,
                    width: imageWidth,
                    height: cardHeight,
                    fit: BoxFit.cover,
                  ),
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
                        text: anime.displayName,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        height: 40,
                      ),
                      const SizedBox(height: 4),
                      if ((anime.info.isNotEmpty) ||
                          (anime.summary.isNotEmpty))
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
                                anime.info.isNotEmpty
                                    ? anime.info
                                    : anime.summary,
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
                          if (anime.ratingScore > 0) ...[
                            Icon(
                              Icons.star_rounded,
                              size: 15,
                              color: context.colors.primary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              anime.ratingScore.toStringAsFixed(1),
                              style: context.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (anime.rank > 0) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.leaderboard,
                              size: 15,
                              color: context.colors.tertiary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'Rank ${anime.rank}',
                              style: context.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (anime.ratingCount > 0)
                            Text(
                              '${anime.ratingCount}人',
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
