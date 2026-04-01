import 'package:flutter/material.dart';
import 'package:mikomi/shared/scrolling_text.dart';
import 'package:mikomi/shared/cached_image.dart';
import 'package:mikomi/core/providers/app_theme_provider.dart';

class AnimeGridCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final VoidCallback? onTap;
  final String? heroTag;

  const AnimeGridCard({
    super.key,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.onTap,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: heroTag != null
                  ? Hero(
                      tag: heroTag!,
                      transitionOnUserGestures: true,
                      flightShuttleBuilder:
                          AnimationProvider.buildHeroFlightShuttle,
                      child: CachedImage(
                        imageUrl: imageUrl ?? '',
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  : CachedImage(
                      imageUrl: imageUrl ?? '',
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(height: 6),
          ScrollingText(
            text: title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
