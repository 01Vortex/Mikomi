import 'package:flutter/material.dart';
import 'package:mikomi/config/themes/app_colors.dart';
import 'package:mikomi/core/models/bangumi_item.dart';
import 'package:mikomi/core/services/bangumi_service.dart';
import 'package:mikomi/features/search/ui/widgets/search_app_bar.dart';
import 'package:mikomi/features/search/ui/widgets/search_results_view.dart';
import 'package:mikomi/features/search/ui/widgets/search_suggestions_view.dart';

class SearchResultsPage extends StatefulWidget {
  final String keyword;

  const SearchResultsPage({super.key, required this.keyword});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final BangumiService _bangumiService = BangumiService();

  List<BangumiItem> _searchResults = [];
  List<BangumiItem> _suggestions = [];
  bool _isSearching = true;
  bool _isLoadingSuggestions = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.keyword;
    _performSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    setState(() => _isSearching = true);

    final results = await _bangumiService.searchBangumi(widget.keyword);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  Future<void> _loadSuggestions(String keyword) async {
    if (keyword.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _isLoadingSuggestions = true;
      _showSuggestions = true;
    });

    final results = await _bangumiService.searchBangumi(keyword.trim());

    if (mounted) {
      setState(() {
        _suggestions = results.take(10).toList();
        _isLoadingSuggestions = false;
      });
    }
  }

  void _handleSearch() {
    if (_searchController.text.trim().isNotEmpty) {
      setState(() {
        _isSearching = true;
        _showSuggestions = false;
      });
      _bangumiService.searchBangumi(_searchController.text.trim()).then((
        results,
      ) {
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
        }
      });
    }
  }

  void _handleSuggestionTap(String keyword) {
    _searchController.text = keyword;
    _handleSearch();
  }

  void _handleClear() {
    _searchController.clear();
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SearchAppBar(
            controller: _searchController,
            focusNode: _focusNode,
            onChanged: (value) {
              setState(() {});
              _loadSuggestions(value);
            },
            onSubmitted: (value) => _handleSearch(),
            onClear: _handleClear,
            onSearch: _handleSearch,
          ),
          Expanded(
            child: _showSuggestions
                ? SearchSuggestionsView(
                    suggestions: _suggestions,
                    keyword: _searchController.text.trim(),
                    onTap: _handleSuggestionTap,
                    isLoading: _isLoadingSuggestions,
                  )
                : SearchResultsView(
                    results: _searchResults,
                    isLoading: _isSearching,
                  ),
          ),
        ],
      ),
    );
  }
}
