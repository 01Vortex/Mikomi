import 'package:flutter/material.dart';
import 'package:mikomi/shared/skeleton.dart';
import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/ui/widgets/episode_grid.dart';

class EpisodeTabContent extends StatelessWidget {
  final bool isLoading;
  final List<Episode> episodes;
  final bool isDescending;
  final bool isEpisodesExpanded;
  final int currentEpisode;
  final Function(Episode) onEpisodeSelected;
  final VoidCallback onToggleExpand;
  final VoidCallback onToggleSort;

  const EpisodeTabContent({
    super.key,
    required this.isLoading,
    required this.episodes,
    required this.isDescending,
    required this.isEpisodesExpanded,
    required this.currentEpisode,
    required this.onEpisodeSelected,
    required this.onToggleExpand,
    required this.onToggleSort,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && episodes.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 56),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 12,
              itemBuilder: (context, index) => const SkeletonEpisodeCard(),
            ),
          ),
        ],
      );
    }

    final sortedEpisodes =
        isDescending ? episodes.reversed.toList() : episodes;
    final displayCount =
        isEpisodesExpanded || episodes.length <= 12 ? episodes.length : 12;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: onToggleSort,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDescending
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isDescending ? '倒序' : '正序',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (episodes.length > 12)
                InkWell(
                  onTap: onToggleExpand,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isEpisodesExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isEpisodesExpanded ? '收起' : '展开',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: displayCount,
            itemBuilder: (context, index) {
              final episode = sortedEpisodes[index];
              return EpisodeGrid(
                episode: episode,
                isCurrent: episode.number == currentEpisode,
                onTap: () => onEpisodeSelected(episode),
              );
            },
          ),
        ),
      ],
    );
  }
}
