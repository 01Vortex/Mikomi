import 'dart:convert';

import 'package:mikomi/features/my/models/collection_model.dart';
import 'package:mikomi/core/notifiers/collection_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CollectionService {
  static const String _key = 'collections';
  final CollectionNotifier _notifier = CollectionNotifier();

  Future<List<CollectionModel>> getCollections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_key);
      if (json == null) return [];
      final decoded = jsonDecode(json) as List<dynamic>;
      return decoded.map((e) => CollectionModel.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> isCollected(int bangumiId) async {
    final items = await getCollections();
    return items.any((e) => e.bangumiId == bangumiId);
  }

  Future<void> addCollection(CollectionModel item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final items = await getCollections();
      items.removeWhere((e) => e.bangumiId == item.bangumiId);
      items.insert(0, item);
      await prefs.setString(_key, jsonEncode(items.map((e) => e.toJson()).toList()));
      _notifier.notifyCollectionChanged();
    } catch (_) {}
  }

  Future<void> removeCollection(int bangumiId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final items = await getCollections();
      items.removeWhere((e) => e.bangumiId == bangumiId);
      await prefs.setString(_key, jsonEncode(items.map((e) => e.toJson()).toList()));
      _notifier.notifyCollectionChanged();
    } catch (_) {}
  }
}
