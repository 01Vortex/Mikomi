import 'package:flutter/foundation.dart';

class CollectionNotifier extends ChangeNotifier {
  static final CollectionNotifier _instance = CollectionNotifier._internal();

  factory CollectionNotifier() => _instance;

  CollectionNotifier._internal();

  void notifyCollectionChanged() {
    notifyListeners();
  }
}
