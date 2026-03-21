import 'package:flutter/material.dart';
import 'package:mikomi/shared/utils/theme_extensions.dart';

class CommentTabWidget extends StatelessWidget {
  const CommentTabWidget.VideoComment({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: context.colors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无评论',
            style: TextStyle(fontSize: 16, color: context.colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            '快来发表第一条评论吧',
            style: TextStyle(fontSize: 13, color: context.colors.textHint),
          ),
        ],
      ),
    );
  }
}
