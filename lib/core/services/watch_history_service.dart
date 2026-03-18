import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:mikomi/core/models/watch_history.dart';
import 'package:mikomi/core/services/history_notifier.dart';

class WatchHistoryService {
  static const String _key = 'watch_history';
  static const int _maxHistoryCount = 50;
  final HistoryNotifier _notifier = HistoryNotifier();

  Future<List<WatchHistory>> getHistories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historiesJson = prefs.getString(_key);

      if (historiesJson == null) return [];

      final List<dynamic> decoded = json.decode(historiesJson);
      return decoded.map((item) => WatchHistory.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addHistory(WatchHistory history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final histories = await getHistories();

      histories.removeWhere((h) => h.bangumiId == history.bangumiId);
      histories.insert(0, history);

      if (histories.length > _maxHistoryCount) {
        histories.removeRange(_maxHistoryCount, histories.length);
      }

      final encoded = json.encode(histories.map((h) => h.toJson()).toList());
      await prefs.setString(_key, encoded);

      // 通知历史记录已变更
      _notifier.notifyHistoryChanged();
    } catch (e) {
      // 忽略错误
    }
  }

  Future<void> deleteHistory(int bangumiId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final histories = await getHistories();

      histories.removeWhere((h) => h.bangumiId == bangumiId);

      final encoded = json.encode(histories.map((h) => h.toJson()).toList());
      await prefs.setString(_key, encoded);

      // 通知历史记录已变更
      _notifier.notifyHistoryChanged();
    } catch (e) {
      // 忽略错误
    }
  }

  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);

      // 通知历史记录已变更
      _notifier.notifyHistoryChanged();
    } catch (e) {
      // 忽略错误
    }
  }
}
