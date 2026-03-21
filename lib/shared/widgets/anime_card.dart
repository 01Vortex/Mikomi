import 'package:flutter/material.dart';
import 'package:mikomi/shared/widgets/scrolling_text.dart';
import 'package:mikomi/config/themes/app_colors.dart';
import 'package:mikomi/shared/widgets/cached_image.dart';
import 'package:mikomi/core/providers/theme_animation_provider.dart';

class AnimeCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final VoidCallback? onTap;
  final double width;
  final double height;
  final String? heroTag;

  const AnimeCard({
    super.key,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.onTap,
    this.width = 120,
    this.height = 160,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: heroTag != null
                  ? Hero(
                      tag: heroTag!,
                      transitionOnUserGestures: true,
                      flightShuttleBuilder:
                          AnimationProvider.buildHeroFlightShuttle,
                      child: CachedImage(
                        imageUrl: imageUrl ?? '',
                        width: width,
                        height: height,
                        fit: BoxFit.cover,
                      ),
                    )
                  : CachedImage(
                      imageUrl: imageUrl ?? '',
                      width: width,
                      height: height,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(height: 6),
            ScrollingText(
              text: title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
