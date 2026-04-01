import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:mikomi/features/my/models/collection_item.dart';
import 'package:mikomi/core/services/collection_notifier.dart';

class CollectionService {
  static const String _key = 'collections';
  final CollectionNotifier _notifier = CollectionNotifier();

  Future<List<CollectionItem>> getCollections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? json = prefs.getString(_key);
      if (json == null) return [];
      final List<dynamic> decoded = jsonDecode(json);
      return decoded.map((e) => CollectionItem.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> isCollected(int bangumiId) async {
    final items = await getCollections();
    return items.any((e) => e.bangumiId == bangumiId);
  }

  Future<void> addCollection(CollectionItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final items = await getCollections();
      items.removeWhere((e) => e.bangumiId == item.bangumiId);
      items.insert(0, item);
      await prefs.setString(
        _key,
        jsonEncode(items.map((e) => e.toJson()).toList()),
      );
      _notifier.notifyCollectionChanged();
    } catch (e) {
      // 忽略错误
    }
  }

  Future<void> removeCollection(int bangumiId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final items = await getCollections();
      items.removeWhere((e) => e.bangumiId == bangumiId);
      await prefs.setString(
        _key,
        jsonEncode(items.map((e) => e.toJson()).toList()),
      );
      _notifier.notifyCollectionChanged();
    } catch (e) {
      // 忽略错误
    }
  }
}
