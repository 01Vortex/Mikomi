import 'package:flutter/material.dart';
import 'package:mikomi/features/home/models/home_anime_model.dart';
import 'package:mikomi/shared/anime_detil_converter.dart';
import 'package:mikomi/shared/anime_grid_card.dart';

class HomeDisplay extends StatelessWidget {
  final List<HomeAnimeModel> animeList;
  final VoidCallback? onLoadMore;
  final bool isLoading;

  const HomeDisplay({
    super.key,
    required this.animeList,
    this.onLoadMore,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (animeList.isEmpty && !isLoading) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (animeList.isNotEmpty)
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
              itemCount: animeList.length,
              itemBuilder: (context, index) {
                final item = animeList[index];
                return AnimeGridCard(
                  title: item.displayName,
                  imageUrl: item.coverUrl,
                  heroTag: 'anime_${item.id}',
                  onTap: () => AnimeDetilConverter.openBangumiDetail(
                    context,
                    item,
                  ),
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
