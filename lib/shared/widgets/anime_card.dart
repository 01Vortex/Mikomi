import 'package:flutter/material.dart';
import 'package:mikomi/shared/widgets/scrolling_text.dart';

class AnimeCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const AnimeCard({
    super.key,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.onTap,
    this.width = 120,
    this.height = 160,
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
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.image_not_supported, size: 40),
                          );
                        },
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.image, size: 40, color: Colors.grey),
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
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
