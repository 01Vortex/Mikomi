import 'package:mikomi/core/models/bangumi_item.dart';

class SearchResult {
  final String sourceName;
  final List<BangumiItem> items;
  final bool isSuccess;
  final String? errorMessage;

  SearchResult({
    required this.sourceName,
    required this.items,
    this.isSuccess = true,
    this.errorMessage,
  });

  factory SearchResult.success(String sourceName, List<BangumiItem> items) {
    return SearchResult(sourceName: sourceName, items: items, isSuccess: true);
  }

  factory SearchResult.failure(String sourceName, String errorMessage) {
    return SearchResult(
      sourceName: sourceName,
      items: [],
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}
