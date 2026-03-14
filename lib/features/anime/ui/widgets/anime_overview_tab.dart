import 'package:flutter/material.dart';
import 'package:mikomi/config/themes/app_colors.dart';
import 'package:mikomi/core/models/bangumi_item.dart';

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
          LayoutBuilder(
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
                if (mounted &&
                    textPainter.didExceedMaxLines != _showExpandButton) {
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
                      child: Text(
                        _isExpanded ? '收起' : '加载更多',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          // 标签
          if (widget.bangumiItem.tags.isNotEmpty) ...[
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
