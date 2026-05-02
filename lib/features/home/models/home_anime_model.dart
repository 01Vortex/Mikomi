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

    final originalName = _stringValue(subject, const ['name']);
    final chineseName = _extractChineseName(subject, fallbackOriginal: originalName);

    return HomeAnimeModel(
      id: subject['id'] ?? 0,
      name: originalName,
      nameCn: chineseName,
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

  String get displayName => _isChineseText(nameCn) ? nameCn : name;

  String get coverUrl =>
      images['large'] ??
      images['common'] ??
      images['medium'] ??
      images['small'] ??
      images['grid'] ??
      '';
}

bool _isChineseText(String text) {
  return RegExp(r'[\u4e00-\u9fff]').hasMatch(text);
}

String _stringValue(Map<dynamic, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return '';
}

String _extractChineseName(
  Map<dynamic, dynamic> subject, {
  required String fallbackOriginal,
}) {
  final direct = _stringValue(subject, const [
    'name_cn',
    'nameCn',
    'nameCN',
    'chineseName',
    'titleCn',
    'title_cn',
  ]);
  if (_isChineseText(direct)) return direct;

  final nameCnObject = subject['name_cn'];
  if (nameCnObject is Map) {
    final value = _stringValue(nameCnObject, const [
      'cn',
      'zh',
      'zh_cn',
      'zh-Hans',
      'zh_hans',
      'value',
    ]);
    if (_isChineseText(value)) return value;
  }

  final infoboxValue = _extractChineseNameFromInfobox(subject['infobox']);
  if (_isChineseText(infoboxValue)) return infoboxValue;

  final aliases = subject['aliases'] ?? subject['alias'];
  if (aliases is List) {
    for (final alias in aliases) {
      final value = alias?.toString().trim() ?? '';
      if (_isChineseText(value)) return value;
    }
  }

  return _isChineseText(fallbackOriginal) ? fallbackOriginal : '';
}

String _extractChineseNameFromInfobox(dynamic infobox) {
  if (infobox is! List) return '';

  for (final item in infobox) {
    if (item is! Map) continue;
    final key = (item['key'] ?? item['name'] ?? '').toString();
    if (!key.contains('中文') && !key.contains('简体')) continue;

    final value = item['value'];
    if (value is String && _isChineseText(value)) return value.trim();
    if (value is List) {
      for (final entry in value) {
        final text = entry?.toString().trim() ?? '';
        if (_isChineseText(text)) return text;
      }
    }
  }

  return '';
}
