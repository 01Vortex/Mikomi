import 'package:flutter/material.dart';
import 'package:mikomi/core/models/watch_history.dart';
import 'package:mikomi/core/services/watch_history_service.dart';
import 'package:mikomi/core/services/bangumi_service.dart';
import 'package:mikomi/features/video/ui/pages/video_page.dart';
import 'package:mikomi/shared/utils/theme_extensions.dart';
import 'package:mikomi/shared/widgets/cached_image.dart';
import 'package:mikomi/shared/widgets/skeleton.dart';
import 'package:mikomi/shared/widgets/scrolling_text.dart';

class HistoryTabContent extends StatelessWidget {
  final List<WatchHistory> histories;
  final bool isLoading;
  final bool isDescending;
  final VoidCallback onSortToggle;
  final VoidCallback onMoreTap;

  const HistoryTabContent({
    super.key,
    required this.histories,
    required this.isLoading,
    required this.isDescending,
    required this.onSortToggle,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: onSortToggle,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.sort,
                    size: 20,
                    color: context.colors.onSurface,
                  ),
                ),
              ),
              InkWell(
                onTap: onMoreTap,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '更多',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.colors.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )
          else if (histories.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                '暂无观看记录',
                style: TextStyle(color: context.colors.textSecondary),
              ),
            )
          else
            Column(
              children: histories
                  .map(
                    (history) => _HistoryItem(
                      key: ValueKey(history.bangumiId),
                      history: history,
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatefulWidget {
  final WatchHistory history;

  const _HistoryItem({super.key, required this.history});

  @override
  State<_HistoryItem> createState() => _HistoryItemState();
}

class _HistoryItemState extends State<_HistoryItem> {
  final BangumiService _bangumiService = BangumiService();
  final WatchHistoryService _historyService = WatchHistoryService();
  String? _coverUrl;

  @override
  void initState() {
    super.initState();
    _loadCover();
  }

  Future<void> _loadCover() async {
    final bangumi = await _bangumiService.getBangumiById(
      widget.history.bangumiId,
    );
    if (mounted && bangumi != null) {
      setState(() {
        _coverUrl = bangumi.coverUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => VideoPage(
              title: widget.history.displayName,
              videoUrl: '',
              currentEpisode: widget.history.lastWatchEpisode,
              episodes: const [],
              pluginName: widget.history.pluginName.isNotEmpty
                  ? widget.history.pluginName
                  : null,
              animeTitle: widget.history.bangumiNameCn,
              bangumiId: widget.history.bangumiId,
              initialProgress: widget.history.progress,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
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
            content: Text('确认删除《${widget.history.displayName}》的观看记录吗?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  '取消',
                  style: TextStyle(color: context.colors.textSecondary),
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
          await _historyService.deleteHistory(widget.history.bangumiId);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _coverUrl == null
                  ? SkeletonLoader(
                      width: 80,
                      height: 110,
                      borderRadius: BorderRadius.circular(8),
                    )
                  : CachedImage(
                      imageUrl: _coverUrl!,
                      width: 80,
                      height: 110,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ScrollingText(
                    text: widget.history.displayName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: context.colors.onSurface,
                    ),
                    height: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '视频源:${widget.history.pluginName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '第${widget.history.lastWatchEpisode}集 · 播放到${widget.history.progressPercent.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _formatTime(widget.history.lastWatchTime),
                    style: TextStyle(
                      fontSize: 11,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
