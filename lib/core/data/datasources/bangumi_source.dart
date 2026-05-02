import 'package:mikomi/core/network/app_api.dart';
import 'package:mikomi/core/network/dio_client.dart';

class BangumiSource {
  final DioClient _dioClient = DioClient();

  Future<List<dynamic>> fetchTrends({
    required int limit,
    required int offset,
  }) async {
    final response = await _dioClient.get(
      ApiConstants.bangumiApiNextDomain + ApiConstants.bangumiTrends,
      queryParameters: {'type': 2, 'limit': limit, 'offset': offset},
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return (data['data'] as List?)?.cast<dynamic>() ?? [];
    }
    return [];
  }

  Future<List<dynamic>> searchSubjects({
    required String keyword,
    int limit = 48,
    int offset = 0,
    String sort = 'rank',
  }) async {
    final response = await _dioClient.post(
      ApiConstants.bangumiApiDomain + ApiConstants.bangumiSearch,
      data: {
        'keyword': keyword,
        'sort': sort,
        'filter': {'type': [2]},
      },
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return (data['data'] as List?)?.cast<dynamic>() ?? [];
    }
    return [];
  }

  Future<Map<String, dynamic>> fetchCalendar() async {
    final response = await _dioClient.get(
      ApiConstants.bangumiApiNextDomain + ApiConstants.bangumiCalendar,
    );
    final data = response.data;
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<List<dynamic>> fetchSubjectCharacters(int subjectId) async {
    final url = ApiConstants.formatUrl(
      '${ApiConstants.bangumiApiDomain}/v0/subjects/{0}/characters',
      [subjectId],
    );

    final response = await _dioClient.get(url);
    return (response.data as List?)?.cast<dynamic>() ?? [];
  }

  Future<List<dynamic>> fetchSubjectStaff(int subjectId) async {
    final url = ApiConstants.formatUrl(
      '${ApiConstants.bangumiApiNextDomain}/p1/subjects/{0}/staffs/persons',
      [subjectId],
    );

    final response = await _dioClient.get(url);
    final data = response.data as Map<String, dynamic>?;
    return (data?['data'] as List?)?.cast<dynamic>() ?? [];
  }

  Future<Map<String, dynamic>?> fetchCharacterInfo(int characterId) async {
    final url = ApiConstants.formatUrl(
      '${ApiConstants.bangumiApiNextDomain}/p1/characters/{0}',
      [characterId],
    );

    final response = await _dioClient.get(url);
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : null;
  }

  Future<List<dynamic>> fetchCharacterComments(int characterId) async {
    final url = ApiConstants.formatUrl(
      '${ApiConstants.bangumiApiNextDomain}/p1/characters/{0}/comments',
      [characterId],
    );

    final response = await _dioClient.get(url);
    return (response.data as List?)?.cast<dynamic>() ?? [];
  }

  Future<Map<String, dynamic>?> fetchPersonInfo(int personId) async {
    final url = ApiConstants.formatUrl(
      '${ApiConstants.bangumiApiNextDomain}/p1/persons/{0}',
      [personId],
    );

    final response = await _dioClient.get(url);
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : null;
  }

  Future<List<dynamic>> fetchPersonComments(int personId) async {
    final url = ApiConstants.formatUrl(
      '${ApiConstants.bangumiApiNextDomain}/p1/persons/{0}/comments',
      [personId],
    );

    final response = await _dioClient.get(url);
    return (response.data as List?)?.cast<dynamic>() ?? [];
  }

  Future<List<dynamic>> fetchSubjectComments(
    int subjectId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final url = ApiConstants.formatUrl(
      '${ApiConstants.bangumiApiNextDomain}/p1/subjects/{0}/comments',
      [subjectId],
    );

    final response = await _dioClient.get(
      url,
      queryParameters: {'limit': limit, 'offset': offset},
    );

    final data = response.data as Map<String, dynamic>?;
    return (data?['data'] as List?)?.cast<dynamic>() ?? [];
  }
}
