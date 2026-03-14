import 'package:flutter/material.dart';
import 'package:mikomi/config/themes/app_colors.dart';

class AnimeTucaoTab extends StatelessWidget {
  const AnimeTucaoTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '吐槽功能开发中',
        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
    );
  }
}
