class BangumiItem {
  final int id;
  final String name;
  final String nameCn;
  final String summary;
  final String airDate;
  final Map<String, String> images;
  final double ratingScore;
  final int ratingCount;
  final int rank;
  final List<BangumiTag> tags;
  final String info;

  BangumiItem({
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

  factory BangumiItem.fromJson(Map<String, dynamic> json) {
    final rating = json['rating'] ?? {};
    final subject = json['subject'] ?? json;

    // 解析标签
    final List<BangumiTag> tagsList = [];
    if (subject['tags'] != null) {
      final tags = subject['tags'];
      if (tags is List) {
        for (var tag in tags) {
          try {
            if (tag is Map) {
              tagsList.add(BangumiTag.fromJson(Map<String, dynamic>.from(tag)));
            }
          } catch (e) {
            // 忽略解析失败的标签
          }
        }
      }
    }

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
      ratingCount: rating['total'] ?? 0,
      rank: rating['rank'] ?? 0,
      tags: tagsList,
      info: subject['info'] ?? '',
    );
  }

  String get displayName => nameCn.isNotEmpty ? nameCn : name;

  String get coverUrl => images['large'] ?? images['common'] ?? '';

  // 添加copyWith方法用于数据迁移
  BangumiItem copyWith({
    int? id,
    String? name,
    String? nameCn,
    String? summary,
    String? airDate,
    Map<String, String>? images,
    double? ratingScore,
    int? ratingCount,
    int? rank,
    List<BangumiTag>? tags,
    String? info,
  }) {
    return BangumiItem(
      id: id ?? this.id,
      name: name ?? this.name,
      nameCn: nameCn ?? this.nameCn,
      summary: summary ?? this.summary,
      airDate: airDate ?? this.airDate,
      images: images ?? this.images,
      ratingScore: ratingScore ?? this.ratingScore,
      ratingCount: ratingCount ?? this.ratingCount,
      rank: rank ?? this.rank,
      tags: tags ?? this.tags,
      info: info ?? this.info,
    );
  }
}

class BangumiTag {
  final String name;
  final int count;

  BangumiTag({required this.name, required this.count});

  factory BangumiTag.fromJson(Map<String, dynamic> json) {
    return BangumiTag(name: json['name'] ?? '', count: json['count'] ?? 0);
  }
}
