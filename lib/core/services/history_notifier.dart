import 'package:flutter/foundation.dart';

/// 观看历史变更通知器
/// 用于在不同页面间同步历史记录的变更
class HistoryNotifier extends ChangeNotifier {
  static final HistoryNotifier _instance = HistoryNotifier._internal();

  factory HistoryNotifier() => _instance;

  HistoryNotifier._internal();

  /// 通知历史记录已变更
  void notifyHistoryChanged() {
    notifyListeners();
  }
}
