import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const String _historyKey = 'search_history';
  static const int _maxHistoryCount = 20;

  Future<List<String>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_historyKey) ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<void> addHistory(String keyword) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getHistory();

      history.remove(keyword);
      history.insert(0, keyword);

      if (history.length > _maxHistoryCount) {
        history.removeRange(_maxHistoryCount, history.length);
      }

      await prefs.setStringList(_historyKey, history);
    } catch (e) {
      // 忽略错误
    }
  }

  Future<void> removeHistory(String keyword) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getHistory();

      history.remove(keyword);

      await prefs.setStringList(_historyKey, history);
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
}
