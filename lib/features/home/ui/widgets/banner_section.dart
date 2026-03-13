import 'package:flutter/material.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:mikomi/config/themes/app_colors.dart';
import 'package:mikomi/core/models/bangumi_item.dart';
import 'package:mikomi/shared/widgets/cached_image.dart';

class BannerSection extends StatefulWidget {
  final List<BangumiItem> bannerList;

  const BannerSection({super.key, this.bannerList = const []});

  @override
  State<BannerSection> createState() => _BannerSectionState();
}

class _BannerSectionState extends State<BannerSection> {
  @override
  Widget build(BuildContext context) {
    if (widget.bannerList.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.placeholder,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.image, size: 60, color: AppColors.placeholderIcon),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      height: 180,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Swiper(
          itemCount: widget.bannerList.length,
          autoplay: true,
          autoplayDelay: 4000,
          duration: 600,
          viewportFraction: 0.92,
          scale: 0.94,
          itemBuilder: (context, index) {
            final item = widget.bannerList[index];
            return GestureDetector(
              onTap: () {
                // TODO: 跳转到详情页
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedImage(
                        imageUrl: item.coverUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(color: Colors.black45, blurRadius: 4),
                              ],
                            ),
                          ),
                          if (item.ratingScore > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.ratingScore.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          pagination: SwiperPagination(
            margin: const EdgeInsets.only(bottom: 8),
            builder: DotSwiperPaginationBuilder(
              size: 6,
              activeSize: 8,
              color: Colors.white.withValues(alpha: 0.5),
              activeColor: Colors.white,
              space: 4,
            ),
          ),
        ),
      ),
    );
  }
}
