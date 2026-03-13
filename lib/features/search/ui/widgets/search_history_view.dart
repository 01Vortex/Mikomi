import 'package:flutter/material.dart';
import 'package:mikomi/config/themes/app_colors.dart';

class SearchHistoryView extends StatefulWidget {
  final List<String> history;
  final ValueChanged<String> onTap;
  final VoidCallback onClear;

  const SearchHistoryView({
    super.key,
    required this.history,
    required this.onTap,
    required this.onClear,
  });

  @override
  State<SearchHistoryView> createState() => _SearchHistoryViewState();
}

class _SearchHistoryViewState extends State<SearchHistoryView> {
  bool _isExpanded = false;
  final double _maxCollapsedHeight = 130;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '搜索历史',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: widget.onClear,
                  ),
                  if (_shouldShowExpandButton())
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 20,
                      ),
                    )
                  else
                    const Icon(Icons.keyboard_arrow_down, size: 20),
                ],
              ),
            ],
          ),
        ),
        if (widget.history.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: Center(
              child: Text(
                '暂无搜索历史',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ),
          )
        else
          _buildHistoryTags(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHistoryTags() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: _isExpanded ? 500 : _maxCollapsedHeight,
          ),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.history.map((keyword) {
                return GestureDetector(
                  onTap: () => widget.onTap(keyword),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.skeletonHighlight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      keyword,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  bool _shouldShowExpandButton() {
    return widget.history.length > 6;
  }
}
