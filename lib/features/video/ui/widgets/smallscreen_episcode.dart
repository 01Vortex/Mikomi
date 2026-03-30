import 'package:flutter/material.dart';
import 'package:mikomi/core/models/episode.dart';
import 'package:mikomi/shared/utils/theme_extensions.dart';
import 'package:mikomi/shared/widgets/scrolling_text.dart';

class SmallscreenEpisode extends StatelessWidget {
  final Episode episode;
  final bool isCurrent;
  final VoidCallback onTap;

  const SmallscreenEpisode({
    super.key,
    required this.episode,
    required this.isCurrent,
    required this.onTap,
  });

  bool get _hasTitle =>
      episode.title != null && episode.title!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: isCurrent
              ? context.colors.primaryLight
              : context.colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCurrent
                ? context.colors.primary
                : context.colors.outlineVariant,
            width: isCurrent ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: _hasTitle
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '第${episode.number}集',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isCurrent
                          ? context.colors.primary
                          : context.colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Flexible(
                    child: ScrollingText(
                      text: episode.title!,
                      style: TextStyle(
                        fontSize: 10,
                        color: context.colors.textSecondary,
                      ),
                      height: 13,
                    ),
                  ),
                ],
              )
            : Center(
                child: Text(
                  '第${episode.number}集',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isCurrent ? FontWeight.bold : FontWeight.w500,
                    color: isCurrent
                        ? context.colors.primary
                        : context.colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
      ),
    );
  }
}
