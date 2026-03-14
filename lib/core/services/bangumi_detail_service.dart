import 'package:mikomi/core/network/dio_client.dart';
import 'package:mikomi/core/network/api_constants.dart';
import 'package:mikomi/core/models/bangumi_item.dart';

class BangumiDetailService {
  final DioClient _dioClient = DioClient();

  /// 根据ID获取番剧详细信息
  Future<BangumiItem?> getBangumiDetailById(int id) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.bangumiApiDomain}/v0/subjects/$id',
      );

      if (response.data != null) {
        return BangumiItem.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
