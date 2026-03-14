import 'package:flutter/material.dart';
import 'package:mikomi/config/themes/app_colors.dart';
import 'package:mikomi/core/models/comment_item.dart';
import 'package:mikomi/shared/widgets/cached_image.dart';

class CommentCard extends StatelessWidget {
  final CommentItem commentItem;

  const CommentCard({super.key, required this.commentItem});

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()}年前';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}个月前';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}天前';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}小时前';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: CachedImage(
              imageUrl: commentItem.user.avatar.large,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        commentItem.user.nickname,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(commentItem.comment.updatedAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (commentItem.comment.rate > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < (commentItem.comment.rate / 2).floor()
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 16,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ),
                Text(
                  commentItem.comment.comment,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
