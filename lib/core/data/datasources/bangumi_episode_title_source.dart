import 'package:dio/dio.dart';

class BangumiEpisodeTitleSource {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.bgm.tv',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Future<List<Map<String, dynamic>>> fetchEpisodeTitles(int subjectId) async {
    final response = await _dio.get(
      '/v0/episodes',
      queryParameters: {
        'subject_id': subjectId,
        'type': 0,
        'limit': 200,
        'offset': 0,
      },
    );

    if (response.statusCode != 200) return [];

    final data = response.data;
    if (data is! Map<String, dynamic>) return [];

    final list = (data['data'] as List?)?.cast<dynamic>() ?? [];
    return list.whereType<Map>().map((item) {
      final map = Map<String, dynamic>.from(item);
      return {
        'number': map['ep'] ?? 0,
        'title': (map['name_cn']?.toString().trim().isNotEmpty == true)
            ? map['name_cn'].toString().trim()
            : (map['name']?.toString().trim() ?? ''),
      };
    }).toList();
  }
}
