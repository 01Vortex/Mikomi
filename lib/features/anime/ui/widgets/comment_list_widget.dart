import 'package:flutter/material.dart';
import 'package:mikomi/config/themes/app_colors.dart';
import 'package:mikomi/shared/widgets/cached_image.dart';
import 'package:mikomi/shared/widgets/skeleton.dart';
import 'package:intl/intl.dart';

class CommentListWidget<T> extends StatefulWidget {
  final List<T> comments;
  final bool isLoading;
  final VoidCallback onRetry;
  final String Function(T) getUserNickname;
  final String Function(T) getUserAvatar;
  final String Function(T) getContent;
  final int Function(T) getCreatedAt;
  final List<T> Function(T) getReplies;

  const CommentListWidget({
    super.key,
    required this.comments,
    required this.isLoading,
    required this.onRetry,
    required this.getUserNickname,
    required this.getUserAvatar,
    required this.getContent,
    required this.getCreatedAt,
    required this.getReplies,
  });

  @override
  State<CommentListWidget<T>> createState() => _CommentListWidgetState<T>();
}

class _CommentListWidgetState<T> extends State<CommentListWidget<T>> {
  final Set<int> _expandedComments = {};

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays == 1) {
      return '昨天 ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return DateFormat('yyyy-MM-dd HH:mm').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildCommentsSkeleton();
    }

    if (widget.comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('暂无评论'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: widget.onRetry, child: const Text('重试')),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: widget.comments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final comment = widget.comments[index];
        return _buildCommentItem(comment, index);
      },
    );
  }

  Widget _buildCommentsSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 24),
      itemBuilder: (context, index) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonCircle(size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(width: 100, height: 14),
                const SizedBox(height: 8),
                SkeletonText(width: double.infinity, height: 14),
                const SizedBox(height: 4),
                SkeletonText(width: double.infinity, height: 14),
                const SizedBox(height: 4),
                SkeletonText(width: 200, height: 14),
                const SizedBox(height: 8),
                SkeletonText(width: 80, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(T comment, int index) {
    final isExpanded = _expandedComments.contains(index);
    final replies = widget.getReplies(comment);
    final hasReplies = replies.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipOval(
              child: CachedImage(
                imageUrl: widget.getUserAvatar(comment),
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.getUserNickname(comment),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.getContent(comment),
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(widget.getCreatedAt(comment)),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (hasReplies) ...[
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedComments.remove(index);
                } else {
                  _expandedComments.add(index);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 60),
              child: Row(
                children: [
                  Container(width: 40, height: 1, color: AppColors.divider),
                  const SizedBox(width: 8),
                  Text(
                    isExpanded
                        ? '收起${replies.length}条回复'
                        : '展开${replies.length}条回复',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
        if (isExpanded && hasReplies) ...[
          const SizedBox(height: 16),
          ...replies.map(
            (reply) => Padding(
              padding: const EdgeInsets.only(left: 60, bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipOval(
                    child: CachedImage(
                      imageUrl: widget.getUserAvatar(reply),
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.getUserNickname(reply),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.getContent(reply),
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatDate(widget.getCreatedAt(reply)),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
