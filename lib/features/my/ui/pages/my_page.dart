import 'package:flutter/material.dart';
import 'package:mikomi/features/settings/settings_page.dart';
import 'package:mikomi/features/settings/theme_settings_page.dart';
import 'package:mikomi/features/my/ui/pages/history_play_page.dart';
import 'package:mikomi/core/services/watch_history_service.dart';
import 'package:mikomi/core/services/history_notifier.dart';
import 'package:mikomi/core/models/watch_history.dart';
import 'package:mikomi/shared/utils/theme_extensions.dart';
import 'package:mikomi/features/my/ui/widgets/profile_action_tabs.dart';
import 'package:mikomi/features/my/ui/widgets/history_tab_content.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final WatchHistoryService _historyService = WatchHistoryService();
  final HistoryNotifier _historyNotifier = HistoryNotifier();
  List<WatchHistory> _histories = [];
  bool _isLoading = true;
  bool _isDescending = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadHistories();
    _historyNotifier.addListener(_onHistoryChanged);
  }

  @override
  void dispose() {
    _historyNotifier.removeListener(_onHistoryChanged);
    super.dispose();
  }

  void _onHistoryChanged() {
    _loadHistories();
  }

  Future<void> _loadHistories() async {
    setState(() => _isLoading = true);
    final histories = await _historyService.getHistories();
    if (mounted) {
      setState(() {
        _histories = histories;
        _isLoading = false;
      });
    }
  }

  List<WatchHistory> get _sortedHistories {
    return _isDescending ? _histories : _histories.reversed.toList();
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedTab = index;
    });
  }

  void _onSortToggle() {
    setState(() {
      _isDescending = !_isDescending;
    });
  }

  void _onMoreTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WatchHistoryPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 背景区和个人信息区（合并使用Stack）
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 背景（添加渐变效果）
                    Container(
                      height: 240,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            context.colors.surfaceVariant,
                            context.colors.surfaceVariant.withValues(
                              alpha: 0.8,
                            ),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 120, 24, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 头像（添加阴影）
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: context.colors.surface,
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: context.colors.primaryContainer,
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: context.colors.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // 昵称和UID
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '昵称',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: context.colors.onSurface,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'uid:88888888',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: context.colors.textSecondary,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // 简介和性别标签（在背景外，添加卡片效果）
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '这是简介',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.colors.onSurface,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              context.colors.surfaceVariant,
                              context.colors.surfaceVariant.withValues(
                                alpha: 0.7,
                              ),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 14,
                              color: context.colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '男',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.colors.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              // 按钮tab区
              SliverToBoxAdapter(
                child: ProfileActionTabs(
                  selectedIndex: _selectedTab,
                  onTabSelected: _onTabSelected,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              // 对应按钮tab内容区
              SliverToBoxAdapter(child: _buildTabContent()),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          // 左上角主题按钮
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ThemePage()),
                );
              },
              icon: const Icon(Icons.palette_outlined),
              style: IconButton.styleFrom(
                backgroundColor: context.colors.surface.withValues(alpha: 0.9),
                foregroundColor: context.colors.onSurface,
              ),
            ),
          ),
          // 右上角设置按钮
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
              icon: const Icon(Icons.settings_outlined),
              style: IconButton.styleFrom(
                backgroundColor: context.colors.surface.withValues(alpha: 0.9),
                foregroundColor: context.colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0: // 历史播放
        return HistoryTabContent(
          histories: _sortedHistories,
          isLoading: _isLoading,
          isDescending: _isDescending,
          onSortToggle: _onSortToggle,
          onMoreTap: _onMoreTap,
        );
      case 1: // 收藏
        return _buildPlaceholder('收藏功能开发中');
      case 2: // 下载
        return _buildPlaceholder('下载功能开发中');
      case 3: // 我的评论
        return _buildPlaceholder('评论功能开发中');
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPlaceholder(String message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
        ),
      ),
    );
  }
}
