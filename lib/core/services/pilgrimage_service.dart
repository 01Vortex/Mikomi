import 'package:mikomi/core/network/dio_client.dart';
import 'package:mikomi/core/models/pilgrimage_item.dart';

class PilgrimageService {
  final DioClient _dioClient = DioClient();
  static const String _baseUrl = 'https://api.anitabi.cn';

  /// 根据Bangumi作品ID获取巡礼信息
  Future<PilgrimageItem?> getPilgrimageByBangumiId(int bangumiId) async {
    try {
      final response = await _dioClient.get(
        '$_baseUrl/bangumi/$bangumiId/lite',
      );

      return PilgrimageItem.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  /// 根据Bangumi作品ID获取详细地标信息
  Future<List<LitePoint>> getDetailPoints(
    int bangumiId, {
    bool haveImage = true,
  }) async {
    try {
      final response = await _dioClient.get(
        '$_baseUrl/bangumi/$bangumiId/points/detail',
        queryParameters: haveImage ? {'haveImage': 'true'} : null,
      );

      final List<dynamic> data = response.data ?? [];
      return data.map((e) => LitePoint.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }
}
