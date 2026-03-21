import 'package:flutter/material.dart';
import 'package:mikomi/config/themes/app_colors.dart';
import 'package:mikomi/core/models/bangumi_item.dart';
import 'package:mikomi/shared/widgets/skeleton.dart';

class AnimeOverviewTab extends StatefulWidget {
  final BangumiItem bangumiItem;

  const AnimeOverviewTab({super.key, required this.bangumiItem});

  @override
  State<AnimeOverviewTab> createState() => _AnimeOverviewTabState();
}

class _AnimeOverviewTabState extends State<AnimeOverviewTab> {
  bool _isExpanded = false;
  bool _showExpandButton = false;
  bool _showAllTags = false;
  static const int _maxLines = 4;
  static const int _maxVisibleTags = 9;

  @override
  Widget build(BuildContext context) {
    final hasMoreTags = widget.bangumiItem.tags.length > _maxVisibleTags;
    final displayTags = _showAllTags
        ? widget.bangumiItem.tags
        : widget.bangumiItem.tags.take(_maxVisibleTags).toList();

    // 判断是否正在加载
    final isLoading =
        widget.bangumiItem.summary.isEmpty &&
        widget.bangumiItem.ratingCount == 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 简介标题
          const Text(
            '简介',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // 简介内容
          if (isLoading) _buildSummarySkeleton() else _buildSummaryContent(),
          // 标签
          if (isLoading)
            _buildTagsSkeleton()
          else if (widget.bangumiItem.tags.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              '标签',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...displayTags.map((tag) => _buildTagChip(tag)),
                if (hasMoreTags)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showAllTags = !_showAllTags;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.divider),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _showAllTags ? '收起' : '更多',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _showAllTags ? Icons.remove : Icons.add,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummarySkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonText(width: double.infinity, height: 14),
        const SizedBox(height: 8),
        const SkeletonText(width: double.infinity, height: 14),
        const SizedBox(height: 8),
        const SkeletonText(width: double.infinity, height: 14),
        const SizedBox(height: 8),
        SkeletonText(
          width: MediaQuery.of(context).size.width * 0.6,
          height: 14,
        ),
      ],
    );
  }

  Widget _buildTagsSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          '标签',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            6,
            (index) => SkeletonLoader(
              width: 80 + (index % 3) * 20,
              height: 32,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(
          text: widget.bangumiItem.summary.isEmpty
              ? '暂无简介'
              : widget.bangumiItem.summary,
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: AppColors.textSecondary,
          ),
        );

        final textPainter = TextPainter(
          text: textSpan,
          maxLines: _maxLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && textPainter.didExceedMaxLines != _showExpandButton) {
            setState(() {
              _showExpandButton = textPainter.didExceedMaxLines;
            });
          }
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.bangumiItem.summary.isEmpty
                  ? '暂无简介'
                  : widget.bangumiItem.summary,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
              maxLines: _isExpanded ? null : _maxLines,
              overflow: _isExpanded ? null : TextOverflow.ellipsis,
            ),
            if (_showExpandButton) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: const Text(
                  '加载更多',
                  style: TextStyle(fontSize: 14, color: AppColors.primary),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTagChip(BangumiTag tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag.name,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 4),
          Text(
            '${tag.count}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
