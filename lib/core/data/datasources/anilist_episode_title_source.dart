import 'package:mikomi/core/network/dio_client.dart';

class AniListEpisodeTitleSource {
  final DioClient _dioClient = DioClient();

  Future<List<Map<String, dynamic>>> fetchEpisodeTitlesBySearch(String keyword) async {
    if (keyword.trim().isEmpty) return [];

    final response = await _dioClient.post(
      'https://graphql.anilist.co',
      data: {
        'query': '''
query (
  \$search: String
) {
  Media(search: \$search, type: ANIME) {
    episodes
    title {
      native
      romaji
      english
    }
  }
}
''',
        'variables': {'search': keyword},
      },
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) return [];

    final media = data['data']?['Media'] as Map<String, dynamic>?;
    if (media == null) return [];

    final episodes = media['episodes'] as int? ?? 0;
    if (episodes <= 0) return [];

    final titleMap = media['title'] as Map<String, dynamic>?;
    final baseTitle =
        (titleMap?['native']?.toString().trim().isNotEmpty == true)
            ? titleMap!['native'].toString().trim()
            : (titleMap?['romaji']?.toString().trim().isNotEmpty == true)
                ? titleMap!['romaji'].toString().trim()
                : (titleMap?['english']?.toString().trim() ?? keyword.trim());

    return List.generate(episodes, (index) {
      final number = index + 1;
      return {
        'number': number,
        'title': '$baseTitle EP$number',
      };
    });
  }
}
