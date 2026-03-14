import 'package:flutter/material.dart';
import 'package:mikomi/config/themes/app_colors.dart';

class AnimeCommentsTab extends StatelessWidget {
  const AnimeCommentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '评论功能开发中',
        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
    );
  }
}
