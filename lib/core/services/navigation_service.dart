import 'package:flutter/foundation.dart';

class NavigationService extends ChangeNotifier {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  int _selectedTab = 0;

  int get selectedTab => _selectedTab;

  void switchToTab(int index) {
    _selectedTab = index;
    notifyListeners();
  }

  void switchToMyPage() {
    switchToTab(2); // 个人页是索引2
  }
}
