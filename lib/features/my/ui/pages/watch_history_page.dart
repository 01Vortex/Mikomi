import 'package:flutter/material.dart';
import 'package:mikomi/core/services/watch_history_service.dart';
import 'package:mikomi/core/models/watch_history.dart';
import 'package:mikomi/features/my/ui/widgets/watch_history_card.dart';
import 'package:mikomi/features/video/ui/pages/video_page.dart';

class WatchHistoryPage extends StatefulWidget {
  const WatchHistoryPage({super.key});

  @override
  State<WatchHistoryPage> createState() => _WatchHistoryPageState();
}

class _WatchHistoryPageState extends State<WatchHistoryPage> {
  final WatchHistoryService _historyService = WatchHistoryService();
  List<WatchHistory> _histories = [];
  bool _isLoading = true;
  bool _showDelete = false;

  @override
  void initState() {
    super.initState();
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

  Future<void> _deleteHistory(int bangumiId) async {
    await _historyService.deleteHistory(bangumiId);
    _loadHistories();
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空历史记录'),
        content: const Text('确认要清除所有历史记录吗?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '取消',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _historyService.clearAll();
      _loadHistories();
    }
  }

  // 按日期分组历史记录
  Map<String, List<WatchHistory>> _groupByDate() {
    final Map<String, List<WatchHistory>> grouped = {};
    final now = DateTime.now();

    for (var history in _histories) {
      final date = history.lastWatchTime;
      final diff = now.difference(date);

      String key;
      if (diff.inDays == 0) {
        key = '今天';
      } else if (diff.inDays == 1) {
        key = '昨天';
      } else if (diff.inDays < 7) {
        key = '${diff.inDays}天前';
      } else {
        key = '${date.month}月${date.day}日';
      }

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(history);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedHistories = _groupByDate();

    return Scaffold(
      appBar: AppBar(
        title: const Text('最近在看'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() => _showDelete = !_showDelete);
            },
            icon: Icon(_showDelete ? Icons.edit_outlined : Icons.edit),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _histories.isEmpty
          ? const Center(
              child: Text('暂无观看记录', style: TextStyle(color: Colors.grey)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupedHistories.length,
              itemBuilder: (context, index) {
                final dateKey = groupedHistories.keys.elementAt(index);
                final histories = groupedHistories[dateKey]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 日期标题和第一个圆点对齐
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          dateKey,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...histories.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final history = entry.value;
                      final isLast = idx == histories.length - 1;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 时间轴连线
                            SizedBox(
                              width: 12,
                              child: Column(
                                children: [
                                  if (!isLast)
                                    Container(
                                      width: 2,
                                      height: 120,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.3),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // 历史记录卡片
                            Expanded(
                              child: WatchHistoryCard(
                                history: history,
                                showDelete: _showDelete,
                                cardHeight: 110,
                                onTap: () {
                                  if (_showDelete) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('编辑模式')),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder:
                                            (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                            ) => VideoPage(
                                              title: history.displayName,
                                              videoUrl: '',
                                              currentEpisode:
                                                  history.lastWatchEpisode,
                                              episodes: const [],
                                              pluginName:
                                                  history.pluginName.isNotEmpty
                                                  ? history.pluginName
                                                  : null,
                                              animeTitle: history.bangumiNameCn,
                                              bangumiId: history.bangumiId,
                                              coverUrl: history.coverUrl,
                                              initialProgress: history.progress,
                                            ),
                                        transitionsBuilder:
                                            (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                              child,
                                            ) {
                                              return FadeTransition(
                                                opacity: animation,
                                                child: child,
                                              );
                                            },
                                        transitionDuration: const Duration(
                                          milliseconds: 200,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                onDelete: () =>
                                    _deleteHistory(history.bangumiId),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (index < groupedHistories.length - 1)
                      const SizedBox(height: 16),
                  ],
                );
              },
            ),
      floatingActionButton: _histories.isNotEmpty
          ? FloatingActionButton(
              onPressed: _clearAll,
              child: const Icon(Icons.clear_all),
            )
          : null,
    );
  }
}
