import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mikomi/features/settings/settings_page.dart';
import 'package:mikomi/features/settings/theme_settings_page.dart';
import 'package:mikomi/features/my/ui/pages/history_play_page.dart';
import 'package:mikomi/core/services/watch_history_service.dart';
import 'package:mikomi/core/services/history_notifier.dart';
import 'package:mikomi/core/services/auth_service.dart';
import 'package:mikomi/features/my/models/watch_history.dart';
import 'package:mikomi/shared/theme_extensions.dart';
import 'package:mikomi/features/my/ui/widgets/profile_action_tabs.dart';
import 'package:mikomi/features/my/ui/widgets/history_tab_content.dart';
import 'package:mikomi/features/my/ui/widgets/collect_tab_content.dart';

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
    final authService = context.watch<AuthService>();
    final isLoggedIn = authService.isLoggedIn;

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 背景区和个人信息区（仅登录时显示）
              if (isLoggedIn)
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
                              context.colors.surfaceContainerHighest,
                              context.colors.surfaceContainerHighest.withValues(
                                alpha: 0.8,
                              ),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(24, 80, 24, 16),
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
                              child: authService.mikomiUserInfo != null
                                  ? CircleAvatar(
                                      radius: 40,
                                      backgroundColor:
                                          context.colors.primaryContainer,
                                      child: Icon(
                                        Icons.person,
                                        size: 40,
                                        color:
                                            context.colors.onPrimaryContainer,
                                      ),
                                    )
                                  : CircleAvatar(
                                      radius: 40,
                                      backgroundColor:
                                          context.colors.primaryContainer,
                                      child: Icon(
                                        Icons.person,
                                        size: 40,
                                        color:
                                            context.colors.onPrimaryContainer,
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
                                    authService.nickname ?? '用户',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: context.colors.onSurface,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'uid:${authService.mikomiUserInfo?.account ?? ''}',
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
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              // 按钮tab区
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: isLoggedIn ? MediaQuery.of(context).padding.top + 56 : MediaQuery.of(context).padding.top + 56,
                  ),
                  child: ProfileActionTabs(
                    selectedIndex: _selectedTab,
                    onTabSelected: _onTabSelected,
                  ),
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
                  MaterialPageRoute(builder: (context) => const ThemeSettingsPage()),
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
        return const CollectTabContent();
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
        color: context.colors.surfaceContainerHighest,
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
