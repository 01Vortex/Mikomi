import 'package:flutter/material.dart';
import 'package:mikomi/core/models/collection_item.dart';
import 'package:mikomi/core/services/collection_service.dart';
import 'package:mikomi/core/services/collection_notifier.dart';
import 'package:mikomi/features/anime/ui/pages/anime_page.dart';
import 'package:mikomi/core/services/bangumi_service.dart';
import 'package:mikomi/shared/utils/theme_extensions.dart';
import 'package:mikomi/shared/widgets/cached_image.dart';
import 'package:mikomi/shared/widgets/skeleton.dart';
import 'package:mikomi/shared/widgets/scrolling_text.dart';

class CollectTabContent extends StatefulWidget {
  const CollectTabContent({super.key});

  @override
  State<CollectTabContent> createState() => _CollectTabContentState();
}

class _CollectTabContentState extends State<CollectTabContent> {
  final CollectionService _service = CollectionService();
  final CollectionNotifier _notifier = CollectionNotifier();
  List<CollectionItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _notifier.addListener(_load);
  }

  @override
  void dispose() {
    _notifier.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final items = await _service.getCollections();
    if (mounted) {
      setState(() {
        _items = items;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          : _items.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  '暂无收藏',
                  style: TextStyle(color: context.colors.textSecondary),
                ),
              ),
            )
          : Column(
              children: _items
                  .map(
                    (item) => _CollectionItemCard(
                      key: ValueKey(item.bangumiId),
                      item: item,
                      onDeleted: _load,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _CollectionItemCard extends StatefulWidget {
  final CollectionItem item;
  final VoidCallback onDeleted;

  const _CollectionItemCard({
    super.key,
    required this.item,
    required this.onDeleted,
  });

  @override
  State<_CollectionItemCard> createState() => _CollectionItemCardState();
}

class _CollectionItemCardState extends State<_CollectionItemCard> {
  final BangumiService _bangumiService = BangumiService();
  final CollectionService _collectionService = CollectionService();

  Future<void> _onTap() async {
    final bangumi = await _bangumiService.getBangumiById(
      widget.item.bangumiId,
    );
    if (!mounted || bangumi == null) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AnimePage(bangumiItem: bangumi),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  Future<void> _onLongPress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('取消收藏'),
        content: Text('确认取消收藏《${widget.item.displayName}》吗?'),
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
            child: const Text('确认'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _collectionService.removeCollection(widget.item.bangumiId);
      widget.onDeleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _onTap,
      onLongPress: _onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: widget.item.coverUrl.isEmpty
                  ? SkeletonLoader(
                      width: 80,
                      height: 110,
                      borderRadius: BorderRadius.circular(8),
                    )
                  : CachedImage(
                      imageUrl: widget.item.coverUrl,
                      width: 80,
                      height: 110,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ScrollingText(
                    text: widget.item.displayName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: context.colors.onSurface,
                    ),
                    height: 22,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(widget.item.collectedAt),
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

  String _formatDate(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays > 3) {
      return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} 收藏';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}天前收藏';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}小时前收藏';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分钟前收藏';
    } else {
      return '刚刚收藏';
    }
  }
}
