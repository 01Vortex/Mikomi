import 'package:mikomi/features/home/models/home_anime_model.dart';
import 'package:mikomi/core/network/api_constants.dart';
import 'package:mikomi/core/network/dio_client.dart';
import 'package:mikomi/features/home/service/display_service.dart';
import 'package:mikomi/features/home/service/slider_image_service.dart';

class HomeFeedData {
  final DioClient _dioClient = DioClient();

  Future<List<HomeAnimeModel>> getRecommendedList({
    int limit = 12,
    int offset = 0,
  }) async {
    try {
      final fetchLimit = offset + limit + 24;

      final response = await _dioClient.get(
        ApiConstants.bangumiApiNextDomain + ApiConstants.bangumiTrends,
        queryParameters: {'type': 2, 'limit': fetchLimit, 'offset': 0},
      );

      final List<dynamic> data = response.data['data'] ?? [];
      final items = data.map((item) => HomeAnimeModel.fromJson(item)).toList();

      return DisplayService.buildRecommendPage(
        source: items,
        limit: limit,
        offset: offset,
      );
    } catch (_) {
      return [];
    }
  }

  Future<List<HomeAnimeModel>> getBannerList({int count = 5}) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.bangumiApiNextDomain + ApiConstants.bangumiTrends,
        queryParameters: {'type': 2, 'limit': 60, 'offset': 0},
      );

      final List<dynamic> data = response.data['data'] ?? [];
      final items = data.map((item) => HomeAnimeModel.fromJson(item)).toList();

      return SliderImageService.selectTopBanners(items, count: count);
    } catch (_) {
      return [];
    }
  }

  Future<List<List<HomeAnimeModel>>> getCalendar() async {
    try {
      final response = await _dioClient.get(
        ApiConstants.bangumiApiNextDomain + ApiConstants.bangumiCalendar,
      );

      final calendar = <List<HomeAnimeModel>>[];
      final jsonData = response.data;

      for (var i = 1; i <= 7; i++) {
        final dayList = <HomeAnimeModel>[];
        final jsonList = jsonData['$i'] ?? [];
        for (final jsonItem in jsonList) {
          try {
            final subjectData = jsonItem['subject'] ?? jsonItem;
            dayList.add(HomeAnimeModel.fromJson(subjectData));
          } catch (_) {}
        }
        calendar.add(dayList);
      }

      return calendar;
    } catch (_) {
      return List.generate(7, (_) => <HomeAnimeModel>[]);
    }
  }
}
