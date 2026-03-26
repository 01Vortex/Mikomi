import 'package:flutter/material.dart';
import 'package:mikomi/core/services/watch_history_service.dart';
import 'package:mikomi/core/models/watch_history.dart';
import 'package:mikomi/features/video/ui/pages/video_page.dart';
import 'package:mikomi/shared/widgets/cached_image.dart';
import 'package:mikomi/shared/widgets/skeleton.dart';
import 'package:mikomi/core/services/bangumi_service.dart';

class WatchHistoryPage extends StatefulWidget {
  const WatchHistoryPage({super.key});

  @override
  State<WatchHistoryPage> createState() => _WatchHistoryPageState();
}

class _WatchHistoryPageState extends State<WatchHistoryPage> {
  final WatchHistoryService _historyService = WatchHistoryService();
  List<WatchHistory> _histories = [];
  final Set<int> _selectedIds = {};
  bool _isLoading = true;
  bool _isSelectionMode = false;

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

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除历史记录'),
        content: Text('确认删除选中的 ${_selectedIds.length} 条记录吗?'),
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
      for (final id in _selectedIds) {
        await _historyService.deleteHistory(id);
      }
      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
      _loadHistories();
    }
  }

  void _toggleSelection(int bangumiId) {
    setState(() {
      if (_selectedIds.contains(bangumiId)) {
        _selectedIds.remove(bangumiId);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(bangumiId);
      }
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedIds.clear();
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedIds.length == _histories.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.clear();
        for (var history in _histories) {
          _selectedIds.add(history.bangumiId);
        }
      }
    });
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
        centerTitle: true,
        title: const Text('观看历史', style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: _toggleSelectionMode,
            child: Text(
              _isSelectionMode ? '取消' : '编辑',
              style: const TextStyle(fontSize: 14),
            ),
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
                            SizedBox(
                              width: 12,
                              child: Column(
                                children: [
                                  if (!isLast)
                                    Container(
                                      width: 2,
                                      height: 120,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.3),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _WatchHistoryCard(
                                history: history,
                                isSelected: _selectedIds.contains(
                                  history.bangumiId,
                                ),
                                isSelectionMode: _isSelectionMode,
                                cardHeight: 110,
                                onTap: () {
                                  if (_isSelectionMode) {
                                    _toggleSelection(history.bangumiId);
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
                                              videoUrl: history.cachedPlayUrl,
                                              currentEpisode:
                                                  history.lastWatchEpisode,
                                              episodes: const [],
                                              pluginName:
                                                  history.pluginName.isNotEmpty
                                                  ? history.pluginName
                                                  : null,
                                              animeTitle: history.bangumiNameCn,
                                              bangumiId: history.bangumiId,
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
                                onLongPress: () {
                                  if (!_isSelectionMode) {
                                    setState(() {
                                      _isSelectionMode = true;
                                      _selectedIds.add(history.bangumiId);
                                    });
                                  }
                                },
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
      bottomNavigationBar: _isSelectionMode
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    TextButton(
                      onPressed: _selectAll,
                      child: Text(
                        _selectedIds.length == _histories.length
                            ? '取消全选'
                            : '全选',
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      child: const Text('删除'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _WatchHistoryCard extends StatefulWidget {
  final WatchHistory history;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isSelectionMode;
  final double cardHeight;

  const _WatchHistoryCard({
    required this.history,
    required this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.cardHeight = 120,
  });

  @override
  State<_WatchHistoryCard> createState() => _WatchHistoryCardState();
}

class _WatchHistoryCardState extends State<_WatchHistoryCard> {
  final BangumiService _bangumiService = BangumiService();
  String? _coverUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCover();
  }

  Future<void> _loadCover() async {
    final bangumi = await _bangumiService.getBangumiById(
      widget.history.bangumiId,
    );
    if (mounted) {
      setState(() {
        if (bangumi != null) {
          _coverUrl = bangumi.coverUrl;
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageWidth = widget.cardHeight * 0.7;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Stack(
          children: [
            SizedBox(
              height: widget.cardHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _isLoading
                        ? SkeletonLoader(
                            width: imageWidth,
                            height: widget.cardHeight,
                            borderRadius: BorderRadius.circular(8),
                          )
                        : CachedImage(
                            imageUrl: _coverUrl ?? '',
                            width: imageWidth,
                            height: widget.cardHeight,
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
                          Text(
                            widget.history.displayName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              _buildChip(
                                context,
                                '来源: ${widget.history.pluginName}',
                              ),
                              _buildChip(
                                context,
                                '看到: 第${widget.history.lastWatchEpisode}集 ${widget.history.progressPercent.toStringAsFixed(0)}%',
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            _formatTime(widget.history.lastWatchTime),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.isSelectionMode)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surface,
                    border: Border.all(
                      color: widget.isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      width: 2,
                    ),
                  ),
                  child: widget.isSelected
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: theme.colorScheme.onPrimary,
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label) {
    return Chip(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      side: BorderSide.none,
      label: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 3) {
      return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}天前';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}小时前';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}
