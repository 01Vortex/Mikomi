import 'package:flutter/material.dart';
import 'package:mikomi/config/themes/app_colors.dart';
import 'package:mikomi/config/localization/app_localizations.dart';

class SearchAppBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onSearch;

  const SearchAppBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onSearch,
  });

  @override
  State<SearchAppBar> createState() => _SearchAppBarState();
}

class _SearchAppBarState extends State<SearchAppBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 8,
        16,
        12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.skeletonHighlight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 16, right: 8),
                    child: Icon(
                      Icons.search,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context).searchBangumi,
                        hintStyle: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.only(bottom: 12),
                      ),
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                    ),
                  ),
                  if (widget.controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(
                        Icons.clear,
                        size: 20,
                        color: AppColors.textHint,
                      ),
                      onPressed: widget.onClear,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 40,
            child: TextButton(
              onPressed: widget.onSearch,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(48, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(AppLocalizations.of(context).search),
            ),
          ),
        ],
      ),
    );
  }
}
