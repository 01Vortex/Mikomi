import 'package:flutter/material.dart';
import 'package:mikomi/core/models/watch_history.dart';
import 'package:mikomi/shared/widgets/cached_image.dart';
import 'package:mikomi/core/services/bangumi_service.dart';

class WatchHistoryCard extends StatefulWidget {
  final WatchHistory history;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onLongPress;
  final bool showDelete;
  final double cardHeight;

  const WatchHistoryCard({
    super.key,
    required this.history,
    required this.onTap,
    this.onDelete,
    this.onLongPress,
    this.showDelete = false,
    this.cardHeight = 120,
  });

  @override
  State<WatchHistoryCard> createState() => _WatchHistoryCardState();
}

class _WatchHistoryCardState extends State<WatchHistoryCard> {
  final BangumiService _bangumiService = BangumiService();
  String _coverUrl = '';

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
    final theme = Theme.of(context);
    final imageWidth = widget.cardHeight * 0.7;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: SizedBox(
          height: widget.cardHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedImage(
                  imageUrl: _coverUrl,
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
              if (widget.showDelete && widget.onDelete != null)
                IconButton(
                  icon: Icon(Icons.delete, color: theme.colorScheme.error),
                  onPressed: widget.onDelete,
                ),
            ],
          ),
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

    if (diff.inDays > 0) {
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
