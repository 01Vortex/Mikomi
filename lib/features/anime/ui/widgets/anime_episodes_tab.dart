import 'package:flutter/material.dart';
import 'package:mikomi/config/themes/app_colors.dart';

class AnimeEpisodesTab extends StatelessWidget {
  const AnimeEpisodesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '剧集列表开发中',
        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
    );
  }
}
