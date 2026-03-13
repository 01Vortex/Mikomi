import 'package:flutter/material.dart';
import 'package:mikomi/config/themes/app_colors.dart';
import 'package:mikomi/core/models/bangumi_item.dart';

class SearchSuggestionsView extends StatelessWidget {
  final List<BangumiItem> suggestions;
  final String keyword;
  final ValueChanged<String> onTap;
  final bool isLoading;

  const SearchSuggestionsView({
    super.key,
    required this.suggestions,
    required this.keyword,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final item = suggestions[index];
        final displayName = item.displayName;

        return InkWell(
          onTap: () => onTap(displayName),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.search, size: 20, color: AppColors.textHint),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      children: _buildHighlightedText(displayName, keyword),
                    ),
                  ),
                ),
                const Icon(
                  Icons.north_west,
                  size: 16,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<TextSpan> _buildHighlightedText(String text, String keyword) {
    if (keyword.isEmpty) {
      return [TextSpan(text: text)];
    }

    final lowerText = text.toLowerCase();
    final lowerKeyword = keyword.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerKeyword, start);
      if (index == -1) {
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start)));
        }
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + keyword.length),
          style: const TextStyle(color: AppColors.primary),
        ),
      );

      start = index + keyword.length;
    }

    return spans;
  }
}
