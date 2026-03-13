import 'package:flutter/material.dart';
import 'package:mikomi/config/themes/app_colors.dart';

class SearchHistoryView extends StatelessWidget {
  final List<String> history;
  final ValueChanged<String> onTap;
  final VoidCallback onClear;

  const SearchHistoryView({
    super.key,
    required this.history,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              '暂无搜索历史',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '搜索历史',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: onClear,
                    ),
                    const Icon(Icons.keyboard_arrow_down, size: 20),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: history.map((keyword) {
                return GestureDetector(
                  onTap: () => onTap(keyword),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.skeletonHighlight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      keyword,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
