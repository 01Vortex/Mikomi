import 'package:mikomi/features/home/models/home_anime_model.dart';

class RankRecord {
  final HomeAnimeModel item;
  final int metric;

  const RankRecord({required this.item, required this.metric});
}
