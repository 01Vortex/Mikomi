import 'package:mikomi/core/network/dio_client.dart';
import 'package:mikomi/core/data/graphql/anilist_queries.dart';

class AniListSource {
  final DioClient _dioClient = DioClient();

  Future<List<dynamic>> fetchMedia({
    required int page,
    required int perPage,
    required String sort,
    String? country,
  }) async {
    final variables = {
      'page': page,
      'perPage': perPage,
      'sort': [sort],
    };

    if (country != null && country.isNotEmpty) {
      variables['country'] = country;
    }

    final query = country == null ? AniListQueries.base : AniListQueries.japanese;

    final response = await _dioClient.post(
      'https://graphql.anilist.co',
      data: {'query': query, 'variables': variables},
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return (data['data']?['Page']?['media'] as List?)?.cast<dynamic>() ?? [];
    }
    return [];
  }
}
