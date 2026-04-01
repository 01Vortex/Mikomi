class HomeAnimeTag {
  final String name;
  final int count;

  const HomeAnimeTag({required this.name, required this.count});

  factory HomeAnimeTag.fromJson(Map<String, dynamic> json) {
    return HomeAnimeTag(name: json['name'] ?? '', count: json['count'] ?? 0);
  }
}

class HomeAnimeModel {
  final int id;
  final String name;
  final String nameCn;
  final String summary;
  final String airDate;
  final Map<String, String> images;
  final double ratingScore;
  final int ratingCount;
  final int rank;
  final List<HomeAnimeTag> tags;
  final String info;

  const HomeAnimeModel({
    required this.id,
    required this.name,
    required this.nameCn,
    required this.summary,
    required this.airDate,
    required this.images,
    required this.ratingScore,
    required this.ratingCount,
    required this.rank,
    this.tags = const [],
    this.info = '',
  });

  factory HomeAnimeModel.fromJson(Map<String, dynamic> json) {
    final rating = json['rating'] ?? {};
    final subject = json['subject'] ?? json;

    final tagsList = <HomeAnimeTag>[];
    if (subject['tags'] != null) {
      final tags = subject['tags'];
      if (tags is List) {
        for (final tag in tags) {
          try {
            if (tag is Map) {
              tagsList.add(HomeAnimeTag.fromJson(Map<String, dynamic>.from(tag)));
            }
          } catch (_) {}
        }
      }
    }

    return HomeAnimeModel(
      id: subject['id'] ?? 0,
      name: subject['name'] ?? '',
      nameCn: subject['name_cn'] ?? subject['name'] ?? '',
      summary: subject['summary'] ?? '',
      airDate: subject['date'] ?? '',
      images: Map<String, String>.from(
        subject['images'] ??
            {
              'large': '',
              'common': '',
              'medium': '',
              'small': '',
              'grid': '',
            },
      ),
      ratingScore: (rating['score'] ?? 0.0).toDouble(),
      ratingCount: rating['total'] ?? 0,
      rank: rating['rank'] ?? 0,
      tags: tagsList,
      info: subject['info'] ?? '',
    );
  }

  String get displayName => nameCn.isNotEmpty ? nameCn : name;

  String get coverUrl =>
      images['large'] ??
      images['common'] ??
      images['medium'] ??
      images['small'] ??
      images['grid'] ??
      '';
}
