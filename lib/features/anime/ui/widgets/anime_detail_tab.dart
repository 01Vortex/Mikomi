import 'package:flutter/material.dart';
import 'package:mikomi/config/themes/app_colors.dart';
import 'package:mikomi/core/models/bangumi_item.dart';

class AnimeDetailTab extends StatelessWidget {
  final BangumiItem bangumiItem;

  const AnimeDetailTab({super.key, required this.bangumiItem});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '详细信息',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('放送日期', bangumiItem.airDate),
          if (bangumiItem.rank > 0)
            _buildInfoRow('Bangumi排行', '#${bangumiItem.rank}'),
          if (bangumiItem.ratingScore > 0)
            _buildInfoRow('评分', bangumiItem.ratingScore.toStringAsFixed(1)),
          if (bangumiItem.ratingCount > 0)
            _buildInfoRow('评分人数', '${bangumiItem.ratingCount}人'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '未知' : value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
