import 'package:flutter/material.dart';
import 'package:mikomi/config/themes/app_colors.dart';
import 'package:mikomi/shared/widgets/cached_image.dart';
import 'package:mikomi/shared/widgets/skeleton.dart';

class PersonInfoWidget extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String nameCN;
  final String info;
  final String summary;
  final String summaryTitle;
  final bool isLoading;
  final VoidCallback onRetry;

  const PersonInfoWidget({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.nameCN,
    required this.info,
    required this.summary,
    required this.summaryTitle,
    required this.isLoading,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildSkeleton();
    }

    if (imageUrl.isEmpty && name.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('加载失败'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedImage(
              imageUrl: imageUrl,
              width: 120,
              height: 180,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (nameCN.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    nameCN,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (info.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    '基本信息',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    info,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    summaryTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    summary,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(
            width: 120,
            height: 180,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(width: 150, height: 18),
                const SizedBox(height: 8),
                SkeletonText(width: 100, height: 14),
                const SizedBox(height: 16),
                SkeletonText(width: 80, height: 14),
                const SizedBox(height: 8),
                SkeletonText(width: double.infinity, height: 13),
                const SizedBox(height: 4),
                SkeletonText(width: double.infinity, height: 13),
                const SizedBox(height: 4),
                SkeletonText(width: 200, height: 13),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
