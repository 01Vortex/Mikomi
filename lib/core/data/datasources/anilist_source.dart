import 'package:mikomi/core/network/dio_client.dart';
import 'package:mikomi/core/data/graphql/anilist_queries.dart';

class AniListSource {
  final DioClient _dioClient = DioClient();

  Future<List<dynamic>> fetchMedia({
    required int page,
    required int perPage,
    required String sort,
    String? country,
    String? genre,
    int? seasonYear,
    String? status,
  }) async {
    final variables = <String, dynamic>{
      'page': page,
      'perPage': perPage,
      'sort': [sort],
    };

    if (country != null && country.isNotEmpty) {
      variables['country'] = country;
    }
    if (genre != null && genre.isNotEmpty) {
      variables['genre'] = genre;
    }
    if (seasonYear != null) {
      variables['seasonYear'] = seasonYear;
    }
    if (status != null && status.isNotEmpty) {
      variables['status'] = status;
    }

    final response = await _dioClient.post(
      'https://graphql.anilist.co',
      data: {'query': AniListQueries.base, 'variables': variables},
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return (data['data']?['Page']?['media'] as List?)?.cast<dynamic>() ?? [];
    }
    return [];
  }

  Future<List<dynamic>> fetchAiringSchedule({
    required int page,
    int perPage = 50,
  }) async {
    final response = await _dioClient.post(
      'https://graphql.anilist.co',
      data: {
        'query': AniListQueries.airingSchedule,
        'variables': {'page': page, 'perPage': perPage},
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return (data['data']?['Page']?['media'] as List?)?.cast<dynamic>() ?? [];
    }
    return [];
  }
}
