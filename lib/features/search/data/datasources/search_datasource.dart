import 'package:mikomi/core/models/bangumi_item.dart';

abstract class SearchDatasource {
  String get sourceName;
  int get priority;
  Future<List<BangumiItem>> search(String keyword);
}
