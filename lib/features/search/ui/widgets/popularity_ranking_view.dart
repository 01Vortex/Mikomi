import 'package:flutter/material.dart';
import 'package:mikomi/config/themes/app_colors.dart';
import 'package:mikomi/core/models/bangumi_item.dart';

class PopularityRankingView extends StatelessWidget {
  final List<BangumiItem> rankings;
  final ValueChanged<BangumiItem> onTap;

  const PopularityRankingView({
    super.key,
    required this.rankings,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            '热度排行',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: rankings.length,
          itemBuilder: (context, index) {
            final item = rankings[index];
            return _buildRankingItem(item, index + 1);
          },
        ),
      ],
    );
  }

  Widget _buildRankingItem(BangumiItem item, int rank) {
    return InkWell(
      onTap: () => onTap(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            _buildRankBadge(rank),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (item.ratingScore > 0) ...[
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          item.ratingScore.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color badgeColor;
    if (rank == 1) {
      badgeColor = const Color(0xFFFFD700); // 金色
    } else if (rank == 2) {
      badgeColor = const Color(0xFFC0C0C0); // 银色
    } else if (rank == 3) {
      badgeColor = const Color(0xFFCD7F32); // 铜色
    } else {
      badgeColor = AppColors.textHint;
    }

    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: rank <= 3 ? badgeColor : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        rank.toString(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: rank <= 3 ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }
}
