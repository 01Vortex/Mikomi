import 'package:flutter/material.dart';
import 'package:mikomi/shared/widgets/section_header.dart';
import 'package:mikomi/core/models/watch_history.dart';
import 'package:mikomi/config/themes/app_colors.dart';
import 'package:mikomi/shared/widgets/cached_image.dart';
import 'package:mikomi/shared/widgets/skeleton.dart';
import 'package:mikomi/config/localization/app_localizations.dart';
import 'package:mikomi/core/services/bangumi_service.dart';
import 'package:mikomi/features/video/ui/pages/video_page.dart';
import 'package:mikomi/core/services/watch_history_service.dart';
import 'package:mikomi/features/my/ui/pages/watch_history_page.dart';

class HistorySection extends StatefulWidget {
  final List<WatchHistory> historyList;

  const HistorySection({super.key, required this.historyList});

  @override
  State<HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends State<HistorySection> {
  final WatchHistoryService _historyService = WatchHistoryService();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: AppLocalizations.of(context).watchHistory,
          moreText: widget.historyList.isEmpty
              ? AppLocalizations.of(context).noHistory
              : AppLocalizations.of(context).more,
          onMoreTap: widget.historyList.isEmpty
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WatchHistoryPage(),
                    ),
                  );
                },
        ),
        if (widget.historyList.isNotEmpty)
          SizedBox(
            height: 210,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: widget.historyList.length,
              itemBuilder: (context, index) {
                final history = widget.historyList[index];
                return _HistoryCard(
                  history: history,
                  onDelete: () async {
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
          ),
      ],
    );
  }
}

class _HistoryCard extends StatefulWidget {
  final WatchHistory history;
  final VoidCallback? onDelete;

  const _HistoryCard({required this.history, this.onDelete});

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  final BangumiService _bangumiService = BangumiService();
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
    return GestureDetector(
      onTap: () {
        // 直接跳转到视频播放页
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
      onLongPress: widget.onDelete,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  width: 120,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
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
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: widget.history.progressPercent / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.history.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Text(
              '第${widget.history.lastWatchEpisode}集 ${widget.history.progressPercent.toStringAsFixed(0)}%',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
