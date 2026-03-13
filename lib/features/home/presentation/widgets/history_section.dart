import 'package:flutter/material.dart';
import 'package:mikomi/shared/widgets/section_header.dart';
import 'package:mikomi/shared/widgets/anime_card.dart';
import 'package:mikomi/core/models/bangumi_item.dart';

class HistorySection extends StatelessWidget {
  final List<BangumiItem> bangumiList;

  const HistorySection({super.key, required this.bangumiList});

  @override
  Widget build(BuildContext context) {
    if (bangumiList.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: '播放记录', onMoreTap: () {}),
        SizedBox(
          height: 210,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: bangumiList.length,
            itemBuilder: (context, index) {
              final item = bangumiList[index];
              return AnimeCard(
                title: item.displayName,
                subtitle: '评分: ${item.ratingScore}',
                imageUrl: item.coverUrl,
                onTap: () {},
              );
            },
          ),
        ),
      ],
    );
  }
}
