import 'dart:convert';

import 'package:mikomi/features/my/models/history_model.dart';
import 'package:mikomi/core/notifiers/history_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryModelService {
  static const String _key = 'watch_history';
  static const int _maxHistoryCount = 50;
  final HistoryNotifier _notifier = HistoryNotifier();

  Future<List<HistoryModel>> getHistories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historiesJson = prefs.getString(_key);
      if (historiesJson == null) return [];

      final decoded = json.decode(historiesJson) as List<dynamic>;
      return decoded.map((item) => HistoryModel.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addHistory(HistoryModel history) async {
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
      _notifier.notifyHistoryChanged();
    } catch (_) {}
  }

  Future<void> deleteHistory(int bangumiId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final histories = await getHistories();
      histories.removeWhere((h) => h.bangumiId == bangumiId);

      final encoded = json.encode(histories.map((h) => h.toJson()).toList());
      await prefs.setString(_key, encoded);
      _notifier.notifyHistoryChanged();
    } catch (_) {}
  }

  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
      _notifier.notifyHistoryChanged();
    } catch (_) {}
  }
}
