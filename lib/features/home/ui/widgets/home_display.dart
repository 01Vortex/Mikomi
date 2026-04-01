import 'package:flutter/material.dart';
import 'package:mikomi/core/models/anime.dart';
import 'package:mikomi/shared/widgets/anime_grid_card.dart';
import 'package:mikomi/config/routes/app_routes.dart';

class HomeDisplay extends StatelessWidget {
  final List<Anime> bangumiList;
  final VoidCallback? onLoadMore;
  final bool isLoading;

  const HomeDisplay({
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
                  heroTag: 'bangumi_${item.id}',
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.bangumiDetail,
                      arguments: item,
                    );
                  },
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
