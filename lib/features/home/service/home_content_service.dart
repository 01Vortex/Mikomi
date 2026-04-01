import 'package:mikomi/features/home/data/repositories/home_repository.dart';
import 'package:mikomi/features/home/models/home_anime_model.dart';

class HomeFeedData {
  final HomeRepository _repository = HomeRepository();

  Future<List<HomeAnimeModel>> getRecommendedList({
    int limit = 12,
    int offset = 0,
  }) {
    return _repository.getRecommendedList(limit: limit, offset: offset);
  }

  Future<List<HomeAnimeModel>> getBannerList({int count = 5}) {
    return _repository.getBannerList(count: count);
  }

  Future<List<List<HomeAnimeModel>>> getCalendar() {
    return _repository.getCalendar();
  }
}
