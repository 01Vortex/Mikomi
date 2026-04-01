import 'package:mikomi/core/models/bangumi_item.dart';

class RankRecord {
  final BangumiItem item;
  final int metric;

  const RankRecord({required this.item, required this.metric});
}
