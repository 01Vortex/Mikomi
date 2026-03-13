import 'package:flutter/material.dart';
import 'package:mikomi/core/models/bangumi_item.dart';
import 'package:mikomi/shared/widgets/anime_grid_card.dart';
import 'package:mikomi/config/localization/app_localizations.dart';

class RecommendSection extends StatelessWidget {
  final List<BangumiItem> bangumiList;
  final VoidCallback? onLoadMore;
  final bool isLoading;

  const RecommendSection({
    super.key,
    required this.bangumiList,
    this.onLoadMore,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (bangumiList.isEmpty && !isLoading) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Text(
            AppLocalizations.of(context).recommend,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 7),
        if (bangumiList.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.58,
              ),
              itemCount: bangumiList.length,
              itemBuilder: (context, index) {
                final item = bangumiList[index];
                return AnimeGridCard(
                  title: item.displayName,
                  imageUrl: item.coverUrl,
                  onTap: () {},
                );
              },
            ),
          ),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
