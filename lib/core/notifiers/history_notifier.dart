import 'package:flutter/foundation.dart';

class HistoryNotifier extends ChangeNotifier {
  static final HistoryNotifier _instance = HistoryNotifier._internal();

  factory HistoryNotifier() => _instance;

  HistoryNotifier._internal();

  void notifyHistoryChanged() {
    notifyListeners();
  }
}
