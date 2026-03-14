import 'package:flutter/material.dart';
import 'package:mikomi/config/themes/app_colors.dart';
import 'package:mikomi/core/models/bangumi_item.dart';
import 'package:mikomi/shared/widgets/anime_grid_card.dart';
import 'package:mikomi/config/localization/app_localizations.dart';
import 'package:mikomi/config/routes/app_routes.dart';

class SearchResultsView extends StatelessWidget {
  final List<BangumiItem> results;
  final bool isLoading;

  const SearchResultsView({
    super.key,
    required this.results,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).noResults,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.58,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return AnimeGridCard(
          title: item.displayName,
          imageUrl: item.coverUrl,
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.bangumiDetail,
              arguments: item,
            );
          },
        );
      },
    );
  }
}
