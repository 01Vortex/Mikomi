import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mikomi/config/app_theme.dart';
import 'package:mikomi/core/models/anime.dart';
import 'package:mikomi/features/search/repository/search_repository.dart';
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
  final SearchRepository _searchRepository = SearchRepository();

  List<Anime> _searchResults = [];
  List<Anime> _suggestions = [];
  bool _isSearching = true;
  bool _isLoadingSuggestions = false;
  bool _showSuggestions = false;
  Timer? _suggestionDebounce;
  int _suggestionRequestId = 0;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.keyword;
    _performSearch();
  }

  @override
  void dispose() {
    _suggestionDebounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    setState(() => _isSearching = true);

    final results = await _searchRepository.search(widget.keyword);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  Future<void> _loadSuggestions(String keyword) async {
    _suggestionDebounce?.cancel();
    final normalizedKeyword = keyword.trim();
    final requestId = ++_suggestionRequestId;

    if (normalizedKeyword.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _isLoadingSuggestions = false;
      });
      return;
    }

    setState(() {
      _showSuggestions = true;
    });

    _suggestionDebounce = Timer(const Duration(milliseconds: 280), () async {
      if (!mounted || requestId != _suggestionRequestId) return;

      setState(() {
        _isLoadingSuggestions = true;
      });

      final results = await _searchRepository.searchSuggestions(
        normalizedKeyword,
      );

      if (mounted && requestId == _suggestionRequestId) {
        setState(() {
          _suggestions = results;
          _isLoadingSuggestions = false;
        });
      }
    });
  }

  void _handleSearch() {
    if (_searchController.text.trim().isNotEmpty) {
      setState(() {
        _isSearching = true;
        _showSuggestions = false;
      });
      _searchRepository.search(_searchController.text.trim()).then((results) {
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
