import 'package:flutter/material.dart';
import 'package:mikomi/config/themes/app_colors.dart';
import 'package:mikomi/config/localization/app_localizations.dart';

class PilgrimagePage extends StatelessWidget {
  const PilgrimagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).pilgrimageMap),
        backgroundColor: AppColors.surface,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).pilgrimageDeveloping,
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).comingSoon,
              style: TextStyle(fontSize: 14, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}
