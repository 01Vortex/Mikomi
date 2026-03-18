import 'package:flutter/material.dart';
import 'package:mikomi/core/services/bangumi_service.dart';
import 'package:mikomi/core/models/bangumi_item.dart';
import 'package:mikomi/features/schedule/ui/widgets/schedule_day_card.dart';
import 'package:mikomi/config/routes/app_routes.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage>
    with SingleTickerProviderStateMixin {
  final BangumiService _bangumiService = BangumiService();
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
      final schedule = await _bangumiService.getCalendar();
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 104,
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
          tabs: _weekDays.map((day) => Tab(text: day.substring(1))).toList(),
        ),
      ),
      body: _isLoading && _weekSchedule.isEmpty
          ? const Center(child: CircularProgressIndicator())
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
      return const Center(
        child: Text('暂无新番', style: TextStyle(color: Colors.grey)),
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
        return ScheduleDayCard(
          bangumiItem: bangumi,
          cardHeight: cardHeight,
          onBangumiTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.bangumiDetail,
              arguments: bangumi,
            );
          },
        );
      },
    );
  }
}
