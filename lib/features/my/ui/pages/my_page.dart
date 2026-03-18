import 'package:flutter/material.dart';
import 'package:mikomi/features/my/ui/widgets/profile_header.dart';
import 'package:mikomi/features/my/ui/widgets/action_chips.dart';
import 'package:mikomi/features/my/ui/pages/settings_page.dart';
import 'package:mikomi/features/my/ui/pages/theme_page.dart';
import 'package:mikomi/features/my/ui/pages/watch_history_page.dart';
import 'package:mikomi/core/services/watch_history_service.dart';
import 'package:mikomi/core/services/history_notifier.dart';
import 'package:mikomi/core/models/watch_history.dart';
import 'package:mikomi/features/my/ui/widgets/watch_history_card.dart';
import 'package:mikomi/features/video/ui/pages/video_page.dart';

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
  bool _isDescending = true; // true=倒序(最新在前), false=正序(最旧在前)

  @override
  void initState() {
    super.initState();
    _loadHistories();

    // 监听历史记录变更
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
        _histories = histories.take(6).toList();
        _isLoading = false;
      });
    }
  }

  List<WatchHistory> get _sortedHistories {
    return _isDescending ? _histories : _histories.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  const ProfileHeader(nickname: '昵称', bio: '个人简介'),
                  const SizedBox(height: 24),
                  ActionChips(
                    chips: [
                      MyActionItem(
                        label: '最近在看',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WatchHistoryPage(),
                            ),
                          );
                        },
                      ),
                      MyActionItem(label: '收藏', onTap: () {}),
                      MyActionItem(label: '我的下载', onTap: () {}),
                      MyActionItem(label: '我的评论', onTap: () {}),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    )
                  else if (_histories.isNotEmpty)
                    _buildHistorySection()
                  else
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        '暂无观看记录',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            Positioned(
              top: 16,
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
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  foregroundColor: Colors.black87,
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.settings_outlined),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  foregroundColor: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _isDescending = !_isDescending;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '排序',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isDescending ? Icons.arrow_downward : Icons.arrow_upward,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WatchHistoryPage(),
                    ),
                  );
                },
                child: const Text('查看全部'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _sortedHistories.length,
            itemBuilder: (context, index) {
              final history = _sortedHistories[index];
              return WatchHistoryCard(
                history: history,
                cardHeight: 100,
                onTap: () {
                  // 直接跳转到视频播放页
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          VideoPage(
                            title: history.displayName,
                            videoUrl: '',
                            currentEpisode: history.lastWatchEpisode,
                            episodes: const [],
                            pluginName: history.pluginName.isNotEmpty
                                ? history.pluginName
                                : null,
                            animeTitle: history.bangumiNameCn,
                            bangumiId: history.bangumiId,
                            coverUrl: history.coverUrl,
                            initialProgress: history.progress,
                          ),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                      transitionDuration: const Duration(milliseconds: 200),
                    ),
                  );
                },
                onLongPress: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('删除历史记录'),
                      content: Text('确认删除《${history.displayName}》的观看记录吗?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            '取消',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('删除'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await _historyService.deleteHistory(history.bangumiId);
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
