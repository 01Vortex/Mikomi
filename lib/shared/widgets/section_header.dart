import 'package:flutter/material.dart';
import 'package:mikomi/config/themes/app_colors.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? moreText;
  final VoidCallback? onMoreTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.moreText,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          GestureDetector(
            onTap: onMoreTap,
            child: Text(
              moreText ?? '更多',
              style: TextStyle(
                fontSize: 14,
                color: onMoreTap == null
                    ? AppColors.textHint
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
