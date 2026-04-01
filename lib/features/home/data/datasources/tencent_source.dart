import 'package:mikomi/core/network/dio_client.dart';

class TencentSource {
  final DioClient _dioClient = DioClient();

  Future<String> fetchChineseRankHtml({required int limit}) async {
    final response = await _dioClient.get(
      'https://v.qq.com/x/bu/pagesheet/list',
      queryParameters: {
        'append': 1,
        'channel': 'cartoon',
        'iarea': 1,
        'listpage': 2,
        'offset': 0,
        'pagesize': limit,
      },
    );

    return response.data.toString();
  }
}
