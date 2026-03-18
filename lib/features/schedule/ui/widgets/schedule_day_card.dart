import 'package:flutter/material.dart';
import 'package:mikomi/core/models/bangumi_item.dart';
import 'package:mikomi/shared/widgets/cached_image.dart';
import 'package:mikomi/shared/widgets/scrolling_text.dart';

class ScheduleDayCard extends StatelessWidget {
  final BangumiItem bangumiItem;
  final double cardHeight;
  final VoidCallback onBangumiTap;

  const ScheduleDayCard({
    super.key,
    required this.bangumiItem,
    required this.cardHeight,
    required this.onBangumiTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageWidth = cardHeight * 0.7;
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onBangumiTap,
        child: SizedBox(
          height: cardHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedImage(
                  imageUrl: bangumiItem.coverUrl,
                  width: imageWidth,
                  height: cardHeight,
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
                      ScrollingText(
                        text: bangumiItem.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        height: 40,
                      ),
                      const SizedBox(height: 4),
                      if ((bangumiItem.info.isNotEmpty) ||
                          (bangumiItem.summary.isNotEmpty))
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                bangumiItem.info.isNotEmpty
                                    ? bangumiItem.info
                                    : bangumiItem.summary,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      const Spacer(),
                      Row(
                        children: [
                          if (bangumiItem.ratingScore > 0) ...[
                            Icon(
                              Icons.star_rounded,
                              size: 15,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              bangumiItem.ratingScore.toStringAsFixed(1),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (bangumiItem.rank > 0) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.leaderboard,
                              size: 15,
                              color: theme.colorScheme.tertiary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'Rank ${bangumiItem.rank}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (bangumiItem.ratingCount > 0)
                            Text(
                              '${bangumiItem.ratingCount}人',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
