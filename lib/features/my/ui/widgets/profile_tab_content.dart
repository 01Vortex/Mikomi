import 'package:flutter/material.dart';
import 'package:mikomi/core/models/watch_history.dart';
import 'package:mikomi/core/services/watch_history_service.dart';
import 'package:mikomi/core/services/bangumi_service.dart';
import 'package:mikomi/features/video/ui/pages/video_page.dart';
import 'package:mikomi/shared/utils/theme_extensions.dart';
import 'package:mikomi/shared/widgets/cached_image.dart';
import 'package:mikomi/shared/widgets/skeleton.dart';

class ProfileTabContent extends StatelessWidget {
  final int selectedTab;
  final List<WatchHistory> histories;
  final bool isLoading;
  final bool isDescending;
  final VoidCallback onSortToggle;
  final VoidCallback onMoreTap;

  const ProfileTabContent({
    super.key,
    required this.selectedTab,
    required this.histories,
    required this.isLoading,
    required this.isDescending,
    required this.onSortToggle,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 排序和更多按钮
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: onSortToggle,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '排序',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: onMoreTap,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '更多',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 内容区域
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          )
        else if (histories.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              _getEmptyMessage(),
              style: TextStyle(color: context.colors.textSecondary),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: histories
                  .map((history) => _HistoryItem(history: history))
                  .toList(),
            ),
          ),
      ],
    );
  }

  String _getEmptyMessage() {
    switch (selectedTab) {
      case 0:
        return '暂无观看记录';
      case 1:
        return '暂无收藏';
      case 2:
        return '暂无下载';
      case 3:
        return '暂无评论';
      default:
        return '暂无内容';
    }
  }
}

// 历史记录项组件
class _HistoryItem extends StatefulWidget {
  final WatchHistory history;

  const _HistoryItem({required this.history});

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
            // 封面图
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _coverUrl == null
                  ? SkeletonLoader(
                      width: 120,
                      height: 160,
                      borderRadius: BorderRadius.circular(8),
                    )
                  : CachedImage(
                      imageUrl: _coverUrl!,
                      width: 120,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(width: 12),
            // 信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.history.displayName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: context.colors.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '视频源:${widget.history.pluginName}',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '第${widget.history.lastWatchEpisode}集 · 播放到${widget.history.progressPercent.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(widget.history.lastWatchTime),
                    style: TextStyle(
                      fontSize: 12,
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
    return '${time.year}-${time.month}-${time.day}';
  }
}
