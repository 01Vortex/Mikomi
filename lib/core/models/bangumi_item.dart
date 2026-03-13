class BangumiItem {
  final int id;
  final String name;
  final String nameCn;
  final String summary;
  final String airDate;
  final Map<String, String> images;
  final double ratingScore;
  final int rank;

  BangumiItem({
    required this.id,
    required this.name,
    required this.nameCn,
    required this.summary,
    required this.airDate,
    required this.images,
    required this.ratingScore,
    required this.rank,
  });

  factory BangumiItem.fromJson(Map<String, dynamic> json) {
    final rating = json['rating'] ?? {};
    final subject = json['subject'] ?? json;

    return BangumiItem(
      id: subject['id'] ?? 0,
      name: subject['name'] ?? '',
      nameCn: subject['name_cn'] ?? subject['name'] ?? '',
      summary: subject['summary'] ?? '',
      airDate: subject['date'] ?? '',
      images: Map<String, String>.from(
        subject['images'] ??
            {'large': '', 'common': '', 'medium': '', 'small': '', 'grid': ''},
      ),
      ratingScore: (rating['score'] ?? 0.0).toDouble(),
      rank: rating['rank'] ?? 0,
    );
  }

  String get displayName => nameCn.isNotEmpty ? nameCn : name;

  String get coverUrl => images['large'] ?? images['common'] ?? '';
}
