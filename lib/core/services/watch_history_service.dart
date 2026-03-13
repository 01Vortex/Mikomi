import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mikomi/core/models/watch_history.dart';

class WatchHistoryService {
  static const String _historyKey = 'watch_history';
  static const int _maxHistoryCount = 500;

  Future<List<WatchHistory>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_historyKey) ?? [];

      return historyJson
          .map((json) => WatchHistory.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addHistory(WatchHistory history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyList = await getHistory();

      historyList.removeWhere(
        (h) =>
            h.bangumiId == history.bangumiId &&
            h.episodeIndex == history.episodeIndex,
      );

      historyList.insert(0, history);

      if (historyList.length > _maxHistoryCount) {
        historyList.removeRange(_maxHistoryCount, historyList.length);
      }

      final historyJson = historyList
          .map((h) => jsonEncode(h.toJson()))
          .toList();

      await prefs.setStringList(_historyKey, historyJson);
    } catch (e) {
      // 忽略错误
    }
  }

  Future<void> removeHistory(int bangumiId, int episodeIndex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyList = await getHistory();

      historyList.removeWhere(
        (h) => h.bangumiId == bangumiId && h.episodeIndex == episodeIndex,
      );

      final historyJson = historyList
          .map((h) => jsonEncode(h.toJson()))
          .toList();

      await prefs.setStringList(_historyKey, historyJson);
    } catch (e) {
      // 忽略错误
    }
  }

  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (e) {
      // 忽略错误
    }
  }

  Future<WatchHistory?> getHistoryByBangumi(int bangumiId) async {
    try {
      final historyList = await getHistory();
      return historyList.firstWhere((h) => h.bangumiId == bangumiId);
    } catch (e) {
      return null;
    }
  }
}
