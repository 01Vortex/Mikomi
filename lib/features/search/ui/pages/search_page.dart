import 'package:flutter/material.dart';
import 'package:mikomi/config/themes/app_colors.dart';
import 'package:mikomi/core/services/bangumi_service.dart';
import 'package:mikomi/core/services/search_history_service.dart';
import 'package:mikomi/core/models/bangumi_item.dart';
import 'package:mikomi/core/utils/popularity_algorithm.dart';
import 'package:mikomi/features/search/ui/widgets/search_app_bar.dart';
import 'package:mikomi/features/search/ui/widgets/search_history_view.dart';
import 'package:mikomi/features/search/ui/widgets/search_suggestions_view.dart';
import 'package:mikomi/features/search/ui/widgets/popularity_ranking_view.dart';
import 'package:mikomi/features/search/ui/pages/search_results_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final BangumiService _bangumiService = BangumiService();
  final SearchHistoryService _historyService = SearchHistoryService();
  final FocusNode _focusNode = FocusNode();

  List<String> _searchHistory = [];
  List<BangumiItem> _suggestions = [];
  List<BangumiItem> _popularityRankings = [];
  bool _showHistory = true;
  bool _isLoadingSuggestions = false;
  bool _isLoadingRankings = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadPopularityRankings();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await _historyService.getHistory();
    setState(() {
      _searchHistory = history;
    });
  }

  Future<void> _loadPopularityRankings() async {
    setState(() => _isLoadingRankings = true);

    final allItems = await _bangumiService.getRecommendedList(limit: 50);
    final rankings = PopularityAlgorithm.getPopularityRanking(
      allItems,
      limit: 10,
    );

    if (mounted) {
      setState(() {
        _popularityRankings = rankings;
        _isLoadingRankings = false;
      });
    }
  }

  Future<void> _performSearch(String keyword) async {
    if (keyword.trim().isEmpty) return;

    await _historyService.addHistory(keyword.trim());
    await _loadHistory();

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsPage(keyword: keyword.trim()),
        ),
      ).then((_) {
        _searchController.clear();
        setState(() {
          _suggestions = [];
          _showHistory = true;
        });
      });
    }
  }

  Future<void> _loadSuggestions(String keyword) async {
    if (keyword.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showHistory = true;
      });
      return;
    }

    setState(() {
      _isLoadingSuggestions = true;
      _showHistory = false;
    });

    final results = await _bangumiService.searchBangumi(keyword.trim());

    if (mounted) {
      setState(() {
        _suggestions = results.take(10).toList();
        _isLoadingSuggestions = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    await _historyService.clearHistory();
    await _loadHistory();
  }

  void _handleClear() {
    _searchController.clear();
    setState(() {
      _showHistory = true;
      _suggestions = [];
    });
  }

  void _handleHistoryTap(String keyword) {
    _searchController.text = keyword;
    _performSearch(keyword);
  }

  void _handleSuggestionTap(String keyword) {
    _searchController.text = keyword;
    _performSearch(keyword);
  }

  void _handleRankingTap(BangumiItem item) {
    _searchController.text = item.displayName;
    _performSearch(item.displayName);
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
            onSubmitted: _performSearch,
            onClear: _handleClear,
            onSearch: () {
              if (_searchController.text.isNotEmpty) {
                _performSearch(_searchController.text);
              }
            },
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_showHistory) {
      return SingleChildScrollView(
        child: Column(
          children: [
            SearchHistoryView(
              history: _searchHistory,
              onTap: _handleHistoryTap,
              onClear: _clearHistory,
            ),
            if (_isLoadingRankings)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )
            else if (_popularityRankings.isNotEmpty)
              PopularityRankingView(
                rankings: _popularityRankings,
                onTap: _handleRankingTap,
              ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    return SearchSuggestionsView(
      suggestions: _suggestions,
      keyword: _searchController.text.trim(),
      onTap: _handleSuggestionTap,
      isLoading: _isLoadingSuggestions,
    );
  }
}
