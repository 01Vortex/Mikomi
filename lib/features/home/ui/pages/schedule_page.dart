import 'package:flutter/material.dart';
import 'package:mikomi/config/app_routes.dart';
import 'package:mikomi/core/providers/app_theme_provider.dart';
import 'package:mikomi/features/home/models/home_anime_model.dart';
import 'package:mikomi/features/home/service/schedule_service.dart';
import 'package:mikomi/shared/cached_image.dart';
import 'package:mikomi/shared/scrolling_text.dart';
import 'package:mikomi/shared/theme_extensions.dart';
import 'package:mikomi/shared/skeleton.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage>
    with SingleTickerProviderStateMixin {
  final ScheduleService _scheduleService = ScheduleService();

  static const List<String> _weekDays = [
    '星期一',
    '星期二',
    '星期三',
    '星期四',
    '星期五',
    '星期六',
    '星期日',
  ];

  late final int _todayIndex;
  TabController? _tabController;
  PageController? _pageController;

  List<List<HomeAnimeModel>> _weekSchedule = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _todayIndex = (DateTime.now().weekday + 6) % 7;
    _tabController = TabController(
      length: 7,
      vsync: this,
      initialIndex: _todayIndex,
    );
    _pageController = PageController(initialPage: _todayIndex);
    _tabController?.addListener(_handleTabChange);
    _loadSchedule(forceRefresh: true);
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabChange);
    _tabController?.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!(_tabController?.indexIsChanging ?? false)) {
      return;
    }

    final controller = _pageController;
    if (controller == null || !controller.hasClients) {
      return;
    }

    controller.animateToPage(
      _tabController!.index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _loadSchedule({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    final schedule = await _scheduleService.getWeekSchedule(
      forceRefresh: forceRefresh,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _weekSchedule = schedule;
      _isLoading = false;
    });
  }

  void _scrollToToday() {
    _tabController?.animateTo(_todayIndex);

    final controller = _pageController;
    if (controller == null || !controller.hasClients) {
      return;
    }

    controller.animateToPage(
      _todayIndex,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabController = _tabController;
    final pageController = _pageController;

    if (tabController == null || pageController == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: context.colors.primary),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('时间表'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: () => _loadSchedule(forceRefresh: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: '回到今天',
            onPressed: _scrollToToday,
            icon: const Icon(Icons.today_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: tabController,
                isScrollable: true,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: context.colors.primary,
                ),
                labelColor: context.colors.onPrimary,
                unselectedLabelColor: context.colors.onSurfaceVariant,
                tabs: _weekDays.map((day) => Tab(text: day)).toList(),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: 7,
              itemBuilder: (context, index) => _buildScheduleSkeleton(context),
            )
          : RefreshIndicator(
              onRefresh: () => _loadSchedule(forceRefresh: true),
              child: PageView.builder(
                controller: pageController,
                itemCount: 7,
                onPageChanged: (index) {
                  if (tabController.index != index) {
                    tabController.animateTo(index);
                  }
                },
                itemBuilder: (context, index) {
                  final dayList =
                      index < _weekSchedule.length ? _weekSchedule[index] : const <HomeAnimeModel>[];
                  return _buildDayList(context, index, dayList);
                },
              ),
            ),
    );
  }

  Widget _buildDayList(
    BuildContext context,
    int dayIndex,
    List<HomeAnimeModel> animeList,
  ) {
    if (animeList.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.event_busy_outlined,
            size: 48,
            color: context.colors.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '${_weekDays[dayIndex]} 暂无更新',
              style: TextStyle(color: context.colors.onSurfaceVariant),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: animeList.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
            child: Text(
              '${_weekDays[dayIndex]} · 共 ${animeList.length} 部正在更新',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.colors.onSurfaceVariant,
              ),
            ),
          );
        }

        final anime = animeList[index - 1];
        return _buildScheduleItem(context, anime);
      },
    );
  }

  Widget _buildScheduleItem(BuildContext context, HomeAnimeModel anime) {
    final cs = context.colors;
    final timeText = _extractTime(anime.airDate);
    final regionText = anime.info.contains('国漫') ? '国漫' : '日漫';
    final episodeText = _extractEpisode(anime.info);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.animeDetail, arguments: anime);
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Hero(
                    tag: 'anime_${anime.id}',
                    transitionOnUserGestures: true,
                    flightShuttleBuilder: AnimationProvider.buildHeroFlightShuttle,
                    child: CachedImage(
                      imageUrl: anime.coverUrl,
                      width: 78,
                      height: 102,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 102,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ScrollingText(
                          text: anime.displayName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          height: 22,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          anime.summary.isEmpty ? '暂无简介' : anime.summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$regionText · $timeText${episodeText.isEmpty ? '' : ' · $episodeText'}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: cs.primary,
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

  Widget _buildScheduleSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            SkeletonLoader(
              width: 78,
              height: 102,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 102,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(
                      width: 170,
                      height: 16,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 8),
                    SkeletonLoader(
                      width: double.infinity,
                      height: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 6),
                    SkeletonLoader(
                      width: 180,
                      height: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const Spacer(),
                    SkeletonLoader(
                      width: 108,
                      height: 20,
                      borderRadius: BorderRadius.circular(999),
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

  String _extractEpisode(String info) {
    final match = RegExp(r'第\d+[话集]|更新至\d+集').firstMatch(info);
    return match?.group(0) ?? '';
  }

  String _extractTime(String airDate) {
    if (airDate.length >= 16) {
      return airDate.substring(11, 16);
    }
    return '--:--';
  }
}
